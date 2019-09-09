Pod::Spec.new do |s|
  s.name         = "FormFramework"
  s.version      = "1.10.5"
  s.module_name  = "Form"
  s.summary      = "Powerful iOS layout and styling"
  s.description  = <<-DESC
                   Form is an iOS Swift library for working efficiently with layout and styling.
                   DESC
  s.homepage     = "https://github.com/iZettle/Form"
  s.license      = { :type => "MIT", :file => "LICENSE.md" }
  s.author       = { 'iZettle AB' => 'hello@izettle.com' }

  s.ios.deployment_target = "9.0"
  s.dependency 'FlowFramework', '~> 1.8.2'
  s.default_subspec = 'Form'

  s.subspec 'Form' do |form|
  # empty subspec for users who don't want to have additional dependency on PresentationFramework
  # we decided to make it the default one since we consider PresentationFramework more of a nice addition than part of Form's functionality
  end

  s.subspec 'Presentation' do |presentation|
    presentation.dependency 'PresentationFramework', '~> 1.1'
  end

  s.source       = { :git => "https://github.com/iZettle/Form.git", :tag => "#{s.version}" }
  s.source_files = "Form/*.{swift,m,h}"
  s.public_header_files = "Form/*.{h}"
  s.swift_version = '5.0'
end
