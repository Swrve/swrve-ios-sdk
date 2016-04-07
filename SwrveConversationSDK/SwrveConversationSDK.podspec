Pod::Spec.new do |s|
  s.name             = "SwrveConversationSDK"
  s.version          = "4.3.0"
  s.summary          = "iOS Conversation SDK for Swrve."
  s.homepage         = "http://www.swrve.com"
  s.license          = { "type" => "Apache License, Version 2.0", "file" => "SwrveConversationSDK/LICENSE" }
  s.authors          = "Swrve Mobile Inc or its licensors"
  s.source           = { :git => "https://github.com/Swrve/swrve-ios-sdk.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/Swrve_Inc'

  s.platform     = :ios, '6.0'
  s.requires_arc = true

  s.source_files = 'SwrveConversationSDK/Conversation/**/*.{m,h}'
  s.public_header_files = 'SwrveConversationSDK/Conversation/**/*.h'
  s.resources = 'SwrveConversationSDK/Resources/**/*.*'
  
  s.dependency 'SwrveSDKCommon', '~> 4.3.0'
end
