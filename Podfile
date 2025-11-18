source 'https://cdn.cocoapods.org/'

# Uncomment this line to define a global platform for your project
# platform :ios, '9.0'
platform :macos, '11.0'

target 'ShadowsocksX-NG' do
  # Comment this line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for ShadowsocksX-NG
  pod 'Alamofire', '~> 5.4.3'
  pod "GCDWebServer", "~> 3.0"
  pod 'MASShortcut', '~> 2'

  # https://github.com/ReactiveX/RxSwift/blob/master/Documentation/GettingStarted.md
  pod 'RxSwift',    '~> 6.2.0'
  pod 'RxCocoa',    '~> 6.2.0'

  target 'ShadowsocksX-NGTests' do
    inherit! :search_paths
    # Pods for testing
  end

end

target 'proxy_conf_helper' do
  pod 'BRLOptionParser', '~> 0.3.1'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '11.0'
    end
  end

  # Fix TOOLCHAIN_DIR compatibility for Xcode < 15
  frameworks_script_path = 'Pods/Target Support Files/Pods-ShadowsocksX-NG/Pods-ShadowsocksX-NG-frameworks.sh'
  if File.exist?(frameworks_script_path)
    frameworks_script = File.read(frameworks_script_path)
    # Replace TOOLCHAIN_DIR with fallback to DT_TOOLCHAIN_DIR for older Xcode
    frameworks_script.gsub!(
      'SWIFT_STDLIB_PATH="${TOOLCHAIN_DIR}/usr/lib/swift/${PLATFORM_NAME}"',
      'SWIFT_STDLIB_PATH="${TOOLCHAIN_DIR:-$DT_TOOLCHAIN_DIR}/usr/lib/swift/${PLATFORM_NAME}"'
    )
    # Fix readlink -f (GNU extension not available on macOS BSD readlink)
    # Remove -f flag to maintain compatibility with macOS
    frameworks_script.gsub!(
      'source="$(readlink -f "${source}")"',
      'source="$(readlink "${source}")"'
    )
    File.write(frameworks_script_path, frameworks_script)
  end
end
