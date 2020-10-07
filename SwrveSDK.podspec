Pod::Spec.new do |s|
  s.name             = "SwrveSDK"
  s.version          = "6.6.2"
  s.summary          = "iOS SDK for Swrve."
  s.homepage         = "http://www.swrve.com"
  s.license          = { "type" => "Apache License, Version 2.0", "file" => s.name.to_s + "/LICENSE" }
  s.authors          = "Swrve Mobile Inc or its licensors"
  s.source           = { :git => "https://github.com/Swrve/swrve-ios-sdk.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/Swrve_Inc'
  s.documentation_url = 'https://docs.swrve.com/developer-documentation/integration/ios/'

  s.platforms    = { :ios => "8.0", :tvos => "9.0" }
  s.requires_arc = true


  s.tvos.user_target_xcconfig = s.tvos.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) SWRVE_NO_PUSH' }

  s.source_files = s.name.to_s + '/SDK/**/*.{m,h}'
  s.public_header_files = s.name.to_s + '/SDK/**/*.h'

  s.dependency 'SwrveSDKCommon', '6.6.2'
  s.dependency 'SwrveConversationSDK', '6.6.2'

  s.frameworks = 'UIKit', 'QuartzCore', 'CFNetwork', 'StoreKit', 'Security', 'AVFoundation', 'CoreText'
  s.ios.frameworks = 'MessageUI', 'CoreTelephony'
  # weak frameworks mark them as optional in xcode allowing for backwards compatibility with iOS7 and iOS8
  s.ios.weak_frameworks = 'UserNotifications'
  s.library = 'sqlite3'
end
