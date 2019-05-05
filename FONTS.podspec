Pod::Spec.new do |spec|
  spec.name         = "FONTS"
  spec.version      = "0.0.1"
  spec.summary      = "Provide Any Font from remote or system"
spec.description  = "Use this library to get custom fonts from remote or system with completion handler "
  spec.homepage     = "https://github.com/rohitRohi123/FONTSMANAGER"
  spec.license      = "MIT"

  spec.author             = { "Rohit" => "rohitadichauhan@gmail.com" }

  spec.platform     = :ios, "10.0"

  spec.source       = { :git => "https://github.com/rohitRohi123/FONTSMANAGER.git", :tag => "1.0.0" }

  spec.source_files  = "FONTS"

  spec.requires_arc = true

  spec.swift_version = "4.2"


end
