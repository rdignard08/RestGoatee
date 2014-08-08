Pod::Spec.new do |s|
  s.name             = "RestGoatee"
  s.version          = '1.1.0'
  s.summary          = "An Easier dependency-free way to handle ReST objects."
  s.homepage         = "https://github.com/rdignard08/RestGoatee"
  s.license          = 'BSD'
  s.author           = { "Ryan Dignard" => "dignard@1debit.com" }
  s.source           = { :git => "https://github.com/rdignard08/RestGoatee.git", :tag => s.version.to_s }

  s.platform     = :ios, '7.0'
  s.requires_arc = true
  s.source_files = 'RestGoatee'
  s.dependency 'AFNetworking'
end
