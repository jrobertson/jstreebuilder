Gem::Specification.new do |s|
  s.name = 'jstreebuilder'
  s.version = '0.1.0'
  s.summary = 'Generates an HTML tree from XML.'
  s.authors = ['James Robertson']
  s.files = Dir['lib/jstreebuilder.rb']
  s.add_runtime_dependency('nokogiri', '~> 1.10', '>=1.10.3')  
  s.add_runtime_dependency('polyrex', '~> 1.3', '>=1.3.0')
  s.add_runtime_dependency('polyrex-xslt', '~> 0.2', '>=0.2.0')
  s.signing_key = '../privatekeys/jstreebuilder.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@jamesrobertson.eu'
  s.homepage = 'https://github.com/jrobertson/jstreebuilder'
end
