Pod::Spec.new do |s|
  s.name             = "SwrveSDKCommon"
  s.version          = "6.6.1"
  s.summary          = "iOS Common library for Swrve."
  s.homepage         = "http://www.swrve.com"
  s.license          = { "type" => "Apache License, Version 2.0", "file" => s.name.to_s + "/LICENSE" }
  s.authors          = "Swrve Mobile Inc or its licensors"
  s.source           = { :git => "https://github.com/Swrve/swrve-ios-sdk.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/Swrve_Inc'
  s.documentation_url = 'https://docs.swrve.com/developer-documentation/integration/ios/'

  s.platforms    = { :ios => "8.0", :tvos => "9.0" }
  s.requires_arc = true

  s.tvos.user_target_xcconfig = s.tvos.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) SWRVE_NO_PUSH' }

  s.source_files = s.name.to_s + '/Common/**/*.{m,h}'
  s.public_header_files = s.name.to_s + '/Common/**/*.h'

  s.compiler_flags = '-DSWRVE_SDK_COMMON'
end
