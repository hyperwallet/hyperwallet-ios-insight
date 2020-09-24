Pod::Spec.new do |spec|
    spec.name                  = 'Insights'
    spec.version               = '1.0.0-beta04'
    spec.summary               = 'Insights SDK for iOS Hyperwallet UI SDK to capture the events'
    spec.homepage              = 'https://github.com/hyperwallet/hyperwallet-ios-insight'
    spec.license               = { :type => 'MIT', :file => 'LICENSE' }
    spec.author                = { 'Hyperwallet Systems Inc' => 'devsupport@hyperwallet.com' }
    spec.platform              = :ios
    spec.ios.deployment_target = '10.0'
    spec.source                = { :git => 'https://github.com/hyperwallet/hyperwallet-ios-insight.git', :tag => "#{spec.version}"}
    spec.source_files          = 'Sources/**/*.{swift,h}'
    spec.requires_arc          = true
    spec.swift_version         = '5.0'
    spec.resources             = 'Sources/**/Insights.xcdatamodeld'
end
