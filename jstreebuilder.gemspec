Gem::Specification.new do |s|
  s.name = 'jstreebuilder'
  s.version = '0.3.2'
  s.summary = 'Generates an HTML tree from XML or Markdown.'
  s.authors = ['James Robertson']
  s.files = Dir['lib/jstreebuilder.rb']
  s.add_runtime_dependency('nokogiri', '~> 1.12', '>=1.12.5')
  s.add_runtime_dependency('polyrex', '~> 1.3', '>=1.3.4')
  s.add_runtime_dependency('polyrex-xslt', '~> 0.2', '>=0.2.2')
  s.add_runtime_dependency('kramdown', '~> 2.3', '>=2.3.1')
  s.signing_key = '../privatekeys/jstreebuilder.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'digital.robertson@gmail.com'
  s.homepage = 'https://github.com/jrobertson/jstreebuilder'
end
