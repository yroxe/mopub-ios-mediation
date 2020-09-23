## Changelog
* 6.8.0.0
    * This version of the adapters has been certified with Vungle 6.8.0 and MoPub SDK 5.13.1.
    * Note that, while Vungle 6.8.0 supports iOS 14, this adapter version is not certified using iOS 14. For iOS 14 compatibility, expect an upcoming adapter release.

* 6.7.1.0
    * This version of the adapters has been certified with Vungle 6.7.1 and MoPub SDK 5.13.1.
    * Fix a Rewarded Video duplicated callbacks issue.

* 6.7.0.1
    * Fix adapter compiler warnings.

* 6.7.0.0
    * This version of the adapters has been certified with Vungle 6.7.0 and MoPub SDK 5.13.0.
    * Add support for Advanced Bidding for fullscreen ads.
    * Add support for playing multiple banner ads at the same time.
    * Add support for new Vungle SDK event `vungleAdTrackClick`.
    * Add support for new Vungle SDK init API.

* 6.5.3.2
    * Refactor non-native adapter classes to use the new consolidated API from MoPub.
    * This and newer adapter versions are only compatible with 5.13.0+ MoPub SDK.

* 6.5.3.1
   * Fix `scheduledTimerWithTimeInterval` called for iOS 9.

* 6.5.3.0
   * This version of the adapters has been certified with Vungle 6.5.3 and MoPub SDK 5.11.0.

* 6.5.2.0
   * This version of the adapters has been certified with Vungle 6.5.2.
   * Add support for Vungle's newly-introduced banner format.

  * 6.4.6.1
    * Remove duplicate `rewardedVideoDidAppearForCustomEvent` callback.
    * Adapter logging cleanup.

  * 6.4.6.0
    * This version of the adapters has been certified with Vungle 6.4.6.
    
  * 6.4.5.1
    * Pass mute and ad orientations settings for interstitial ad.
    * Remove passing user ID setting for interstitial ad.

  * 6.4.5.0
    * This version of adapters has been certified with Vungle 6.4.5 and is compatible with iOS 13.
    * Stop implementing deprecated request API.
    * Prioritize reading data from `localExtras` for rewarded video.
    * Add support for the newly-introduced Vungle's Medium Rectangle format demand.

  * 6.3.2.6
    * Allow supported mediated networks and publishers to opt-in to process a user’s personal data based on legitimate interest basis. More details [here](https://developers.mopub.com/docs/publisher/gdpr-guide/#legitimate-interest-support).

  * 6.3.2.5
    * Rename `MPVungleRouter` to `VungleRouter` for consistency with other adapter class names. 

  * 6.3.2.4
    * Adapters now fetch only the core MoPub iOS SDK (excluding viewability SDKs). Publishers wishing to integrate viewability should fetch the `mopub-ios-sdk` dependency in their own Podfile.

  * 6.3.2.3
    * Update adapter version in VungleAdapterConfiguration to accommodate podspec changes for Unity releases.
    
  * 6.3.2.2
    * Move source_files to the `Network` subspec.

  * 6.3.2.1
    * **Note**: This version is only compatible with the 5.5.0+ release of the MoPub SDK.
    * Add the `VungleAdapterConfiguration` class to: 
         * pre-initialize the Vungle SDK during MoPub SDK initialization process
         * store adapter and SDK versions for logging purpose
    * Streamline adapter logs via `MPLogAdEvent` to make debugging more efficient. For more details, check the [iOS Initialization guide](https://developers.mopub.com/docs/ios/initialization/) and [Writing Custom Events guide](https://developers.mopub.com/docs/ios/custom-events/).

  * 6.3.2.0
    * This version of the adapters has been certified with Vungle 6.3.2.

  * 6.2.0.2
    * Clean up remaining code pertaining to Vungle's placement IDs (`pids`) since it's no longer needed to initialize Vungle.

  * 6.2.0.1  
    * Update adapters to remove dependency on MPInstanceProvider
    * Update adapters to be compatible with MoPub iOS SDK framework

  * 6.2.0.0
    * This version of the adapters has been certified with Vungle 6.2.0.
    * General Data Protection Regulation (GDPR) update to support a way for publishers to determine GDPR applicability and to obtain/manage consent from users in European Economic Area, the United Kingdom, or Switzerland to serve personalize ads. Only applicable when integrated with MoPub version 5.0.0 and above

  * 5.4.0.1
    * This version of the adapters has been certified with Vungle 5.4.0.
    * Podspec version bumped in order to pin the network SDK version.

  * 5.4.0.0
    * This version of the adapters has been certified with Vungle 5.4.0.
    
  * 5.3.2.0
    * This version of the adapters has been certified with Vungle 5.3.2.

  * Initial Commit
  	* Adapters moved from [mopub-ios-sdk](https://github.com/mopub/mopub-ios-sdk) to [mopub-ios-mediation](https://github.com/mopub/mopub-ios-mediation/)
