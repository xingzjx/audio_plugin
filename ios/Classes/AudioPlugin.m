#import "AudioPlugin.h"
#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

static NSString *const CHANNEL_NAME = @"audio_plugin";
static FlutterMethodChannel *channel;
static AVPlayer *player;
static AVPlayerItem *playerItem;

@interface AudioPlugin()
-(void)pause;
-(void)stop;
-(void)mute:(BOOL)muted;
-(void)seek:(CMTime)time;
-(void)onStart;
-(void)onTimeInterval:(CMTime)time;
@end

@implementation AudioPlugin

CMTime position;
NSString *lastUrl;
BOOL isPlaying = false;
NSMutableSet *observers;
NSMutableSet *timeobservers;
FlutterMethodChannel *_channel;
NSMutableArray *resources;

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:CHANNEL_NAME
                                     binaryMessenger:[registrar messenger]];
    AudioPlugin* instance = [[AudioPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
    _channel = channel;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    typedef void (^CaseBlock)(void);
    // Squint and this looks like a proper switch!
    NSDictionary *methods = @{
                              @"play":
                                  ^{
                                      NSMutableData *obj = call.arguments[@"url"];
                                      if([obj isKindOfClass:[NSString class]]) {
                                          // int isLocal = [call.arguments[@"isLocal"] intValue];
                                          NSString *url = call.arguments[@"url"];
                                          resources = [NSMutableArray arrayWithCapacity:1];
                                          [resources addObject:url];
                                          result(nil);
                                      } else if([obj isKindOfClass:[NSMutableArray class]]) {
                                          resources = call.arguments[@"url"];
                                      }
                                      [self playList];
                                  },
                              @"pause":
                                  ^{
                                      [self pause];
                                      result(nil);
                                  },
                              @"stop":
                                  ^{
                                      [self stop];
                                      result(nil);
                                  },
                              @"mute":
                                  ^{
                                      [self mute:[call.arguments boolValue]];
                                      result(nil);
                                  },
                              @"seek":
                                  ^{
                                      [self seek:CMTimeMakeWithSeconds([call.arguments doubleValue], 1)];
                                      result(nil);
                                  }
                              };
    
    CaseBlock c = methods[call.method];
    if (c) {
        c();
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)playList {
    if(resources!=nil && [resources count] > 0 ) {
        NSString* url = [resources firstObject];
        [self play:url];
    }
}

- (void)play:(NSString*)url {
    NSLog(@"============================> play");
    if (![url isEqualToString:lastUrl]) {
        [playerItem removeObserver:self
                        forKeyPath:@"player.currentItem.status"];
        
        for (id ob in observers) {
            [[NSNotificationCenter defaultCenter] removeObserver:ob];
        }
        observers = nil;
        if([url hasPrefix:@"http"]) {// http
            NSLog(@"path:%@", url);
            playerItem = [[AVPlayerItem alloc] initWithURL:[NSURL URLWithString:url]];
        } else if([url hasPrefix:@"/"]) {// sdcard
            NSString * documentPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
            url = [documentPath stringByAppendingString:url];
            NSLog(@"path:%@", url);
            playerItem = [[AVPlayerItem alloc] initWithURL:[NSURL fileURLWithPath:url]];
        } else {// 工程目录 相当于Android里面的Assets
            NSArray *listItems = [url componentsSeparatedByString:@"."];
            NSString *resName = [@"" stringByAppendingString:listItems[0]];// todo：resources 加入不了？
            NSString *path = [[NSBundle mainBundle] pathForResource:resName ofType:@"mp3"];
            NSLog(@"path:%@", path);
            if(path!=nil) {
                playerItem = [[AVPlayerItem alloc] initWithURL:[NSURL fileURLWithPath:path]];
            }
        }
        lastUrl = url;
        id anobserver = [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemDidPlayToEndTimeNotification
                                                                          object:playerItem
                                                                           queue:nil
                                                                      usingBlock:^(NSNotification* note){
                                                                          [self stop];
                                                                          [resources removeObject:url];
                                                                          if([resources count] > 0) {
                                                                              NSString* url = [resources firstObject];
                                                                              [self play:url];
                                                                              [_channel invokeMethod:@"audio.onComplete" arguments:nil];
                                                                          }
                                                                      }];
        [observers addObject:anobserver];
        
        if (player) {
            [player replaceCurrentItemWithPlayerItem:playerItem];
        } else {
            player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
            // Stream player position.
            // This call is only active when the player is active so there's no need to
            // remove it when player is paused or stopped.
            CMTime interval = CMTimeMakeWithSeconds(0.2, NSEC_PER_SEC);
            id timeObserver = [player addPeriodicTimeObserverForInterval:interval queue:nil usingBlock:^(CMTime time){
                [self onTimeInterval:time];
            }];
            [timeobservers addObject:timeObserver];
        }
        
        // is sound ready
        [[player currentItem] addObserver:self
                               forKeyPath:@"player.currentItem.status"
                                  options:0
                                  context:nil];
    }
    [self onStart];
    [player play];
    isPlaying = true;
}

- (void)onStart {
    CMTime duration = [[player currentItem] duration];
    if (CMTimeGetSeconds(duration) > 0) {
        int mseconds= CMTimeGetSeconds(duration)*1000;
        [_channel invokeMethod:@"audio.onStart" arguments:@(mseconds)];
    }
}

- (void)onTimeInterval:(CMTime)time {
    int mseconds =  CMTimeGetSeconds(time)*1000;
    [_channel invokeMethod:@"audio.onCurrentPosition" arguments:@(mseconds)];
}

- (void)pause {
    [player pause];
    isPlaying = false;
    [_channel invokeMethod:@"audio.onPause" arguments:nil];
}

- (void)stop {
    if (isPlaying) {
        [player pause];
        isPlaying = false;
    }
    [playerItem seekToTime:CMTimeMake(0, 1)];
    [_channel invokeMethod:@"audio.onStop" arguments:nil];
}

- (void)mute:(BOOL)muted {
    player.muted = muted;
}

- (void)seek:(CMTime)time {
    [playerItem seekToTime:time];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if ([keyPath isEqualToString:@"player.currentItem.status"]) {
        if ([[player currentItem] status] == AVPlayerItemStatusReadyToPlay) {
            [self onStart];
        } else if ([[player currentItem] status] == AVPlayerItemStatusFailed) {
            [_channel invokeMethod:@"audio.onError" arguments:@[(player.currentItem.error.localizedDescription)]];
        }
    } else {
        // Any unrecognized context must belong to super
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}

- (void)dealloc {
    for (id ob in timeobservers) {
        [player removeTimeObserver:ob];
    }
    timeobservers = nil;
    
    for (id ob in observers) {
        [[NSNotificationCenter defaultCenter] removeObserver:ob];
    }
    observers = nil;
}

@end
