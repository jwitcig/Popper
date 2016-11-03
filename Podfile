# Uncomment this line to define a global platform for your project
# platform :ios, '9.0'

source 'https://github.com/jwitcig/PodSpecs.git'

target 'MessagesExtension' do
  # Comment this line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  pod 'SwiftTools', :git => "https://github.com/jwitcig/SwiftTools"
  pod 'iMessageTools', :path => '~/Documents/projects/iMessageTools'
  pod 'Game', :path => '~/Documents/projects/iOS-Game'

  post_install do |installer|
      installer.pods_project.targets.each do |target|
          target.build_configurations.each do |config|
              config.build_settings['SWIFT_VERSION'] = '3.0'
          end
      end
  end

end

target 'Popper' do
  # Comment this line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Popper

end
