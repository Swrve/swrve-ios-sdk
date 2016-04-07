Pod::Spec.new do |s|
  s.name             = "SwrveSDK"
  s.version          = "4.3.0"
  s.summary          = "iOS SDK for Swrve."
  s.homepage         = "http://www.swrve.com"
  s.license          = { "type" => "Apache License, Version 2.0", "file" => "SwrveSDK/LICENSE" }
  s.authors          = "Swrve Mobile Inc or its licensors"
  s.source           = { :git => "https://github.com/Swrve/swrve-ios-sdk.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/Swrve_Inc'

  s.platform     = :ios, '6.0'
  s.requires_arc = true

  s.source_files = 'SwrveSDK/SDK/**/*.{m,h}'
  s.public_header_files = 'SwrveSDK/SDK/**/*.h'

  s.dependency 'SwrveSDKCommon', '~> 4.3.0'
  s.dependency 'SwrveConversationSDK', '~> 4.3.0'
  
  s.frameworks = 'UIKit', 'QuartzCore', 'CFNetwork', 'StoreKit', 'Security', 'CoreTelephony', 'MessageUI', 'CoreLocation', 'AddressBook', 'AVFoundation', 'AssetsLibrary', 'Contacts', 'Photos'
  s.library = 'sqlite3'
end
