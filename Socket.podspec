Pod::Spec.new do |s|
  
  s.name                  = 'Socket'
  s.version               = '1.0.0'
  s.summary               = 'iOS Socket framework for usage with JSTP'
  s.description           = 'TCP Socket, JSTP'
  s.homepage              = 'https://github.com/Gagnant/Socket'
  s.license               = 'MIT'
  s.authors               = 'Gagnant', 'metarhia'
  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.10'
  s.source                = { :git => 'https://github.com/Gagnant/Socket.git', :tag => s.version.to_s }
  s.source_files          = 'Socket/*.{h, swift}'

end
