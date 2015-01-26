Gem::Specification.new do |s|
  s.name        = 'serverspec-aws-resources'
  s.version     = '0.0.0'
  s.date        = '2015-01-26'
  s.summary     = 'serverspec resource types to test AWS resources'
  s.description = s.summary
  s.authors     = %w{Eric Kascic}
  s.email       = 'eric.kascic@stelligent.com'
  s.files       =  Dir['lib/*.rb'] + Dir['lib/resources/*.rb']
end
