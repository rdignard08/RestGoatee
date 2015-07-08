Pod::Spec.new do |s|
  s.name             = "RestGoatee"
  s.version          = '2.4.0'
  s.summary          = "An intuitive JSON & XML deserialization library for ReST based client"
  s.homepage         = "https://github.com/rdignard08/RestGoatee"
  s.license          = 'BSD'
  s.author           = { "Ryan Dignard" => "conceptuallyflawed@gmail.com" }
  s.source           = { :git => "https://github.com/rdignard08/RestGoatee.git", :tag => s.version.to_s }

  s.platform     = :ios, '6.0'
  s.requires_arc = true
  s.source_files = 'RestGoatee'
  s.dependency 'RestGoatee-Core'
  s.dependency 'AFNetworking'
end
