// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "SharePlugin.h"

static NSString *const PLATFORM_CHANNEL = @"plugins.flutter.io/share";

@interface ShareData : NSObject <UIActivityItemSource>

@property(readonly, nonatomic, copy) NSString *subject;
@property(readonly, nonatomic, copy) NSString *text;

- (instancetype)initWithSubject:(NSString *)subject text:(NSString *)text NS_DESIGNATED_INITIALIZER;

- (instancetype)init __attribute__((unavailable("Use initWithSubject:text: instead")));

@end

@implementation ShareData

- (instancetype)init {
  [super doesNotRecognizeSelector:_cmd];
  return nil;
}

- (instancetype)initWithSubject:(NSString *)subject text:(NSString *)text {
  self = [super init];
  if (self) {
    _subject = subject;
    _text = text;
  }
  return self;
}

- (id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController {
  return @"";
}

- (id)activityViewController:(UIActivityViewController *)activityViewController
         itemForActivityType:(UIActivityType)activityType {
  return _text;
}

- (NSString *)activityViewController:(UIActivityViewController *)activityViewController
              subjectForActivityType:(UIActivityType)activityType {
  return [_subject isKindOfClass:NSNull.class] ? @"" : _subject;
}

@end
@interface FLTSharePlugin() <UIPopoverPresentationControllerDelegate>
@property (nonatomic,strong) UIViewController *viewController;
@property (nonatomic) CGRect originRect;
@end

@implementation FLTSharePlugin
-(instancetype) initWithViewController:(UIViewController *)viewController {
    self = [super init];
    if(self) {
        _viewController = viewController;
    }
    return self;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    FlutterMethodChannel *shareChannel = [FlutterMethodChannel methodChannelWithName:PLATFORM_CHANNEL
                                binaryMessenger:registrar.messenger];

    FLTSharePlugin *instance = [[FLTSharePlugin alloc]initWithViewController:[UIApplication sharedApplication].delegate.window.rootViewController];
    [registrar addMethodCallDelegate:instance channel:shareChannel];
}
-(void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSDictionary *arguments = [call arguments];
    if ([@"share" isEqualToString:call.method]) {
      NSString *shareText = arguments[@"text"];
      NSString *shareSubject = arguments[@"subject"];

      if (shareText.length == 0) {
        result([FlutterError errorWithCode:@"error"
                                   message:@"Non-empty text expected"
                                   details:nil]);
        return;
      }

      [self makeOriginFromArguments:arguments];
      [self share:shareText
                 subject:shareSubject
          withController:[UIApplication sharedApplication].keyWindow.rootViewController
                atSource:self.originRect];
      result(nil);
    } else if([@"updateOrigin" isEqualToString:call.method]) {
        [self makeOriginFromArguments:arguments];
    } else{
      result(FlutterMethodNotImplemented);
    }
}
-(void)makeOriginFromArguments:(NSDictionary*)arguments {
    NSNumber *originX = arguments[@"originX"];
    NSNumber *originY = arguments[@"originY"];
    NSNumber *originWidth = arguments[@"originWidth"];
    NSNumber *originHeight = arguments[@"originHeight"];

    self.originRect = CGRectZero;
    if (originX != nil && originY != nil && originWidth != nil && originHeight != nil) {
      self.originRect = CGRectMake([originX doubleValue], [originY doubleValue],
                              [originWidth doubleValue], [originHeight doubleValue]);
    }

}
-(void)popoverPresentationController:(UIPopoverPresentationController *)popoverPresentationController willRepositionPopoverToRect:(inout CGRect *)rect inView:(inout UIView * _Nonnull __autoreleasing *)view {
    *rect = self.originRect;
}
- (void)share:(NSString *)shareText
           subject:(NSString *)subject
    withController:(UIViewController *)controller
          atSource:(CGRect)origin {
  ShareData *data = [[ShareData alloc] initWithSubject:subject text:shareText];
  UIActivityViewController *activityViewController =
      [[UIActivityViewController alloc] initWithActivityItems:@[ data ] applicationActivities:nil];
  activityViewController.popoverPresentationController.sourceView = controller.view;
    activityViewController.popoverPresentationController.delegate = self;
  if (!CGRectIsEmpty(origin)) {
    activityViewController.popoverPresentationController.sourceRect = origin;
  }
  [controller presentViewController:activityViewController animated:YES completion:nil];
}

@end
