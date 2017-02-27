Swrve SDK Change User ID Sample
-------------------------------
Example of how to implement [SwrveIdentityUtils](ChangeUserID/SwrveIdentityUtils.m) class which allows you to change user id after the Swrve SDK is initialized

How to run the demo in XCode
----------------------------
- Open the project located under ChangeUserID/ChangeUserID.xcodproj
- Replace YOUR_APP_ID in AppDelegate.m with your Swrve app ID.
- Replace YOUR_API_KEY in AppDelegate.m with your Swrve API key.
- Run ChangeUserID app normally.

Overview
--------
Swrve is designed to track the behavior and personalize the experience for users on a specific device.  This works great for apps that are device centric.  However, sometimes you want to track and personalize a user's experience across multiple devices or have multiple users on one device.  
If your app uses a user centric model, you will need to do the following;
Implement a method to change user id. 
This method will:
- Destroy the current Swrve Instance 
- Create a new one with the correct user_id
Use this method when the user 
-- logs into the app
OR
-- logs in as a different user.
-When you don’t know the user_id, (e.g. first session) initialize Swrve with an empty SDK. -Use the change user id method when the user_id is known.

**Note:** This feature is not supported by the Swrve SDKs out of the box, it is possible by implementing the SwrveIdentityUtils class as shown in this sample project.

Prerequisites
-------------
The requirements of the implementation are as follows:
  * Using the 4.7.1+ iOS SDK
  * Have an identifier that is unique for the lifetime of a user
  * Ability to log out of a user and log back in within the same app session
  * Objective-C codebase with ARC enabled
  * Not using Swrve’s method swizzling. Follow instructions of the [“Disabling Push Notification Method Swizzling”](https://docs.swrve.com/developer-documentation/integration/ios/#Push_Notifications) section of our docs


Swrve Initialization Flow
-------------------------
1. First Session: Initialize Swrve with an empty SDK using which won’t send any events to Swrve.

2. When the user logs into the app for the first time: 
   * Destroy the previous Swrve instance
   * Initialize Swrve using the custom_user_id

3. Subsequent Sessions: 
   * On App launch: Initialize Swrve with the custom_id of the last logged in user.
   * If the user logs in with the same user_id:
     * Do nothing - The Swrve instance is initialized with the correct user_id
   * If the user logs in with a different user_id
     * Destroy the previous Swrve instance
     * Reinitialize Swrve using custom_id as the user_id

4. User logs out and logs in as a different user mid session:
   * Don’t change user id until the user logs in as a different user as it is more than likely the same user.
   * Once the user logs in as a different user 
     * Destroy the previous Swrve instance
     * Reinitialize Swrve using custom_id as the user_id

Caveats
-------
1. This method of changing user_id is not fully supported by the SDK.
2. Swrve Event Tracking, In-App Messageing or A/B testing should not be used until the user has logged into the app with thier custom ID.
3. Swrve Push Notifications cannot be sent out until the user has logged in at least once, even if the user has agreed to push beforehand. 