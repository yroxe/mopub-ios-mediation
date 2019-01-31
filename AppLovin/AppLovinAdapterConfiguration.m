#import "AppLovinAdapterConfiguration.h"

#if __has_include(<AppLovinSDK/AppLovinSDK.h>)
    #import <AppLovinSDK/AppLovinSDK.h>
#else
    #import "ALSdk.h"
#endif

#if __has_include("MoPub.h")
#import "MPLogging.h"
#endif

// Constants
static NSString * const kAppLovinSdkInfoPlistKey   = @"AppLovinSdkKey";

// Errors
static NSString * const kAdapterErrorDomain = @"com.mopub.mopub-ios-sdk.mopub-applovin-adapters";

typedef NS_ENUM(NSInteger, AppLovinAdapterErrorCode) {
    AppLovinAdapterErrorCodeMissingSdkKeyInPlist,
};

@implementation AppLovinAdapterConfiguration

/**
 Retrieves a shared instance of the AppLovin SDK.
 */
+ (ALSdk *)appLovinSdk {
    ALSdk * sharedSdk = nil;
    
    // Check if the SDK key is present in info.plist. If it's not present, do not attempt
    // to fetch the token since this will cause the app to crash!
    if ([[NSBundle mainBundle] objectForInfoDictionaryKey:kAppLovinSdkInfoPlistKey] != nil) {
        sharedSdk = [ALSdk shared];
    }
    // Error
    else {
        MPLogInfo(@"Could not find `AppLovinSdkKey` in Info.plist or a cached AppLovin SDK key.");
    }
    
    return sharedSdk;
}

#pragma mark - Test Mode

+ (BOOL)isTestMode {
    return [AppLovinAdapterConfiguration appLovinSdk].settings.isTestAdsEnabled;
}

+ (void)setIsTestMode:(BOOL)isTestMode {
    [AppLovinAdapterConfiguration appLovinSdk].settings.isTestAdsEnabled = isTestMode;
}

#pragma mark - MPAdapterConfiguration

- (NSString *)adapterVersion {
    return @"6.1.4.2";
}

- (NSString *)biddingToken {
    return [AppLovinAdapterConfiguration appLovinSdk].adService.bidToken;
}

- (NSString *)moPubNetworkName {
    return @"applovin_sdk";
}

- (NSString *)networkSdkVersion {
    return ALSdk.version;
}

- (void)initializeNetworkWithConfiguration:(NSDictionary<NSString *, id> *)configuration
                                  complete:(void(^)(NSError *))complete {
    // Attempt to retrieve an AppLovin SDK instance
    ALSdk * appLovinSdk = [AppLovinAdapterConfiguration appLovinSdk];
    
    // Initialize the AppLovin SDK to start preloading ads in the background.
    NSError * error = nil;
    if (appLovinSdk != nil) {
        [appLovinSdk initializeSdk];
    }
    // Could not retrieve an AppLovin SDK instance
    else {
        error = [NSError errorWithDomain:kAdapterErrorDomain code:AppLovinAdapterErrorCodeMissingSdkKeyInPlist userInfo:@{ NSLocalizedDescriptionKey: @"Could not find 'AppLovinSdkKey' in Info.plist" }];
    }
    
    if (complete != nil) {
        complete(error);
    }
}

@end
