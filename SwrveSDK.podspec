Pod::Spec.new do |s|
  s.name             = "SwrveSDK"
  s.version          = "4.5.2"
  s.summary          = "iOS SDK for Swrve."
  s.homepage         = "http://www.swrve.com"
  s.license          = { "type" => "Apache License, Version 2.0", "file" => s.name.to_s + "/LICENSE" }
  s.authors          = "Swrve Mobile Inc or its licensors"
  s.source           = { :git => "https://github.com/Swrve/swrve-ios-sdk.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/Swrve_Inc'

  s.platform     = :ios, '6.0'
  s.requires_arc = true

  s.source_files = s.name.to_s + '/SDK/**/*.{m,h}'
  s.public_header_files = s.name.to_s + '/SDK/**/*.h'

  s.dependency 'SwrveSDKCommon', '4.5.2'
  s.dependency 'SwrveConversationSDK', '4.5.2'

  s.frameworks = 'UIKit', 'QuartzCore', 'CFNetwork', 'StoreKit', 'Security', 'CoreTelephony', 'MessageUI', 'CoreLocation', 'AddressBook', 'AVFoundation', 'AssetsLibrary', 'Photos'
  s.weak_frameworks = 'Contacts'
  s.library = 'sqlite3'
end
