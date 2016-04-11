Pod::Spec.new do |s|

  s.name         = "BRWordCounter"
  s.version      = "1.0.0"
  s.summary      = "Live word-counting for NSTextView on OS X and UITextView on iOS."
  s.description  = <<-DESC
                   This project provides a way to count the words in a text view while editing.
                   It is a pod wrapper for the MGWordCounter project, by Matt Gemmell.
                   DESC

  s.homepage     = "https://github.com/Blue-Rocket/BRWordCounter"
  s.license      = "MIT"
  s.author       = { "Matt Magoffin" => "matt@bluerocket.us" }

  s.ios.deployment_target = "6.1"
  s.osx.deployment_target = "10.8"

  s.source       = { :git => "https://github.com/Blue-Rocket/BRWordCounter.git",
  					 :tag => s.version.to_s, :submodules => true }

  s.requires_arc = true

  s.default_subspec = 'Main'

  s.subspec 'Main' do |as|
	  as.source_files = 'BRWordCounter/Packaging/BRWordCounter.h',
	                    'MGWordCounter/MGWordCounterDemo/MGWordCountOperation.{h,m}',
	                    'MGWordCounter/MGWordCounterDemo/MGWordCounter.{h,m}',
	                    'MGWordCounter/MGWordCounterDemo/MGWordCounterDelegate.h'
  end

end
