require "rake/clean"
CLEAN.include ["rdoc", "*.gem"]

require "rdoc/task"
RDoc::Task.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.generator = 'hanna'
  rdoc.title = "hanna-nouveau"
  rdoc.options = ['--main', 'README.rdoc', '--title', 'Hanna-nouveau: RDoc generator designed with simplicity, beauty and ease of browsing in mind']
  rdoc.rdoc_files.add %w"README.rdoc LICENSE lib"
end
