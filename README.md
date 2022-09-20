[![CircleCI](https://circleci.com/gh/Swrve/swrve-ios-sdk/tree/release-8_2_0.svg?style=shield)](https://circleci.com/gh/Swrve/swrve-ios-sdk/tree/release-8_2_0)

What is Swrve
-------------
Swrve is a single integrated platform delivering everything you need to drive mobile engagement and create valuable consumer relationships on mobile.  
This native iOS SDK will enable your app to use all of these features.

Getting started
---------------
Have a look at the quick integration guide at http://docs.swrve.com/developer-documentation/integration/ios/

Installing using CocoaPods
--------------------------
Add the following line to your Podfile
```
pod ‘SwrveSDK’
```
Installing using Carthage (iOS 8+)
--------------------------
You can use [Carthage](https://github.com/Carthage/Carthage) to install `Swrve` by adding it to your `Cartfile`
Note SwrveSDK version > 8.0 depends on SDWebImage. SDWebImage.xcframework is included in the root of our SwrveFramework project.
Use this or add SDWebImage to your cartflie as shown below.

```
github "Swrve/swrve-ios-sdk"
github "SDWebImage" "~> 5.0"
```
Installing using Swift Package Manager (Xcode 12+)
--------------------------
For installing Swift packages, please see the [Apple Developer Docs](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app
Requirements) 

Requirements
------------
### Xcode (latest)
The SDK supports iOS 10+ and the latest version of Xcode (Xcode 10.1, as the time of writing). The SDK will handle older versions of the OS with a dummy SDK.

Sample Projects
-------------------
- The [samples](samples) folder contains several sample projects that include integration instructions and demonstrate best practices.
- Replace the  `-1` and `<API_key>` arguments found in the project's `AppDelegate` file with the AppID with the API Key provided by Swrve.
- Run on your device or on the emulator.

Contributing
------------
We would love to see your contributions! Follow these steps:

1. Fork this repository.
2. Create a branch (`git checkout -b my_awesome_feature`)
3. Commit your changes (`git commit -m "Awesome feature"`)
4. Push to the branch (`git push origin my_awesome_feature`)
5. Open a Pull Request.

License
-------
© Copyright Swrve Mobile Inc or its licensors. Distributed under the [Apache 2.0 License](LICENSE).
