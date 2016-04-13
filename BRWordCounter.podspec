Pod::Spec.new do |s|

  s.name         = "BRWordCounter"
  s.version      = "2.0.1"
  s.summary      = "Live word-counting for NSTextView on OS X and UITextView on iOS."
  s.description  = <<-DESC
                   This project provides a way to efficiently count the words in a text view while editing.
                   DESC

  s.homepage     = "https://github.com/Blue-Rocket/BRWordCounter"
  s.license      = "MIT"
  s.author       = { "Matt Magoffin" => "matt@bluerocket.us" }

  s.ios.deployment_target = "7.1"

  s.source       = { :git => "https://github.com/Blue-Rocket/BRWordCounter.git", :tag => s.version.to_s }

  s.requires_arc = true

  s.default_subspec = 'Main'

  s.subspec 'Main' do |as|
	  as.source_files = 'BRWordCounter/Packaging/BRWordCounter.h',
	                    'BRWordCounter/BRWordCounter/BRWordCountDelegate.h',
	                    'BRWordCounter/BRWordCounter/BRWordCountHelper.{h,m}'
  end

end
