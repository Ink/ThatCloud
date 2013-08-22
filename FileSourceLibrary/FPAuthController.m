//
//  TestViewController.m
//  FPPicker
//
//  Created by Liyan David Chang on 6/20/12.
//  Copyright (c) 2013 Ink (Cloudtop Inc), All rights reserved.
//

#import "FPAuthController.h"
#import "FlatUIKit.h"

@interface FPAuthController ()

@end

@implementation FPAuthController

@synthesize webView = _webView;
@synthesize service, alreadyReload;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (void)backToSourceList {

    NSLog(@"Back to source list");
    //Animation may cause reload not work properly. Should be NO.
    [self dismissViewControllerAnimated:NO completion:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"authCancel" object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    //Override it with our specialty jump back to list.
    NSLog(@"Adding Back");
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(backToSourceList)];
    //Have to configure here otherwise the back button and title don't show up. Can't do it in source controller
    [self.navigationController.navigationBar configureFlatNavigationBarWithColor:[UIColor whiteColor]];


    self.webView = [[UIWebView alloc] init];
    
    [self.view addSubview:self.webView];
    self.webView.delegate = self;
    
    NSString *serviceID = [service lowercaseString];
    
    NSString *urlString = [NSString stringWithFormat:@"%@/api/client/%@/auth/open?m=*/*&key=%@&id=0&modal=false", fpBASE_URL, serviceID, fpAPIKEY];
    NSLog(@"url: %@", urlString);
    NSMutableURLRequest *requestObj = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    self.webView.scalesPageToFit = YES;
    [self.webView loadRequest:requestObj];
    
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation duration:(NSTimeInterval)duration {
    self.webView.frame = self.view.bounds;
}

- (void)viewWillAppear:(BOOL)animated {
    self.contentSizeForViewInPopover = fpWindowSize;   
    self.webView.frame = self.view.bounds;

    [super viewWillAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:NO];
    [self.webView stopLoading];
    self.webView.delegate = nil;
    self.webView = nil;
}

- (void)loadRequest:(NSURLRequest *)request
{
    if ([self.webView isLoading])
        [self.webView stopLoading];
    [self.webView loadRequest:request];
}

#pragma mark WebView Delegate Methods

- (BOOL)webView:(UIWebView *)localWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSLog(@"Loading Path: %@ (relpath: %@)", [[request URL] absoluteString], [[request URL] path] );
    [FPMBProgressHUD hideHUDForView:localWebView animated:YES]; 

    if ([[[request URL] path] isEqualToString:@"/dialog/open"]) {

        //NSLog(@"HIT");
        //NSLog(@"Coookies: %@", fpCOOKIES);

        [[NSNotificationCenter defaultCenter] postNotificationName:@"auth" object:nil];
        //[self.navigationController popViewControllerAnimated:NO];
        [self dismissViewControllerAnimated:YES completion:nil];
        
        return NO;
    }
    
    NSDictionary *FPSettings = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle]  pathForResource:@"FilepickerSettings" ofType:@"plist"]];

    NSLog([[FPSettings valueForKey:@"OnlyResolveAllowedLinks"]boolValue]? @"HIDE LINKS" : @"DONT HIDE");
    
    if ([[FPSettings valueForKey:@"OnlyResolveAllowedLinks"] boolValue]){
        
        NSArray *disallowedUrlPrefix = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"disallowedUrlPrefix" ofType:@"plist"]];
        
        NSArray *allowedUrlPrefix = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle]  pathForResource:@"allowedUrlPrefix" ofType:@"plist"]];
        
        NSEnumerator *e;
        id object;
        
        NSString *normalizedString = [request.URL.absoluteString stringByStandardizingPath];

        e = [disallowedUrlPrefix objectEnumerator];
        while (object = [e nextObject]) {
            if ([normalizedString hasPrefix:[object stringByStandardizingPath]]){
                return NO;
            }
        }
        
        e = [allowedUrlPrefix objectEnumerator];
        while (object = [e nextObject]) {
            if ([normalizedString hasPrefix:[object stringByStandardizingPath]]){
                [FPMBProgressHUD showHUDAddedTo:localWebView animated:YES];
                return YES;
            }
        }
        
        #ifdef DEBUG
        if ([request.URL.absoluteString hasPrefix:fpBASE_URL]){
            [FPMBProgressHUD showHUDAddedTo:localWebView animated:YES];
            return YES;
        }
        #endif

        NSForceLog(@"REJECTING URL FOR WEBVIEW: %@", request.URL.absoluteString);

        return NO;
    } else {
        return YES;
    }
}

- (void) webViewDidFinishLoad:(UIWebView *)webview
{
    [FPMBProgressHUD hideAllHUDsForView:webview animated:YES]; 
    
    int width = (int)CGRectApplyAffineTransform([self.view bounds], [self.view transform]).size.width;
    
    NSString* js = 
    [NSString stringWithFormat:
    @"var meta = document.createElement('meta'); " \
    "meta.setAttribute( 'name', 'viewport' ); " \
    "meta.setAttribute( 'content', 'width = %d, initial-scale = 1.0, user-scalable = yes' ); " \
    "document.getElementsByTagName('head')[0].appendChild(meta)", width
    ];
    [webview stringByEvaluatingJavaScriptFromString: js];

    NSDictionary *FPSettings = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FilepickerSettings" ofType:@"plist"]];

    NSLog(@"Dictionary %@", FPSettings);
    
    NSLog([[FPSettings valueForKey:@"HideAllLinks"]boolValue]? @"HIDE LINKS" : @"DONT HIDE");
    
    if ([[FPSettings valueForKey:@"HideAllLinks"] boolValue]){

        NSString *xui = @"(function(){function J(a,b,c){c=a.slice((c||b)+1||a.length);a.length=b<0?a.length+b:b;return a.push.apply(a,c)}function K(a){return a.replace(/\\-[a-z]/g,function(b){return b[1].toUpperCase()})}function E(a){return a.replace(/[A-Z]/g,function(b){return\"-\"+b.toLowerCase()})}function L(a){return a.firstChild===null?{UL:\"LI\",DL:\"DT\",TR:\"TD\"}[a.tagName]||a.tagName:a.firstChild.tagName}function M(a,b){if(typeof a==z)return N(a,L(b));else{b=n.createElement(\"div\");b.appendChild(a);return b}}function N(a){var b=n.createElement(\"div\");b.innerHTML=a;return b}function O(a){var b=/\\S/;a.each(function(c){for(var d=c.firstChild,f=-1,e;d;){e=d.nextSibling;if(d.nodeType==3&&!b.test(d.nodeValue))c.removeChild(d);else d.nodeIndex=++f;d=e}})}function v(a){if(a._xuiEventID)return a._xuiEventID;return a._xuiEventID=++v.id}function B(a,b){a=u[a]=u[a]||{};return a[b]=a[b]||[]}function P(a,b,c){var d=v(a);b=B(d,b);d=function(f){if(c.call(a,f)===false){f.preventDefault();f.stopPropagation()}};d.guid=c.guid=c.guid||++v.id;d.handler=c;b.push(d);return d}function C(a,b){return D(b).test(a.className)}function A(a){return(a||\"\").replace(Q,\"\")}var w,i,l=this,z=new String(\"string\"),n=l.document,R=/^#?([\\w-]+)$/,S=/^#/,T=/<([\\w:]+)/,s=function(a){return[].slice.call(a,0)};try{s(n.documentElement.childNodes)}catch(W){s=function(a){for(var b=[],c=0;a[c];c++)b.push(a[c]);return b}}l.x$=l.xui=i=function(a,b){return new i.fn.find(a,b)};if(![].forEach)Array.prototype.forEach=function(a,b){var c=this.length||0,d=0;if(typeof a==\"function\")for(;d<c;d++)a.call(b,this[d],d,this)};i.fn=i.prototype={extend:function(a){for(var b in a)i.fn[b]=a[b]},find:function(a,b){var c=[];if(a)if(b==w&&this.length)c=this.each(function(d){c=c.concat(s(i(a,d)))}).reduce(c);else{b=b||n;if(typeof a==z){if(R.test(a)&&b.getElementById&&b.getElementsByTagName){c=S.test(a)?[b.getElementById(a.substr(1))]:b.getElementsByTagName(a);if(c[0]==null)c=[]}else if(T.test(a)){b=n.createElement(\"i\");b.innerHTML=a;s(b.childNodes).forEach(function(d){c.push(d)})}else c=l.Sizzle!==w?Sizzle(a,b):b.querySelectorAll(a);c=s(c)}else if(a instanceof Array)c=a;else if(a.nodeName||a===l)c=[a];else if(a.toString()==\"[object NodeList]\"||a.toString()==\"[object HTMLCollection]\"||typeof a.length==\"number\")c=s(a)}else return this;return this.set(c)},set:function(a){var b=i();b.cache=s(this.length?this:[]);b.length=0;[].push.apply(b,a);return b},reduce:function(a,b){var c=[];a=a||s(this);a.forEach(function(d){c.indexOf(d,0,b)<0&&c.push(d)});return c},has:function(a){var b=i(a);return this.filter(function(){var c=this,d=null;b.each(function(f){d=d||f==c});return d})},filter:function(a){var b=[];return this.each(function(c,d){a.call(c,d)&&b.push(c)}).set(b)},not:function(a){var b=s(this),c=i(a);if(!c.length)return this;return this.filter(function(d){var f;c.each(function(e){return f=b[d]!=e});return f})},each:function(a){for(var b=0,c=this.length;b<c;++b)if(a.call(this[b],this[b],b,this)===false)break;return this}};i.fn.find.prototype=i.fn;i.extend=i.fn.extend;i.extend({html:function(a,b){O(this);if(arguments.length==0){var c=[];this.each(function(e){c.push(e.innerHTML)});return c}if(arguments.length==1&&arguments[0]!=\"remove\"){b=a;a=\"inner\"}if(a!=\"remove\"&&b&&b.each!==w){if(a==\"inner\"){var d=n.createElement(\"p\");b.each(function(e){d.appendChild(e)});this.each(function(e){e.innerHTML=d.innerHTML})}else{var f=this;b.each(function(e){f.html(a,e)})}return this}return this.each(function(e){var h,k=0;if(a==\"inner\")if(typeof b==z||typeof b==\"number\"){e.innerHTML=b;e=e.getElementsByTagName(\"SCRIPT\");for(h=e.length;k<h;k++)eval(e[k].text)}else{e.innerHTML=\"\";e.appendChild(b)}else if(a==\"remove\")e.parentNode.removeChild(e);else{k=M(b,[\"outer\",\"top\",\"bottom\"].indexOf(a)>-1?e:e.parentNode);h=k.childNodes;if(a==\"outer\")e.parentNode.replaceChild(k,e);else if(a==\"top\")e.insertBefore(k,e.firstChild);else if(a==\"bottom\")e.insertBefore(k,null);else if(a==\"before\")e.parentNode.insertBefore(k,e);else a==\"after\"&&e.parentNode.insertBefore(k,e.nextSibling);for(e=k.parentNode;h.length;)e.insertBefore(h[0],k);e.removeChild(k)}})},attr:function(a,b){if(arguments.length==2)return this.each(function(d){if(d.tagName&&d.tagName.toLowerCase()==\"input\"&&a==\"value\")d.value=b;else if(d.setAttribute)a==\"checked\"&&(b==\"\"||b==false||typeof b==\"undefined\")?d.removeAttribute(a):d.setAttribute(a,b)});else{var c=[];this.each(function(d){if(d.tagName&&d.tagName.toLowerCase()==\"input\"&&a==\"value\")c.push(d.value);else d.getAttribute&&d.getAttribute(a)&&c.push(d.getAttribute(a))});return c}}});\"inner outer top bottom remove before after\".split(\" \").forEach(function(a){i.fn[a]=function(b){return function(c){return this.html(b,c)}}(a)});i.events={};var u={};i.extend({on:function(a,b,c){return this.each(function(d){if(i.events[a]){var f=v(d);f=B(f,a);c=c||{};c.handler=function(e,h){i.fn.fire.call(i(this),a,h)};f.length||i.events[a].call(d,c)}d.addEventListener(a,P(d,a,b),false)})},un:function(a,b){return this.each(function(c){for(var d=v(c),f=B(d,a),e=f.length;e--;)if(b===w||b.guid===f[e].guid){c.removeEventListener(a,f[e],false);J(u[d][a],e,1)}u[d][a].length===0&&delete u[d][a];for(var h in u[d])return;delete u[d]})},fire:function(a,b){return this.each(function(c){if(c==n&&!c.dispatchEvent)c=n.documentElement;var d=n.createEvent(\"HTMLEvents\");d.initEvent(a,true,true);d.data=b||{};d.eventName=a;c.dispatchEvent(d)})}});\"click load submit touchstart touchmove touchend touchcancel gesturestart gesturechange gestureend orientationchange\".split(\" \").forEach(function(a){i.fn[a]=function(b){return function(c){return c?this.on(b,c):this.fire(b)}}(a)});i(l).on(\"load\",function(){\"onorientationchange\"in n.body||function(a,b){i(l).on(\"resize\",function(){var c=l.innerWidth<a&&l.innerHeight>b&&l.innerWidth<l.innerHeight,d=l.innerWidth>a&&l.innerHeight<b&&l.innerWidth>l.innerHeight;if(c||d){l.orientation=c?0:90;i(\"body\").fire(\"orientationchange\");a=l.innerWidth;b=l.innerHeight}})}(l.innerWidth,l.innerHeight)});i.touch=function(){try{return!!n.createEvent(\"TouchEvent\").initTouchEvent}catch(a){return false}}();i.ready=function(a){domReady(a)};v.id=1;i.extend({tween:function(a,b){var c=function(){var f={};\"duration after easing\".split(\" \").forEach(function(e){if(a[e]){f[e]=a[e];delete a[e]}});return f}(a),d=function(f){var e=[],h;if(typeof f!=z){for(h in f)e.push(E(h)+\":\"+f[h]);e=e.join(\";\")}else e=f;return e}(a);return this.each(function(f){emile(f,d,c,b)})}});var Q=/^(\\s|\u00A0)+|(\\s|\u00A0)+$/g;i.extend({setStyle:function(a,b){a=K(a);return this.each(function(c){c.style[a]=b})},getStyle:function(a,b){var c=function(f,e){return n.defaultView.getComputedStyle(f,\"\").getPropertyValue(E(e))};if(b===w){var d=[];this.each(function(f){d.push(c(f,a))});return d}else return this.each(function(f){b(c(f,a))})},addClass:function(a){var b=a.split(\" \");return this.each(function(c){b.forEach(function(d){if(C(c,d)===false)c.className=A(c.className+\" \"+d)})})},hasClass:function(a,b){var c=this,d=a.split(\" \");return this.length&&function(){var f=true;c.each(function(e){d.forEach(function(h){if(C(e,h))b&&b(e);else f=false})});return f}()},removeClass:function(a){if(a===w)this.each(function(c){c.className=\"\"});else{var b=a.split(\" \");this.each(function(c){b.forEach(function(d){c.className=A(c.className.replace(D(d),\"$1\"))})})}return this},toggleClass:function(a){var b=a.split(\" \");return this.each(function(c){b.forEach(function(d){c.className=C(c,d)?A(c.className.replace(D(d),\"$1\")):A(c.className+\" \"+d)})})},css:function(a){for(var b in a)this.setStyle(b,a[b]);return this}});var F={},D=function(a){var b=F[a];if(!b){b=new RegExp(\"(^|\\s+)\"+a+\"(?:\\s+|$)\");F[a]=b}return b};i.extend({xhr:function(a,b,c){function d(){if(h.readyState==4){delete e.xmlHttpRequest;if(h.status===0||h.status==200)h.handleResp();/^[45]/.test(h.status)&&h.handleError()}}if(!/^(inner|outer|top|bottom|before|after)$/.test(a)){c=b;b=a;a=\"inner\"}var f=c?c:{};if(typeof c==\"function\"){f={};f.callback=c}var e=this,h=new XMLHttpRequest;c=f.method||\"get\";var k=typeof f.async!=\"undefined\"?f.async:true,r=f.data||null,g;h.queryString=r;h.open(c,b,k);h.setRequestHeader(\"X-Requested-With\",\"XMLHttpRequest\");c.toLowerCase()==\"post\"&&h.setRequestHeader(\"Content-Type\",\"application/x-www-form-urlencoded\");for(g in f.headers)f.headers.hasOwnProperty(g)&&h.setRequestHeader(g,f.headers[g]);h.handleResp=f.callback!=null?f.callback:function(){e.html(a,h.responseText)};h.handleError=f.error&&typeof f.error==\"function\"?f.error:function(){};if(k){h.onreadystatechange=d;this.xmlHttpRequest=h}h.send(r);k||d();return this}});(function(a,b){function c(g,o,m){return(g+(o-g)*m).toFixed(3)}function d(g,o,m){return g.substr(o,m||1)}function f(g,o,m){for(var q=2,p,j,t=[],x=[];p=3,j=arguments[q-1],q--;)if(d(j,0)==\"r\")for(j=j.match(/\\d+/g);p--;)t.push(~~j[p]);else{if(j.length==4)j=\"#\"+d(j,1)+d(j,1)+d(j,2)+d(j,2)+d(j,3)+d(j,3);for(;p--;)t.push(parseInt(d(j,1+p*2,2),16))}for(;p--;){q=~~(t[p+3]+(t[p]-t[p+3])*m);x.push(q<0?0:q>255?255:q)}return\"rgb(\"+x.join(\",\")+\")\"}function e(g){var o=parseFloat(g);g=g.replace(/^[\\-\\d\\.]+/,\"\");return isNaN(o)?{v:g,f:f,u:\"\"}:{v:o,f:c,u:g}}function h(g){var o={},m=r.length,q;k.innerHTML='<div style=\"'+g+'\"></div>';for(g=k.childNodes[0].style;m--;)if(q=g[r[m]])o[r[m]]=e(q);return o}var k=n.createElement(\"div\"),r=\"backgroundColor borderBottomColor borderBottomWidth borderLeftColor borderLeftWidth borderRightColor borderRightWidth borderSpacing borderTopColor borderTopWidth bottom color fontSize fontWeight height left letterSpacing lineHeight marginBottom marginLeft marginRight marginTop maxHeight maxWidth minHeight minWidth opacity outlineColor outlineOffset outlineWidth paddingBottom paddingLeft paddingRight paddingTop right textIndent top width wordSpacing zIndex\".split(\" \"); b[a]=function(g,o,m,q){g=typeof g==\"string\"?n.getElementById(g):g;m=m||{};var p=h(o);o=g.currentStyle?g.currentStyle:getComputedStyle(g,null);var j,t={},x=+new Date,G=m.duration||200,H=x+G,I,U=m.easing||function(y){return-Math.cos(y*Math.PI)/2+0.5};for(j in p)t[j]=e(o[j]);I=setInterval(function(){var y=+new Date,V=y>H?1:(y-x)/G;for(j in p)g.style[j]=p[j].f(t[j].v,p[j].v,U(V))+p[j].u;if(y>H){clearInterval(I);m.after&&m.after();q&&setTimeout(q,1)}},10)}})(\"emile\",this);(function(a,b){function c(g){for(r=1;g=d.shift();)g()}var d=[],f,e,h=b.documentElement,k=h.doScroll,r=/^loade|c/.test(b.readyState);b.addEventListener&&b.addEventListener(\"DOMContentLoaded\",e=function(){b.removeEventListener(\"DOMContentLoaded\",e,false);c()},false);k&&b.attachEvent(\"onreadystatechange\",f=function(){if(/^c/.test(b.readyState)){b.detachEvent(\"onreadystatechange\",f);c()}});a.domReady=k?function(g){self!=top?r?g():d.push(g):function(){try{h.doScroll(\"left\")}catch(o){return setTimeout(function(){a.domReady(g)},50)}g()}()}:function(g){r?g():d.push(g)}})(this,n)})();";
    
        [webview stringByEvaluatingJavaScriptFromString: xui];
        
        NSString* linkRemoval = @"x$('a').setStyle('display', 'none')";
        [webview stringByEvaluatingJavaScriptFromString: linkRemoval];

    }
    
}



@end
