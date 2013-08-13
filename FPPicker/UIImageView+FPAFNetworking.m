// UIImageView+FPAFNetworking.m
//
// Copyright (c) 2011 Gowalla (http://gowalla.com/)
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import "UIImageView+FPAFNetworking.h"

@interface FPAFImageCache : NSCache
@property (nonatomic, assign) CGFloat imageScale;

- (UIImage *)cachedImageForURL:(NSURL *)url
                     cacheName:(NSString *)cacheName;

- (void)cacheImageData:(NSData *)imageData
                forURL:(NSURL *)url
             cacheName:(NSString *)cacheName;
@end

#pragma mark -

static char kFPAFImageRequestOperationObjectKey;

@interface UIImageView (_FPAFNetworking)
@property (readwrite, nonatomic, retain, setter = fpaf_setImageRequestOperation:) FPAFImageRequestOperation *fpaf_imageRequestOperation;
@end

@implementation UIImageView (_FPAFNetworking)
@dynamic fpaf_imageRequestOperation;
@end

#pragma mark -

@implementation UIImageView (FPAFNetworking)

- (FPAFHTTPRequestOperation *)fpaf_imageRequestOperation {
    return (FPAFHTTPRequestOperation *)objc_getAssociatedObject(self, &kFPAFImageRequestOperationObjectKey);
}

- (void)fpaf_setImageRequestOperation:(FPAFImageRequestOperation *)imageRequestOperation {
    objc_setAssociatedObject(self, &kFPAFImageRequestOperationObjectKey, imageRequestOperation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (NSOperationQueue *)fpaf_sharedImageRequestOperationQueue {
    static NSOperationQueue *_fpaf_imageRequestOperationQueue = nil;
    
    if (!_fpaf_imageRequestOperationQueue) {
        _fpaf_imageRequestOperationQueue = [[NSOperationQueue alloc] init];
        [_fpaf_imageRequestOperationQueue setMaxConcurrentOperationCount:8];
    }
    
    return _fpaf_imageRequestOperationQueue;
}

+ (FPAFImageCache *)fpaf_sharedImageCache {
    static FPAFImageCache *_fpaf_imageCache = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _fpaf_imageCache = [[FPAFImageCache alloc] init];
    });
    
    return _fpaf_imageCache;
}

#pragma mark -

- (void)FPsetImageWithURL:(NSURL *)url {
    [self FPsetImageWithURL:url placeholderImage:nil];
}

- (void)FPsetImageWithURL:(NSURL *)url
       placeholderImage:(UIImage *)placeholderImage
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
    [request setHTTPShouldHandleCookies:NO];
    [request setHTTPShouldUsePipelining:YES];
    
    [self FPsetImageWithURLRequest:request placeholderImage:placeholderImage success:nil failure:nil];
}

- (void)FPsetImageWithURLRequest:(NSURLRequest *)urlRequest
              placeholderImage:(UIImage *)placeholderImage 
                       success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image))success
                       failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure
{
    if (![urlRequest URL] || (![self.fpaf_imageRequestOperation isCancelled] && [[urlRequest URL] isEqual:[[self.fpaf_imageRequestOperation request] URL]])) {
        return;
    } else {
        [self FPcancelImageRequestOperation];
    }
    
    UIImage *cachedImage = [[[self class] fpaf_sharedImageCache] cachedImageForURL:[urlRequest URL] cacheName:nil];
    if (cachedImage) {
        self.image = cachedImage;
        self.fpaf_imageRequestOperation = nil;
        
        if (success) {
            success(nil, nil, cachedImage);
        }
    } else {
        self.image = placeholderImage;
        
        FPAFImageRequestOperation *requestOperation = [[[FPAFImageRequestOperation alloc] initWithRequest:urlRequest] autorelease];
        [requestOperation setCompletionBlockWithSuccess:^(FPAFHTTPRequestOperation *operation, id responseObject) {
            if ([[urlRequest URL] isEqual:[[self.fpaf_imageRequestOperation request] URL]]) {
                self.image = responseObject;
            }

            if (success) {
                success(operation.request, operation.response, responseObject);
            }

            [[[self class] fpaf_sharedImageCache] cacheImageData:operation.responseData forURL:[urlRequest URL] cacheName:nil];
        } failure:^(FPAFHTTPRequestOperation *operation, NSError *error) {
            if (failure) {
                failure(operation.request, operation.response, error);
            }
        }];
        
        self.fpaf_imageRequestOperation = requestOperation;
        
        [[[self class] fpaf_sharedImageRequestOperationQueue] addOperation:self.fpaf_imageRequestOperation];
    }
}

- (void)FPcancelImageRequestOperation {
    [self.fpaf_imageRequestOperation cancel];
}

@end

#pragma mark -

static inline NSString * FPAFImageCacheKeyFromURLAndCacheName(NSURL *url, NSString *cacheName) {
    return [[url absoluteString] stringByAppendingFormat:@"#%@", cacheName];
}

@implementation FPAFImageCache
@synthesize imageScale = _imageScale;

- (id)init {
	self = [super init];
	if (!self) {
		return nil;
	}
    
    self.imageScale = [[UIScreen mainScreen] scale];
	
	return self;
}

- (UIImage *)cachedImageForURL:(NSURL *)url
                     cacheName:(NSString *)cacheName
{
	UIImage *image = [UIImage imageWithData:[self objectForKey:FPAFImageCacheKeyFromURLAndCacheName(url, cacheName)]];
	if (image) {
		return [UIImage imageWithCGImage:[image CGImage] scale:self.imageScale orientation:image.imageOrientation];
	}
    return image;
}

- (void)cacheImageData:(NSData *)imageData
                forURL:(NSURL *)url
             cacheName:(NSString *)cacheName
{
    [self setObject:[NSPurgeableData dataWithData:imageData] forKey:FPAFImageCacheKeyFromURLAndCacheName(url, cacheName)];
}

@end

#endif
