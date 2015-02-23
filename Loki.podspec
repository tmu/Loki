Pod::Spec.new do |s|
  s.name = 'Loki'
  s.version = '0.1.1'
  s.license = 'MIT'
  s.summary = 'A debug logging library for Swift'
  s.homepage = 'https://github.com/tmu/Loki'
  s.social_media_url = 'https://twitter.com/teemu'
  s.authors = { 'Teemu Kurppa' => 'teemu.kurppa@gmail.com' }
  s.source = { :git => 'https://github.com/tmu/Loki.git', :tag => s.version }

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.10'

  s.source_files = 'Loki/*.swift'
  s.requires_arc = true

  s.xcconfig = { 'OTHER_SWIFT_FLAGS' => '-DLOKI_ON' }
end
