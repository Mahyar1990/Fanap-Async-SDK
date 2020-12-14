
Pod::Spec.new do |s|

  s.name         = "FanapPodAsyncSDK"
  s.version      = "0.9.5.0"
  s.summary      = "Fanap's POD Async Service (DIRANA) - iOS SDK"
  s.description  = "This Package will use to connect the client to the Fanap's async service (DIRANA), and it will live the connection (with socket) to send and recieve messages..."
  s.homepage     = "https://github.com/Mahyar1990/Fanap-Async-SDK"
  s.license      = "MIT"
  s.author       = { "Mahyar" => "mahyar.zhiani@icloud.com" }
  s.platform     = :ios, "10.0"
  s.source       = { :git => "https://github.com/Mahyar1990/Fanap-Async-SDK.git", :tag => s.version }
# s.source_files = "Pod-Async-iOS-SDK/Async/**/*"
  s.source_files = "Pod-Async-iOS-SDK/Async/**/*.{h,swift,m}"
  s.framework  = "Foundation"
  s.dependency "Starscream" , '~> 3.0.5'
  s.dependency "SwiftyJSON"
  s.dependency "SwiftyBeaver"
  s.dependency "Each" , '~> 1.2'
  s.dependency "Sentry" , '~> 4.3.1'

end
