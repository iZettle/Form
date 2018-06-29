Pod::Spec.new do |s|
  s.name         = "FormFramework"
  s.version      = "1.1.0"
  s.module_name  = "Form"
  s.summary      = "Powerful iOS layout and styling"
  s.description  = <<-DESC
                   Form is an iOS Swift library for working efficiently with layout and styling.
                   DESC
  s.homepage     = "https://github.com/iZettle/Form"
  s.license      = { :type => "MIT", :file => "LICENSE.md" }
  s.author       = { 'iZettle AB' => 'hello@izettle.com' }

  s.ios.deployment_target = "9.0"
  s.dependency 'FlowFramework', '~> 1.1'
  
  s.source       = { :git => "https://github.com/iZettle/Form.git", :tag => "#{s.version}" }
  s.source_files = "Form/*.{swift}"
  s.swift_version = '4.1'
end
