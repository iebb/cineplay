Pod::Spec.new do |s|
  s.name             = 'cineplay_pip'
  s.version          = '0.5.1'
  s.summary          = 'Native Picture-in-Picture sessions for F Video Player.'
  s.description      = <<-DESC
Picture-in-Picture playback handoff and restoration for macOS.
                       DESC
  s.homepage         = 'https://github.com/iebb/cineplay'
  s.license          = { :type => 'BSD-3-Clause', :file => '../LICENSE' }
  s.author           = { 'f-videoplayer contributors' => 'https://github.com/iebb/cineplay' }
  s.source           = { :path => '.' }
  s.source_files     = 'cineplay_pip/Sources/cineplay_pip/**/*'
  s.frameworks       = 'AVFoundation', 'AVKit'
  s.dependency 'FlutterMacOS'
  s.platform         = :osx, '11.0'
  s.swift_version    = '5.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
