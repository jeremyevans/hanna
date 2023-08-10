Gem::Specification.new do |s|
  s.name = "hanna-nouveau"
  s.version = '1.5.0'
  s.authors = ["Jeremy Evans", "Erik Hollensbe", "James Tucker", "Mislav Marohnic"]
  s.email = "code@jeremyevans.net"
  s.files = ['lib/hanna-nouveau.rb', 'lib/rdoc/discover.rb']
  s.homepage = "https://github.com/jeremyevans/hanna"
  s.licenses = ["MIT"]
  s.description = s.summary = "Loads hanna due to gem rename"
  s.required_ruby_version = ">= 2.2"
  s.add_dependency('hanna', [">= 1.5"])
end
