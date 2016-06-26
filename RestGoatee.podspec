Pod::Spec.new do |s|
  s.name             = "RestGoatee"
  s.version          = '2.7.0'
  s.summary          = "An intuitive JSON & XML deserialization library for ReST based clients"
  s.homepage         = "https://github.com/rdignard08/RestGoatee"
  s.license          = 'BSD'
  s.authors          = { "Ryan Dignard" => "conceptuallyflawed@gmail.com" }
  s.source           = { :git => "https://github.com/rdignard08/RestGoatee.git", :tag => s.version }

  s.requires_arc = true

  s.ios.deployment_target = '7.0'
  s.osx.deployment_target = '10.9'
  s.watchos.deployment_target = '2.0'
  s.tvos.deployment_target = '9.0'

  s.source_files = 'RestGoatee'
  s.dependency 'RestGoatee-Core', '~> 2.2'
  s.dependency 'AFNetworking', '~> 3.0'
end
