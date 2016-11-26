Pod::Spec.new do |s|

  s.name         = "Socket"
  s.version      = "0.1.6"
  s.license      = { :type => "MIT" }

  s.homepage     = "https://github.com/Gagnant/Socket"
  s.author       = "Andrew Visotskiy"
  
  s.summary      = "Asynchronous socket networking library."

  s.description  = "Socket supports TCP. Socket is a TCP/IP socket networking library. It offers asynchronous " \
                   "operation, and a native Cocoa class complete with delegate support. Includes non-blocking " \
                   "send/receive operations, full delegate support, run-loop based, self-contained class, and " \
                   "support for IPv4 and IPv6."

  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.6"

  s.source        = { :git => "https://github.com/Gagnant/Socket.git", :tag => "#{s.version}" }
  s.source_files  = "Socket/*.swift"

  s.frameworks = "Foundation"

end
