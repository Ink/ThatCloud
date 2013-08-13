// FPAFURLConnectionOperation.m
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

#import "FPAFURLConnectionOperation.h"

typedef enum {
    FPAFHTTPOperationReadyState       = 1,
    FPAFHTTPOperationExecutingState   = 2,
    FPAFHTTPOperationFinishedState    = 3,
} _FPAFOperationState;

typedef unsigned short FPAFOperationState;

static NSUInteger const kFPAFHTTPMinimumInitialDataCapacity = 1024;
static NSUInteger const kFPAFHTTPMaximumInitialDataCapacity = 1024 * 1024 * 8;

static NSString * const kFPAFNetworkingLockName = @"com.alamofire.networking.operation.lock";

NSString * const FPAFNetworkingErrorDomain = @"com.alamofire.networking.error";

NSString * const FPAFNetworkingOperationDidStartNotification = @"com.alamofire.networking.operation.start";
NSString * const FPAFNetworkingOperationDidFinishNotification = @"com.alamofire.networking.operation.finish";

typedef void (^FPAFURLConnectionOperationProgressBlock)(NSInteger bytes, NSInteger totalBytes, NSInteger totalBytesExpected);
typedef void (^FPAFURLConnectionOperationAuthenticationChallengeBlock)(NSURLConnection *connection, NSURLAuthenticationChallenge *challenge);

static inline NSString * FPAFKeyPathFromOperationState(FPAFOperationState state) {
    switch (state) {
        case FPAFHTTPOperationReadyState:
            return @"isReady";
        case FPAFHTTPOperationExecutingState:
            return @"isExecuting";
        case FPAFHTTPOperationFinishedState:
            return @"isFinished";
        default:
            return @"state";
    }
}

static inline BOOL FPAFStateTransitionIsValid(FPAFOperationState fromState, FPAFOperationState toState, BOOL isCancelled) {
    switch (fromState) {
        case FPAFHTTPOperationReadyState:
            switch (toState) {
                case FPAFHTTPOperationExecutingState:
                    return YES;
                case FPAFHTTPOperationFinishedState:
                    return isCancelled;
                default:
                    return NO;
            }
        case FPAFHTTPOperationExecutingState:
            switch (toState) {
                case FPAFHTTPOperationFinishedState:
                    return YES;
                default:
                    return NO;
            }
        case FPAFHTTPOperationFinishedState:
            return NO;
        default:
            return YES;
    }
}

@interface FPAFURLConnectionOperation ()
@property (readwrite, nonatomic, assign) FPAFOperationState state;
@property (readwrite, nonatomic, retain) NSRecursiveLock *lock;
@property (readwrite, nonatomic, assign) NSURLConnection *connection;
@property (readwrite, nonatomic, retain) NSURLRequest *request;
@property (readwrite, nonatomic, retain) NSURLResponse *response;
@property (readwrite, nonatomic, retain) NSError *error;
@property (readwrite, nonatomic, retain) NSData *responseData;
@property (readwrite, nonatomic, copy) NSString *responseString;
@property (readwrite, nonatomic, assign) NSInteger totalBytesRead;
@property (readwrite, nonatomic, retain) NSMutableData *dataAccumulator;
@property (readwrite, nonatomic, copy) FPAFURLConnectionOperationProgressBlock uploadProgress;
@property (readwrite, nonatomic, copy) FPAFURLConnectionOperationProgressBlock downloadProgress;
@property (readwrite, nonatomic, copy) FPAFURLConnectionOperationAuthenticationChallengeBlock authenticationBlock;

- (void)operationDidStart;
- (void)finish;
@end

@implementation FPAFURLConnectionOperation
@synthesize state = _state;
@synthesize connection = _connection;
@synthesize runLoopModes = _runLoopModes;
@synthesize request = _request;
@synthesize response = _response;
@synthesize error = _error;
@synthesize responseData = _responseData;
@synthesize responseString = _responseString;
@synthesize totalBytesRead = _totalBytesRead;
@synthesize dataAccumulator = _dataAccumulator;
@dynamic inputStream;
@synthesize outputStream = _outputStream;
@synthesize uploadProgress = _uploadProgress;
@synthesize downloadProgress = _downloadProgress;
@synthesize authenticationBlock = _authenticationBlock;
@synthesize lock = _lock;

+ (void)networkRequestThreadEntryPoint:(id)__unused object {
    do {
        NSAutoreleasePool *exceptionPool = [[NSAutoreleasePool alloc] init];
        NSException *caughtException = nil;
        @try {
            NSAutoreleasePool *runLoopPool = [[NSAutoreleasePool alloc] init];
            [[NSRunLoop currentRunLoop] run];
            [runLoopPool drain];
        }
        @catch(NSException *e) { caughtException = e; }
        if(caughtException) { 
            NSLog(NSLocalizedString(@"Unhandled exception on %@ networking thread: %@, userInfo: %@", nil), NSStringFromClass([self class]), caughtException, [caughtException userInfo]); 
        }
        [exceptionPool drain];
    } while (YES);
}

+ (NSThread *)networkRequestThread {
    static NSThread *_networkRequestThread = nil;
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate, ^{
        _networkRequestThread = [[NSThread alloc] initWithTarget:self selector:@selector(networkRequestThreadEntryPoint:) object:nil];
        [_networkRequestThread start];
    });
    
    return _networkRequestThread;
}

- (id)initWithRequest:(NSURLRequest *)urlRequest {
    self = [super init];
    if (!self) {
		return nil;
    }
    
    self.lock = [[[NSRecursiveLock alloc] init] autorelease];
    self.lock.name = kFPAFNetworkingLockName;
    
    self.runLoopModes = [NSSet setWithObject:NSRunLoopCommonModes];
    
    self.request = urlRequest;
     
    self.state = FPAFHTTPOperationReadyState;
	
    return self;
}

- (void)dealloc {
    [_lock release];
        
    [_runLoopModes release];
    
    [_request release];
    [_response release];
    [_error release];
    
    [_responseData release];
    [_responseString release];
    [_dataAccumulator release];
    
    if (_outputStream) {
        [_outputStream close];
        [_outputStream release];
        _outputStream = nil;
    }
    	
    [_uploadProgress release];
    [_downloadProgress release];
    [_authenticationBlock release];

    [super dealloc];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, state: %@, cancelled: %@ request: %@, response: %@>", NSStringFromClass([self class]), self, FPAFKeyPathFromOperationState(self.state), ([self isCancelled] ? @"YES" : @"NO"), self.request, self.response];
}

- (void)setCompletionBlock:(void (^)(void))block {
    [self.lock lock];
    if (!block) {
        [super setCompletionBlock:nil];
    } else {
        __block id _blockSelf = self;
        [super setCompletionBlock:^ {
            block();
            [_blockSelf setCompletionBlock:nil];
        }];
    }
    [self.lock unlock];
}

- (NSInputStream *)inputStream {
    return self.request.HTTPBodyStream;
}

- (void)setInputStream:(NSInputStream *)inputStream {
    NSMutableURLRequest *mutableRequest = [[self.request mutableCopy] autorelease];
    mutableRequest.HTTPBodyStream = inputStream;
    self.request = mutableRequest;
}

- (void)setUploadProgressBlock:(void (^)(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite))block {
    self.uploadProgress = block;
}

- (void)setDownloadProgressBlock:(void (^)(NSInteger bytesRead, NSInteger totalBytesRead, NSInteger totalBytesExpectedToRead))block {
    self.downloadProgress = block;
}

- (void)setAuthenticationChallengeBlock:(void (^)(NSURLConnection *connection, NSURLAuthenticationChallenge *challenge))block {
    self.authenticationBlock = block;
}

- (void)setState:(FPAFOperationState)state {
    [self.lock lock];
    if (FPAFStateTransitionIsValid(self.state, state, [self isCancelled])) {
        NSString *oldStateKey = FPAFKeyPathFromOperationState(self.state);
        NSString *newStateKey = FPAFKeyPathFromOperationState(state);
        
        [self willChangeValueForKey:newStateKey];
        [self willChangeValueForKey:oldStateKey];
        _state = state;
        [self didChangeValueForKey:oldStateKey];
        [self didChangeValueForKey:newStateKey];
        
        switch (state) {
            case FPAFHTTPOperationExecutingState:
                [[NSNotificationCenter defaultCenter] postNotificationName:FPAFNetworkingOperationDidStartNotification object:self];
                break;
            case FPAFHTTPOperationFinishedState:
                [[NSNotificationCenter defaultCenter] postNotificationName:FPAFNetworkingOperationDidFinishNotification object:self];
                break;
            default:
                break;
        }
    }
    [self.lock unlock];
}

- (NSString *)responseString {
    [self.lock lock];
    if (!_responseString && self.response && self.responseData) {
        NSStringEncoding textEncoding = NSUTF8StringEncoding;
        if (self.response.textEncodingName) {
            textEncoding = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((CFStringRef)self.response.textEncodingName));
        }
        
        self.responseString = [[[NSString alloc] initWithData:self.responseData encoding:textEncoding] autorelease];
    }
    [self.lock unlock];
    
    return _responseString;
}

#pragma mark - NSOperation

- (BOOL)isReady {
    return self.state == FPAFHTTPOperationReadyState && [super isReady];
}

- (BOOL)isExecuting {
    return self.state == FPAFHTTPOperationExecutingState;
}

- (BOOL)isFinished {
    return self.state == FPAFHTTPOperationFinishedState;
}

- (BOOL)isCancelled {
    return _cancelled;
}

- (BOOL)isConcurrent {
    return YES;
}

- (void)start {
    [self.lock lock];
    if ([self isReady]) {
        self.state = FPAFHTTPOperationExecutingState;
        
        [self performSelector:@selector(operationDidStart) onThread:[[self class] networkRequestThread] withObject:nil waitUntilDone:NO modes:[self.runLoopModes allObjects]];
    }
    [self.lock unlock];
}

- (void)operationDidStart {
    [self.lock lock];
    if ([self isCancelled]) {
        [self finish];
    } else {
        self.connection = [[[NSURLConnection alloc] initWithRequest:self.request delegate:self startImmediately:NO] autorelease];
        
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        for (NSString *runLoopMode in self.runLoopModes) {
            [self.connection scheduleInRunLoop:runLoop forMode:runLoopMode];
            [self.outputStream scheduleInRunLoop:runLoop forMode:runLoopMode];
        }
        
        [self.connection start];  
    }
    [self.lock unlock];
}

- (void)finish {
    self.state = FPAFHTTPOperationFinishedState;
}

- (void)cancel {
    [self.lock lock];
    if (![self isFinished] && ![self isCancelled]) {
        [super cancel];
        
        [self willChangeValueForKey:@"isCancelled"];
        _cancelled = YES;
        if (self.connection) {
            [self.connection cancel];
            
            // We must send this delegate protcol message ourselves since the above [self.connection cancel] causes the connection to never send another message to its delegate.
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[self.request URL] forKey:NSURLErrorFailingURLErrorKey];
            [self performSelector:@selector(connection:didFailWithError:) withObject:self.connection withObject:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:userInfo]];
        }
        [self didChangeValueForKey:@"isCancelled"];
    }
    [self.lock unlock];
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection 
didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge 
{
    if (self.authenticationBlock) {
        self.authenticationBlock(connection, challenge);
    } else {
        if ([challenge previousFailureCount] == 0) {
            NSURLCredential *credential = nil;
            
            NSString *username = [(NSString *)CFURLCopyUserName((CFURLRef)[self.request URL]) autorelease];
            NSString *password = [(NSString *)CFURLCopyPassword((CFURLRef)[self.request URL]) autorelease];
            
            if (username && password) {
                credential = [NSURLCredential credentialWithUser:username password:password persistence:NSURLCredentialPersistenceNone];
            } else if (username) {
                credential = [[[NSURLCredentialStorage sharedCredentialStorage] credentialsForProtectionSpace:[challenge protectionSpace]] objectForKey:username];
            } else {
                credential = [[NSURLCredentialStorage sharedCredentialStorage] defaultCredentialForProtectionSpace:[challenge protectionSpace]];
            }
            
            if (credential) {
                [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
            } else {
                [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
            }
        } else {
            [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
        }
    }
}

- (void)connection:(NSURLConnection *)__unused connection 
   didSendBodyData:(NSInteger)bytesWritten 
 totalBytesWritten:(NSInteger)totalBytesWritten 
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    if (self.uploadProgress) {
        self.uploadProgress(bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
    }
}

- (void)connection:(NSURLConnection *)__unused connection 
didReceiveResponse:(NSURLResponse *)response 
{
    self.response = (NSHTTPURLResponse *)response;
    
    if (self.outputStream) {
        [self.outputStream open];
    } else {
        NSUInteger maxCapacity = MAX((NSUInteger)llabs(response.expectedContentLength), kFPAFHTTPMinimumInitialDataCapacity);
        NSUInteger capacity = MIN(maxCapacity, kFPAFHTTPMaximumInitialDataCapacity);
        self.dataAccumulator = [NSMutableData dataWithCapacity:capacity];
    }
}

- (void)connection:(NSURLConnection *)__unused connection 
    didReceiveData:(NSData *)data 
{
    self.totalBytesRead += [data length];
    
    if (self.outputStream) {
        if ([self.outputStream hasSpaceAvailable]) {
            const uint8_t *dataBuffer = (uint8_t *) [data bytes];
            [self.outputStream write:&dataBuffer[0] maxLength:[data length]];
        }
    } else {
        [self.dataAccumulator appendData:data];
    }
    
    if (self.downloadProgress) {
        self.downloadProgress([data length], self.totalBytesRead, (NSInteger)self.response.expectedContentLength);
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)__unused connection {        
    if (self.outputStream) {
        [self.outputStream close];
    } else {
        self.responseData = [NSData dataWithData:self.dataAccumulator];
        [_dataAccumulator release]; _dataAccumulator = nil;
    }
    
    [self finish];
}

- (void)connection:(NSURLConnection *)__unused connection 
  didFailWithError:(NSError *)error 
{    
    self.error = error;
    
    if (self.outputStream) {
        [self.outputStream close];
    } else {
        [_dataAccumulator release]; _dataAccumulator = nil;
    }
    
    [self finish];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)__unused connection 
                  willCacheResponse:(NSCachedURLResponse *)cachedResponse 
{
    if ([self isCancelled]) {
        return nil;
    }
    
    return cachedResponse;
}

@end
