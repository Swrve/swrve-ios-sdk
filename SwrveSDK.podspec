Pod::Spec.new do |s|
  s.name             = "SwrveSDK"
  s.version          = "8.2.0"
  s.summary          = "iOS SDK for Swrve."
  s.homepage         = "http://www.swrve.com"
  s.license          = { "type" => "Apache License, Version 2.0", "file" => s.name.to_s + "/LICENSE" }
  s.authors          = "Swrve Mobile Inc or its licensors"
  s.source           = { :git => "https://github.com/Swrve/swrve-ios-sdk.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/Swrve_Inc'
  s.documentation_url = 'https://docs.swrve.com/developer-documentation/integration/ios/'

  s.platforms    = { :ios => "9.0", :tvos => "9.0" }
  s.requires_arc = true

  s.source_files = 'SwrveConversationSDK/Conversation/**/*.{m,h}', 'SwrveSDK/SDK/**/*.{m,h}'
  s.public_header_files = 'SwrveConversationSDK/Conversation/**/*.h', 'SwrveSDK/SDK/**/*.h'
  s.resource_bundles = { 'SwrveConversationSDK' => ['SwrveConversationSDK/Resources/**/*.*']}

  s.dependency 'SwrveSDKCommon', '8.2.0'
  s.dependency 'SDWebImage', '~> 5.0'

  s.frameworks = 'UIKit', 'QuartzCore', 'CFNetwork', 'StoreKit', 'Security', 'AVFoundation', 'CoreText'
  s.ios.frameworks = 'MessageUI', 'CoreTelephony'
  # weak frameworks mark them as optional in xcode allowing for backwards compatibility with iOS7 and iOS8
  s.ios.weak_frameworks = 'UserNotifications'
  s.library = 'sqlite3'
end
