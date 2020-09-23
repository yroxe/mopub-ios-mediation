#import "AppLovinBannerCustomEvent.h"
#import "AppLovinAdapterConfiguration.h"

#if __has_include("MoPub.h")
    #import "MPConstants.h"
    #import "MPError.h"
    #import "MPLogging.h"
    #import "MoPub.h"
#endif

#if __has_include(<AppLovinSDK/AppLovinSDK.h>)
    #import <AppLovinSDK/AppLovinSDK.h>
#else
    #import "ALAdView.h"
    #import "ALPrivacySettings.h"
#endif

#define DEFAULT_ZONE @""
#define ZONE_FROM_INFO(__INFO) ( ([__INFO[@"zone_id"] isKindOfClass: [NSString class]] && ((NSString *) __INFO[@"zone_id"]).length > 0) ? __INFO[@"zone_id"] : @"" )

/**
 * The receiver object of the ALAdView's delegates. This is used to prevent a retain cycle between the ALAdView and AppLovinBannerCustomEvent.
 */
@interface AppLovinMoPubBannerDelegate : NSObject<ALAdLoadDelegate, ALAdDisplayDelegate, ALAdViewEventDelegate>
@property (nonatomic, weak) AppLovinBannerCustomEvent *parentCustomEvent;
- (instancetype)initWithCustomEvent:(AppLovinBannerCustomEvent *)parentCustomEvent;
@end

/**
 * The dedicated delegate for banner ads rendering ads from tokens.
 */
@interface AppLovinMoPubTokenBannerDelegate : AppLovinMoPubBannerDelegate<ALAdLoadDelegate>
@end

@interface AppLovinBannerCustomEvent()
@property (nonatomic, strong) ALSdk *sdk;
@property (nonatomic, strong) ALAdView *bannerView;
@end

@implementation AppLovinBannerCustomEvent
@dynamic delegate;
@dynamic localExtras;

static NSString *const kALMoPubMediationErrorDomain = @"com.applovin.sdk.mediation.mopub.errorDomain";
static NSString *zoneIdentifier;

// A dictionary of Zone -> AdView to be shared by instances of the custom event.
static NSMutableDictionary<NSString *, ALAdView *> *ALGlobalAdViews;

+ (void)initialize
{
    [super initialize];

    ALGlobalAdViews = [NSMutableDictionary dictionary];
}

#pragma mark - MPInlineAdAdapter Overridden Methods

- (void)requestAdWithSize:(CGSize)size adapterInfo:(NSDictionary *)info adMarkup:(NSString *)adMarkup
{
    // Collect and pass the user's consent from MoPub onto the AppLovin SDK
    if ([[MoPub sharedInstance] isGDPRApplicable] == MPBoolYes) {
        BOOL canCollectPersonalInfo = [[MoPub sharedInstance] canCollectPersonalInfo];
        [ALPrivacySettings setHasUserConsent: canCollectPersonalInfo];
    }
    
    self.sdk = [self SDKFromCustomEventInfo: info];
    
    if (self.sdk == nil) {
        NSString *failureReason = @"ALSdk instance is nil likely because no AppLovin SDK key is available. Failing ad request";
        
        NSError *error = [NSError errorWithDomain: kALMoPubMediationErrorDomain
                                             code: kALErrorCodeSdkDisabled
                                         userInfo: @{NSLocalizedFailureReasonErrorKey: failureReason}];
        MPLogAdEvent([MPLogEvent adLoadFailedForAdapter:NSStringFromClass(self.class) error:error], @"");
        
        [self.delegate inlineAdAdapter:self didFailToLoadAdWithError: error];

        return;
    }

    self.sdk.mediationProvider = ALMediationProviderMoPub;
    [self.sdk setPluginVersion: AppLovinAdapterConfiguration.pluginVersion];
    
    zoneIdentifier = ZONE_FROM_INFO(info);
    
    MPLogInfo(@"Requesting AppLovin banner with zoneIdentifier: %@", zoneIdentifier);
    
    NSString *format = [info objectForKey:@"adunit_format"];
    BOOL isBannerFormat = (format != nil ? [[format lowercaseString] containsString:@"banner"] : NO);
    
    if (!isBannerFormat) {
        MPLogInfo(@"AppLovin only supports 320*50 and 728*90 sized ads. Please ensure your MoPub adunit's format is Banner.");
        NSError *error = [NSError errorWithCode:MOPUBErrorAdapterFailedToLoadAd
                           localizedDescription:@"Unsupported sizes received. AppLovin only supports 320 x 50 and 728 x 90 ads. Please ensure your adunit's format is Banner in MoPub UI."];
        MPLogAdEvent([MPLogEvent adLoadFailedForAdapter:NSStringFromClass(self.class) error:error], zoneIdentifier);
        [self.delegate inlineAdAdapter:self didFailToLoadAdWithError:error];
        
        return;
    }
    
    [AppLovinAdapterConfiguration setCachedInitializationParameters: info];
    // Convert requested size to AppLovin Ad Size
    ALAdSize *adSize = [self appLovinAdSizeFromRequestedSize: size];
    BOOL hasAdMarkup = adMarkup.length > 0;
    
    MPLogInfo(@"Requesting AppLovin banner of size %@ and with ad markup: %d", NSStringFromCGSize(size), hasAdMarkup);
    
    // Create adview based off of zone (if any)
    self.bannerView = [[self class] adViewForFrame: [self rectFromAppLovinAdSize: adSize]
                                        adSize: adSize
                                zoneIdentifier: zoneIdentifier
                                   customEvent: self
                                           sdk: self.sdk];
    
    // Use token API
    if ( hasAdMarkup )
    {
        // Ad load delegate attached to Ad Service as well as adview
        AppLovinMoPubTokenBannerDelegate *tokenDelegate = [[AppLovinMoPubTokenBannerDelegate alloc] initWithCustomEvent: self];
        [self.sdk.adService loadNextAdForAdToken: adMarkup andNotify: tokenDelegate];
        
        MPLogAdEvent([MPLogEvent adLoadAttemptForAdapter:NSStringFromClass(self.class) dspCreativeId:nil dspName:nil], zoneIdentifier);
    }
    // Zone/regular ad load
    else
    {
        [self.bannerView loadNextAd];
        
        MPLogAdEvent([MPLogEvent adLoadAttemptForAdapter:NSStringFromClass(self.class) dspCreativeId:nil dspName:nil], zoneIdentifier);
    }
}

- (BOOL)enableAutomaticImpressionAndClickTracking
{
    return NO;
}

#pragma mark - Utility Methods

- (ALAdSize *)appLovinAdSizeFromRequestedSize:(CGSize)size
{
    return (size.width >= 728 && size.height >= 90) ? ALAdSize.leader : ALAdSize.banner;
}

- (CGRect)rectFromAppLovinAdSize:(ALAdSize *)alAdSize
{
    return alAdSize == ALAdSize.leader ? CGRectMake(0, 0, 728, 90) : CGRectMake(0, 0, 320, 50);
}

- (MOPUBErrorCode)toMoPubErrorCode:(int)appLovinErrorCode
{
    if ( appLovinErrorCode == kALErrorCodeNoFill )
    {
        return MOPUBErrorAdapterHasNoInventory;
    }
    else if ( appLovinErrorCode == kALErrorCodeAdRequestNetworkTimeout )
    {
        return MOPUBErrorNetworkTimedOut;
    }
    else if ( appLovinErrorCode == kALErrorCodeInvalidResponse )
    {
        return MOPUBErrorServerError;
    }
    else
    {
        return MOPUBErrorUnknown;
    }
}

- (ALSdk *)SDKFromCustomEventInfo:(NSDictionary *)info
{
    // The SDK key is not returned from the MoPub dashboard, so we statically read it
    // for Unity publishers who don't have access to the project's info.plist.
    NSString *SDKKey = AppLovinAdapterConfiguration.sdkKey;
    if ( SDKKey.length > 0 )
    {
        return [ALSdk sharedWithKey: SDKKey];
    }
    else
    {
        return [ALSdk shared];
    }
}

+ (ALAdView *)adViewForFrame:(CGRect)frame
                      adSize:(ALAdSize *)adSize
              zoneIdentifier:(NSString *)zoneIdentifier
                 customEvent:(AppLovinBannerCustomEvent *)customEvent
                         sdk:(ALSdk *)sdk
{
    ALAdView *adView;
    
    // Check if adview for zone already exists
    if ( ALGlobalAdViews[zoneIdentifier] )
    {
        adView = ALGlobalAdViews[zoneIdentifier];
    }
    else
    {
        adView = [[ALAdView alloc] initWithFrame: frame size: adSize sdk: sdk];
        // If this is a custom zone
        if ( zoneIdentifier.length > 0 )
        {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
            [adView performSelector: @selector(setZoneIdentifier:) withObject: zoneIdentifier];
#pragma clang diagnostic pop
        }
        
        ALGlobalAdViews[zoneIdentifier] = adView;
    }
    
    AppLovinMoPubBannerDelegate *delegate = [[AppLovinMoPubBannerDelegate alloc] initWithCustomEvent: customEvent];
    adView.adLoadDelegate = delegate;
    adView.adDisplayDelegate = delegate;
    adView.adEventDelegate = delegate;
    
    return adView;
}

@end

@implementation AppLovinMoPubBannerDelegate

#pragma mark - Initialization

- (instancetype)initWithCustomEvent:(AppLovinBannerCustomEvent *)parentCustomEvent
{
    self = [super init];
    if ( self )
    {
        self.parentCustomEvent = parentCustomEvent;
    }
    return self;
}

#pragma mark - Ad Load Delegate

- (void)adService:(ALAdService *)adService didLoadAd:(ALAd *)ad
{
    // Ensure logic is ran on main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.parentCustomEvent.delegate inlineAdAdapter: self.parentCustomEvent
                                           didLoadAdWithAdView: self.parentCustomEvent.bannerView];
        
        MPLogAdEvent([MPLogEvent adLoadSuccessForAdapter:NSStringFromClass(self.class)], [self getAdNetworkId]);
        MPLogAdEvent([MPLogEvent adWillAppearForAdapter:NSStringFromClass(self.class)], [self getAdNetworkId]);
        MPLogAdEvent([MPLogEvent adShowAttemptForAdapter:NSStringFromClass(self.class)], [self getAdNetworkId]);
    });
}

- (void)adService:(ALAdService *)adService didFailToLoadAdWithError:(int)code
{
    // Ensure logic is ran on main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        NSError *error = [NSError errorWithDomain: kALMoPubMediationErrorDomain
                                             code: [self.parentCustomEvent toMoPubErrorCode: code]
                                         userInfo: nil];
        [self.parentCustomEvent.delegate inlineAdAdapter: self.parentCustomEvent didFailToLoadAdWithError: error];
        
        MPLogAdEvent([MPLogEvent adLoadFailedForAdapter:NSStringFromClass(self.class) error:error], [self getAdNetworkId]);
    });
}

#pragma mark - Ad Display Delegate

- (void)ad:(ALAd *)ad wasDisplayedIn:(UIView *)view
{
    // `didDisplayAd` of this class would not be called by MoPub on AppLovin banner refresh if enabled.
    // Only way to track impression of AppLovin refresh is via this callback.
    [self.parentCustomEvent.delegate inlineAdAdapterDidTrackImpression:self.parentCustomEvent];
    
    MPLogAdEvent([MPLogEvent adShowSuccessForAdapter:NSStringFromClass(self.class)], [self getAdNetworkId]);
    MPLogAdEvent([MPLogEvent adDidAppearForAdapter:NSStringFromClass(self.class)], [self getAdNetworkId]);
}

- (void)ad:(ALAd *)ad wasHiddenIn:(UIView *)view
{
    MPLogAdEvent([MPLogEvent adWillDisappearForAdapter:NSStringFromClass(self.class)], [self getAdNetworkId]);
    MPLogAdEvent([MPLogEvent adDidDisappearForAdapter:NSStringFromClass(self.class)], [self getAdNetworkId]);
}

- (void)ad:(ALAd *)ad wasClickedIn:(UIView *)view
{
    [self.parentCustomEvent.delegate inlineAdAdapterDidTrackClick:self.parentCustomEvent];
    [self.parentCustomEvent.delegate inlineAdAdapterWillLeaveApplication:self.parentCustomEvent];
    
    MPLogAdEvent([MPLogEvent adTappedForAdapter:NSStringFromClass(self.class)], [self getAdNetworkId]);
}

#pragma mark - Ad View Event Delegate

- (void)ad:(ALAd *)ad didPresentFullscreenForAdView:(ALAdView *)adView
{
    [self.parentCustomEvent.delegate inlineAdAdapterWillBeginUserAction:self.parentCustomEvent];
}

- (void)ad:(ALAd *)ad willDismissFullscreenForAdView:(ALAdView *)adView
{
    MPLogInfo(@"Banner will dismiss fullscreen");
}

- (void)ad:(ALAd *)ad didDismissFullscreenForAdView:(ALAdView *)adView
{
    MPLogInfo(@"Banner did dismiss fullscreen");
    [self.parentCustomEvent.delegate inlineAdAdapterDidEndUserAction:self.parentCustomEvent];
}

- (void)ad:(ALAd *)ad willLeaveApplicationForAdView:(ALAdView *)adView
{
    // We will fire bannerCustomEventWillLeaveApplication:: in the ad:wasClickedIn: callback
}

- (void)ad:(ALAd *)ad didFailToDisplayInAdView:(ALAdView *)adView withError:(ALAdViewDisplayErrorCode)code
{
    NSString *failureReason = [NSString stringWithFormat: @"Banner failed to display: %ld", (long)code];
    
    NSError *error = [NSError errorWithDomain: kALMoPubMediationErrorDomain
                                         code: kALErrorCodeUnableToRenderAd
                                     userInfo: @{NSLocalizedFailureReasonErrorKey: failureReason}];
    MPLogAdEvent([MPLogEvent adShowFailedForAdapter:NSStringFromClass(self.class) error:error], [self getAdNetworkId]);
}

- (NSString *) getAdNetworkId {
    return zoneIdentifier;
}

@end

@implementation AppLovinMoPubTokenBannerDelegate

- (void)adService:(ALAdService *)adService didLoadAd:(ALAd *)ad
{
    [self.parentCustomEvent.bannerView render: ad];
    [super adService: adService didLoadAd: ad];
}

@end
