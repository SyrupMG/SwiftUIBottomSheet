#
# Be sure to run `pod lib lint SwiftUIBottomSheet.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SwiftUIBottomSheet'
  s.version          = '1.0.1'
  s.summary          = 'SwiftUI BottomSheet implementation'

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  ¯\_( ツ )_/¯
  DESC

  s.homepage         = 'https://github.com/SyrupMG/SwiftUIBottomSheet'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'horovodovodo4ka' => 'xbitstream@gmail.com' }
  s.source           = { :git => 'https://github.com/SyrupMG/SwiftUIBottomSheet.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'

  s.source_files = 'SwiftUIBottomSheet/Classes/**/*'

  s.frameworks = 'UIKit', 'SwiftUI'
end
