using_local_pods = ENV['USE_LOCAL_PODS'] == 'true' || false

platform :ios, '11.0'

if using_local_pods
  # Pull pods from sibling directories if using local pods
  target 'ArisenSwiftSoftkeySignatureProvider' do
    use_frameworks!

    pod 'ArisenSwift', :path => '../arisen-swift'
    pod 'ArisenSwiftEcc', :path => '../arisen-swift-ecc'
    pod 'SwiftLint'

    target 'ArisenSwiftSoftkeySignatureProviderTests' do
      inherit! :search_paths
      pod 'ArisenSwift', :path => '../arisen-swift'
      pod 'ArisenSwiftEcc', :path => '../arisen-swift-ecc'
    end
  end
else
  # Pull pods from sources above if not using local pods
  target 'ArisenSwiftSoftkeySignatureProvider' do
    use_frameworks!

    pod 'ArisenSwift', '~> 0.2.1'
    pod 'ArisenSwiftEcc', '~> 0.2.1'
    pod 'SwiftLint'

    target 'ArisenSwiftSoftkeySignatureProviderTests' do
      inherit! :search_paths
      pod 'ArisenSwift', '~> 0.2.1'
      pod 'ArisenSwiftEcc', '~> 0.2.1'
    end
  end
end
