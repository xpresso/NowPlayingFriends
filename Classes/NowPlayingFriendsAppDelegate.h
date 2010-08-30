//
//  NowPlayingFriendsAppDelegate.h
//  NowPlayingFriends
//
//  Created by Hiroe Shin on 10/08/12.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <QuartzCore/QuartzCore.h>

#define kTweetTemplate @"♪ Now Playing \"[st]\" by \"[ar]\" ♬ #nowplaying"

@interface NowPlayingFriendsAppDelegate : NSObject <UIApplicationDelegate> {
  
  UIWindow *window;
  
@private
  NSManagedObjectContext *managedObjectContext_;
  NSManagedObjectModel *managedObjectModel_;
  NSPersistentStoreCoordinator *persistentStoreCoordinator_;
  UITabBarController *tabBarController;
  
  NSMutableDictionary *profileImages;
  MPMusicPlayerController *musicPlayer;
  
  NSInteger testFlag;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, retain) UITabBarController *tabBarController;
@property (nonatomic, retain) NSMutableDictionary *profileImages;
@property (nonatomic, retain) MPMusicPlayerController *musicPlayer;

- (NSString *)applicationDocumentsDirectory;
- (UINavigationController *)navigationWithViewController:(id)viewController
						   title:(NSString *)title
					       imageName:(NSString *)imageName;

- (void)addMusicPlayerNotification:(id)object;
- (void)setupMusicPlayer;
- (void)handle_NowPlayingItemChanged:(id)notification;

- (NSString *)nowPlayingTitle;
- (NSString *)nowPlayingAlbumTitle;
- (NSString *)nowPlayingArtistName;
- (NSArray *)albums;
- (NSArray *)playLists;
- (NSString *)tweetString;

- (void)setHalfCurlAnimationWithController:(id)targetViewController
				 frontView:(UIView *)frontView
				    curlUp:(BOOL)curlUp;
- (void)setAnimationWithView:(id)targetView 
	       animationType:(UIViewAnimationTransition)transition;

- (void)checkAuthenticateWithController:(id)viewController;
- (NSString *)username:(NSDictionary *)data;

- (NSData *)profileImage:(NSDictionary *)data 
	       getRemote:(BOOL) getRemoteFlag;
- (NSData *)originalProfileImage:(NSDictionary *)data;

- (void)setResizedImage:(UIImage *)image 
	       toButton:(UIButton *)imageButton;

- (UIBarButtonItem *)listButton:(SEL)selector
			 target:(id)target;
- (UIBarButtonItem *)editButton:(SEL)selector
			 target:(id)target;
- (UIBarButtonItem *)cancelButton:(SEL)selector
			   target:(id)target;
- (UIBarButtonItem *)playerButton:(SEL)selector
			   target:(id)target;
- (UIBarButtonItem *)completeButton:(SEL)selector
			     target:(id)target;

@end

