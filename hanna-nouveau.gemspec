Gem::Specification.new do |s|
  s.name = "hanna-nouveau"
  s.version = File.read(File.expand_path("../VERSION", __FILE__))
  s.authors = ["Jeremy Evans", "Erik Hollensbe", "James Tucker", "Mislav Marohnic"]
  s.email = "code@jeremyevans.net"
  s.extra_rdoc_files = [
    "LICENSE",
    "README.rdoc"
  ]
  s.files = [
    "LICENSE",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "lib/hanna-nouveau.rb",
    "lib/hanna-nouveau/template_files/class_index.erb",
    "lib/hanna-nouveau/template_files/file_index.erb",
    "lib/hanna-nouveau/template_files/index.erb",
    "lib/hanna-nouveau/template_files/layout.erb",
    "lib/hanna-nouveau/template_files/method_index.erb",
    "lib/hanna-nouveau/template_files/method_list.erb",
    "lib/hanna-nouveau/template_files/method_search.js",
    "lib/hanna-nouveau/template_files/page.erb",
    "lib/hanna-nouveau/template_files/sections.erb",
    "lib/hanna-nouveau/template_files/styles.css",
    "lib/rdoc/discover.rb"
  ]
  s.homepage = "https://github.com/jeremyevans/hanna-nouveau"
  s.licenses = ["MIT"]
  s.description = s.summary = "RDoc generator designed with simplicity, beauty and ease of browsing in mind"
  s.metadata          = { 
    'bug_tracker_uri'   => 'https://github.com/jeremyevans/hanna-nouveau/issues',
    'mailing_list_uri'  => 'https://github.com/jeremyevans/hanna-nouveau/discussions',
    "source_code_uri"   => 'https://github.com/jeremyevans/hanna-nouveau'
  }

  s.add_dependency('rdoc', [">= 4"])
end

