Pod::Spec.new do |s|
  s.name = 'JanusWebGate'
  s.version = '0.1.0'
  s.author = { 'Igor Kh' => 'igor.kh.mail@gmail.com' }
  s.homepage = 'https://github.com/Igor-Khomich/JanusAudioStreamPlayer'
  s.summary = 'Janus streaming API implementation in swift'
  s.platform = :ios
  
  s.source = { 
    :http => 'https://github.com/Igor-Khomich/JanusAudioStreamPlayer/releases/download/0.1/JanusWebGate.framework.zip'
  }
  s.ios.deployment_target = '10.0'
  s.vendored_frameworks = 'JanusWebGate.framework'
end