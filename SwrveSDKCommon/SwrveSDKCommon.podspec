Pod::Spec.new do |s|
  s.name             = "SwrveSDKCommon"
  s.version          = "4.4.0"
  s.summary          = "iOS Common library for Swrve."
  s.homepage         = "http://www.swrve.com"
  s.license          = { "type" => "Apache License, Version 2.0", "file" => "SwrveSDKCommon/LICENSE" }
  s.authors          = "Swrve Mobile Inc or its licensors"
  s.source           = { :git => "https://github.com/Swrve/swrve-ios-sdk.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/Swrve_Inc'

  s.platform     = :ios, '6.0'
  s.requires_arc = true

  s.source_files = 'SwrveSDKCommon/Common/**/*.{m,h}'
  s.public_header_files = 'SwrveSDKCommon/Common/**/*.h'
  s.compiler_flags = '-DSWRVE_SDK_COMMON'
end
