require "rake/clean"
CLEAN.include ["rdoc", "*.gem", "coverage", "test/rdoc"]

require "rdoc/task"
RDoc::Task.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.generator = 'hanna'
  rdoc.title = "hanna"
  rdoc.options = ['--main', 'README.rdoc', '--title', 'Hanna: RDoc generator designed with simplicity, beauty and ease of browsing in mind']
  rdoc.rdoc_files.add %w"README.rdoc LICENSE CHANGELOG lib"
end

desc "Run tests"
task :test do |p|
  sh %{#{FileUtils::RUBY} #{"-w" if RUBY_VERSION >= '3'} test/test_hanna.rb}
end
task :default=>:test

desc "Run tests with coverage"
task :test_cov do
  ENV['COVERAGE'] = '1'
  sh %{#{FileUtils::RUBY} test/test_hanna.rb}
end
