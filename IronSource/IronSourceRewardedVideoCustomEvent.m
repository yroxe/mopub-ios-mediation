//
//  IronSourceRewardedVideoCustomEvent.m
//

#import "IronSourceRewardedVideoCustomEvent.h"
#import "IronSourceAdapterConfiguration.h"
#import "IronSourceConstants.h"
#if __has_include("MoPub.h")
    #import "MPLogging.h"
    #import "MPReward.h"
    #import "MoPub.h"
#endif

@interface IronSourceRewardedVideoCustomEvent()<IronSourceRewardedVideoDelegate>

#pragma mark Class local properties
@property (nonatomic, copy) NSString *instanceID;
@end
@implementation IronSourceRewardedVideoCustomEvent
@dynamic delegate;
@dynamic localExtras;
@dynamic hasAdAvailable;

- (NSString *) getAdNetworkId {
    return _instanceID;
}

#pragma mark - MPFullscreenAdAdapter Override

- (BOOL)isRewardExpected {
    return YES;
}

- (BOOL)hasAdAvailable {
    BOOL isRVAvailable = [IronSource hasISDemandOnlyRewardedVideo:self.instanceID];
    MPLogInfo(@"IronSource hasAdAvailable returned %d (current instance: %@)",
              isRVAvailable, [self getAdNetworkId]);
    return isRVAvailable;
}

- (BOOL)enableAutomaticImpressionAndClickTracking
{
    return NO;
}

- (void)requestAdWithAdapterInfo:(NSDictionary *)info adMarkup:(NSString *)adMarkup {
    MPLogInfo(@"IronSource requestRewardedVideoWithCustomEventInfo with: %@", info);
    
    // Collect and pass the user's consent from MoPub onto the ironSource SDK
    if ([[MoPub sharedInstance] isGDPRApplicable] == MPBoolYes) {
        BOOL canCollectPersonalInfo = [[MoPub sharedInstance] canCollectPersonalInfo];
        [IronSource setConsent:canCollectPersonalInfo];
    }
    
    @try {
        self.instanceID = kDefaultInstanceId;
        NSString *appKey = @"";
        if (info == nil) {
            MPLogInfo(@"serverParams is null. Make sure you have entered IronSource's application and instance keys on the MoPub dashboard");
            NSError *error = [IronSourceUtils createErrorWith:@"Can't initialize IronSource Rewarded Video"
                                                    andReason:@"serverParams is null"
                                                andSuggestion:@"make sure that server parameters is added"];
            MPLogAdEvent([MPLogEvent adLoadFailedForAdapter:NSStringFromClass(self.class) error: error], self.instanceID);
            [self.delegate fullscreenAdAdapter:self didFailToLoadAdWithError:error];
            return;
        }
        if([info objectForKey:kIronSourceAppKey] != nil ){
            appKey = [info objectForKey:kIronSourceAppKey];
        }
        
        if ([IronSourceUtils isEmpty:appKey]) {
            MPLogInfo(@"IronSource Adapter failed to request RewardedVideo, 'applicationKey' parameter is missing. make sure that 'applicationKey' server parameter is added");
            NSError *error = [IronSourceUtils createErrorWith:@"IronSource Adapter failed to request RewardedVideo"
                                                    andReason:@"applicationKey parameter is missing"
                                                andSuggestion:@"make sure that 'applicationKey' server parameter is added"];
            
            MPLogAdEvent([MPLogEvent adLoadFailedForAdapter:NSStringFromClass(self.class) error: error], self.instanceID);
            [self.delegate fullscreenAdAdapter:self didFailToLoadAdWithError:error];
            
            return;
        }
        
        if (([info objectForKey:kIronSourceInstanceId] != nil) && (![[info objectForKey:kIronSourceInstanceId] isEqualToString:@""]))
        {
            self.instanceID = [info objectForKey:kIronSourceInstanceId];
        }
        
        MPLogInfo(@"IronSource Rewarded Video initialization with appkey %@", appKey);
        // Cache the initialization parameters
        [IronSourceAdapterConfiguration updateInitializationParameters:info];
        [[IronSourceManager sharedManager] initIronSourceSDKWithAppKey:appKey forAdUnits:[NSSet setWithObject:@[IS_REWARDED_VIDEO]]];
        [self loadRewardedVideo: self.instanceID WithAdMarkup: adMarkup];
    } @catch (NSException *exception) {
        MPLogInfo(@"IronSource Rewarded Video initialization with error: %@", exception);
        NSError *error = [NSError errorWithDomain:MoPubRewardedVideoAdsSDKDomain code:MOPUBErrorAdapterInvalid userInfo:@{NSLocalizedDescriptionKey: @"Custom event class Rewarded Video error.", NSLocalizedRecoverySuggestionErrorKey: @"Native Network or Custom Event adapter was configured incorrectly."}];
        MPLogAdEvent([MPLogEvent adLoadFailedForAdapter:NSStringFromClass(self.class) error: error], self.instanceID);
        [self.delegate fullscreenAdAdapter:self didFailToLoadAdWithError:error];
    }
}

- (void)presentAdFromViewController:(UIViewController *)viewController {
    MPLogInfo(@"IronSource showRewardedVideo for instance %@",
              [self getAdNetworkId]);
    MPLogAdEvent([MPLogEvent adShowAttemptForAdapter:NSStringFromClass(self.class)], [self getAdNetworkId]);
    [[IronSourceManager sharedManager] presentRewardedAdFromViewController:viewController
                                                                 instanceID:_instanceID];
}

#pragma mark IronSource RV Methods
-(void) loadRewardedVideo:(NSString *)instanceId WithAdMarkup: (NSString *) adMarkup {
    MPLogInfo(@"IronSource loadRewardedVideo for instance %@ (current instance %@)",
              instanceId, [self getAdNetworkId]);
    MPLogAdEvent([MPLogEvent adLoadAttemptForAdapter:NSStringFromClass(self.class) dspCreativeId:nil dspName:nil],instanceId);
    [[IronSourceManager sharedManager] loadRewardedAdWithDelegate:self instanceID: instanceId WithAdMarkup: adMarkup];
}

#pragma mark IronSource RV Events

/*!
 * @discussion Invoked when an Ad failed to display.
 *
 *          error - NSError which contains the reason for the failure.
 *          The error contains error.code and error.message.
 */
- (void)rewardedVideoDidFailToShowWithError:(NSError *)error instanceId:(NSString *)instanceId {
    MPLogInfo(@"IronSource RewardedVideo failed to show for instance %@ (current isntance %@)",
              instanceId, [self getAdNetworkId]);
    MPLogAdEvent([MPLogEvent adShowFailedForAdapter:NSStringFromClass(self.class) error:error], instanceId);
    [self.delegate fullscreenAdAdapter:self didFailToShowAdWithError:error];
}

/*!
 * @discussion Invoked when the RewardedVideo ad view has opened.
 *
 */
- (void)rewardedVideoDidOpen:(NSString *)instanceId {
    MPLogInfo(@"IronSource RewardedVideo did open for instance %@ (current instance %@)",
              instanceId, [self getAdNetworkId]);
    MPLogAdEvent([MPLogEvent adWillAppearForAdapter:NSStringFromClass(self.class)], instanceId);
    [self.delegate fullscreenAdAdapterAdWillAppear:self];
    MPLogAdEvent([MPLogEvent adShowSuccessForAdapter:NSStringFromClass(self.class)], instanceId);
    MPLogAdEvent([MPLogEvent adDidAppearForAdapter:NSStringFromClass(self.class)], instanceId);
    [self.delegate fullscreenAdAdapterAdDidAppear:self];
    
    [self.delegate fullscreenAdAdapterDidTrackImpression:self];
}

/*!
 * @discussion Invoked when the user is about to return to the application after closing the RewardedVideo ad.
 *
 */
- (void)rewardedVideoDidClose:(NSString *)instanceId {
    MPLogInfo(@"IronSource RewardedVideo did close for instance %@ (current instance %@)",
              instanceId, [self getAdNetworkId]);
    MPLogAdEvent([MPLogEvent adWillDisappearForAdapter:NSStringFromClass(self.class)], instanceId);
    [self.delegate fullscreenAdAdapterAdWillDisappear:self];
    MPLogAdEvent([MPLogEvent adDidDisappearForAdapter:NSStringFromClass(self.class)], instanceId);
    [self.delegate fullscreenAdAdapterAdDidDisappear:self];
}

- (void)rewardedVideoAdRewarded:(NSString *)instanceId {
    MPLogInfo(@"IronSource received reward for instance %@ (current instance %@)",
              instanceId, [self getAdNetworkId]);
    MPReward *reward = [[MPReward alloc] initWithCurrencyType:kMPRewardCurrencyTypeUnspecified
                                                       amount:@(kMPRewardCurrencyAmountUnspecified)];
    MPLogEvent([MPLogEvent adShouldRewardUserWithReward:reward]);
    [self.delegate fullscreenAdAdapter:self willRewardUser:reward];
}

/*!
 * @discussion Invoked when a video has been clicked.
 */
- (void)rewardedVideoDidClick:(NSString *)instanceId {
    MPLogInfo(@"IronSource RewardedVideo did click for instance %@ (current instance %@)",
              instanceId, [self getAdNetworkId]);
    MPLogAdEvent([MPLogEvent adTappedForAdapter:NSStringFromClass(self.class)], instanceId);
    [self.delegate fullscreenAdAdapterDidReceiveTap:self];
    [self.delegate fullscreenAdAdapterWillLeaveApplication:self];
    [self.delegate fullscreenAdAdapterDidTrackClick:self];
}


- (void)rewardedVideoDidFailToLoadWithError:(NSError *)error instanceId:(NSString *)instanceId {
    MPLogDebug(@"IronSource RewardedVideo load fail for instance %@ (current instance: %@)",
               instanceId, [self getAdNetworkId]);
    MPLogAdEvent([MPLogEvent adLoadFailedForAdapter:NSStringFromClass(self.class) error: error], instanceId);
    [self.delegate fullscreenAdAdapter:self didFailToLoadAdWithError:error];
}


- (void)rewardedVideoDidLoad:(NSString *)instanceId {
    MPLogInfo(@"IronSource RewardedVideo did load for instance %@ (current instance: %@)",
              instanceId, [self getAdNetworkId]);
    MPLogAdEvent([MPLogEvent adLoadSuccessForAdapter:NSStringFromClass(self.class)], instanceId);
    [self.delegate fullscreenAdAdapterDidLoadAd:self];
}
@end

