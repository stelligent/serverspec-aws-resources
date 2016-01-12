Gem::Specification.new do |s|
  s.name        = 'serverspec-aws-resources'
  s.version     = '0.0.7'
  s.date        = '2016-01-12'
  s.summary     = 'serverspec resource types to test AWS resources'
  s.description = s.summary
  s.authors     = %w{Eric Kascic}
  s.email       = 'eric.kascic@stelligent.com'
  s.files       =  Dir['lib/*.rb'] + Dir['lib/resources/*.rb']

  s.add_runtime_dependency 'aws-sdk-v1', '>= 1.66.0'
end
