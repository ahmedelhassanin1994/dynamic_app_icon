#import "DynamicAppIconPlugin.h"
#import <UserNotifications/UserNotifications.h>

@implementation DynamicAppIconPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"dynamic_app_icon"
                                     binaryMessenger:[registrar messenger]];
    DynamicAppIconPlugin* instance = [[DynamicAppIconPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"getPlatformVersion" isEqualToString:call.method]) {
        result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
    } else if ([@"supportsAlternateIcons" isEqualToString:call.method]) {
        if (@available(iOS 10.3, *)) {
            result(@(UIApplication.sharedApplication.supportsAlternateIcons));
        } else {
            result([FlutterError errorWithCode:@"UNAVAILABLE"
                                    message:@"Not supported on iOS ver < 10.3"
                                    details:nil]);
        }
    } else if ([@"getAlternateIconName" isEqualToString:call.method]) {
        if (@available(iOS 10.3, *)) {
            result(UIApplication.sharedApplication.alternateIconName);
        } else {
            result([FlutterError errorWithCode:@"UNAVAILABLE"
                                    message:@"Not supported on iOS ver < 10.3"
                                    details:nil]);
        }
    } else if ([@"changeIcon" isEqualToString:call.method]) {
        if (@available(iOS 10.3, *)) {
            @try {
                NSString *iconName = call.arguments[@"iconName"];
                if (iconName == (id)[NSNull null] || [iconName isEqualToString:@""]) {
                    iconName = nil;
                }
                
                // For compatibility with common showAlert needs
                BOOL showAlert = YES;
                if (call.arguments[@"showAlert"] != nil) {
                    showAlert = [call.arguments[@"showAlert"] boolValue];
                }

                if(!showAlert){
                    NSMutableString *selectorString = [[NSMutableString alloc] initWithCapacity:40];
                    [selectorString appendString:@"_setAlternate"];
                    [selectorString appendString:@"IconName:"];
                    [selectorString appendString:@"completionHandler:"];

                    SEL selector = NSSelectorFromString(selectorString);
                    IMP imp = [[UIApplication sharedApplication] methodForSelector:selector];
                    void (*func)(id, SEL, id, id) = (void *)imp;
                    if (func)
                    {
                        func([UIApplication sharedApplication], selector, iconName, ^(NSError * _Nullable error) {
                            if(error) {
                                result([FlutterError errorWithCode:@"Failed to set icon"
                                                        message:[error description]
                                                        details:nil]);
                            } else {
                                result(nil);
                            }
                        });
                        return;
                    }
                }
                
                [UIApplication.sharedApplication setAlternateIconName:iconName completionHandler:^(NSError * _Nullable error) {
                    if(error) {
                        result([FlutterError errorWithCode:@"Failed to set icon"
                                                message:[error description]
                                                details:nil]);
                    } else {
                        result(nil);
                    }
                }];
            }
            @catch (NSException *exception) {
                NSLog(@"%@", exception.reason);
                result([FlutterError errorWithCode:@"Failed to set icon"
                                        message:exception.reason
                                        details:nil]);
            }
        } else {
            result([FlutterError errorWithCode:@"UNAVAILABLE"
                                    message:@"Not supported on iOS ver < 10.3"
                                    details:nil]);
        }
    } else {
        result(FlutterMethodNotImplemented);
    }
}

@end
