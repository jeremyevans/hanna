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
    "lib/hanna-nouveau/template_files/class_index.haml",
    "lib/hanna-nouveau/template_files/file_index.haml",
    "lib/hanna-nouveau/template_files/index.haml",
    "lib/hanna-nouveau/template_files/layout.haml",
    "lib/hanna-nouveau/template_files/method_index.haml",
    "lib/hanna-nouveau/template_files/method_list.haml",
    "lib/hanna-nouveau/template_files/method_search.js",
    "lib/hanna-nouveau/template_files/page.haml",
    "lib/hanna-nouveau/template_files/prototype-1.6.0.3.js",
    "lib/hanna-nouveau/template_files/sections.haml",
    "lib/hanna-nouveau/template_files/styles.sass",
    "lib/rdoc/discover.rb"
  ]
  s.homepage = "https://github.com/jeremyevans/hanna-nouveau"
  s.licenses = ["MIT"]
  s.summary = "RDoc generator designed with simplicity, beauty and ease of browsing in mind"
  s.description = <<END
RDoc generator designed with simplicity, beauty and ease of browsing in mind

Based on the original Hanna by Mislav, with many changes so it works
on modern verions of RDoc, Haml, and Sass.
END

  s.add_dependency('haml', [">= 4"])
  s.add_dependency('sass')
  s.add_dependency('rdoc', [">= 4"])
end

