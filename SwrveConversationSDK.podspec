Pod::Spec.new do |s|
  s.name             = "SwrveConversationSDK"
  s.version          = "5.2.2"
  s.summary          = "iOS Conversation SDK for Swrve."
  s.homepage         = "http://www.swrve.com"
  s.license          = { "type" => "Apache License, Version 2.0", "file" => s.name.to_s + "/LICENSE" }
  s.authors          = "Swrve Mobile Inc or its licensors"
  s.source           = { :git => "https://github.com/Swrve/swrve-ios-sdk.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/Swrve_Inc'

  s.platforms    = { :ios => "6.0", :tvos => "9.0" }
  s.requires_arc = true

  s.tvos.user_target_xcconfig = s.tvos.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) SWRVE_NO_PUSH' }

  s.tvos.exclude_files = '**/*Conversation.storyboard'
  s.ios.exclude_files = '**/*Conversation-tvos.storyboard'

  s.source_files = s.name.to_s + '/Conversation/**/*.{m,h}'
  s.public_header_files = s.name.to_s + '/Conversation/**/*.h'
  s.resources = s.name.to_s + '/Resources/**/*.*'

  s.dependency 'SwrveSDKCommon', '5.2.2'

  s.compiler_flags = '-DSWRVE_CONVERSATION_SDK'
end
