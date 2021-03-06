//
//  JavaScriptAPI.h
//  InteractiveReports
//
//  Created by Tyler Burgett on 1/16/15.
//  Copyright (c) 2015 mil.nga. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "WebViewJavascriptBridge.h"
#import "Report.h"

@interface JavaScriptAPI : NSObject <CLLocationManagerDelegate>

@property (strong, nonatomic)UIWebView *webview;
@property (strong, nonatomic)NSObject<UIWebViewDelegate> *webViewDelegate;
@property (strong, nonatomic)Report* report;
@property (strong, nonatomic)CLLocationManager *locationManager;
@property (strong, nonatomic)WebViewJavascriptBridge *bridge;

- (id)initWithWebView:(UIWebView *)webView report:(Report *)report andDelegate:(NSObject<UIWebViewDelegate> *)delegate;
- (void)sendToBridge:(NSString*)string;

@end
