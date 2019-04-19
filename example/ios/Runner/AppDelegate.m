#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"
#import <Foundation/Foundation.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];
  // Override point for customization after application launch.
  NSLog(@"aaaaaaaa");
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end
