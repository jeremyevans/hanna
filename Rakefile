require "rake/clean"
CLEAN.include ["rdoc", "*.gem", "coverage", "test/rdoc"]

desc "Generate rdoc"
task :rdoc do
  rdoc_dir = "rdoc"
  rdoc_opts = ["--line-numbers", "--inline-source", '--title', 'Hanna: RDoc generator designed with simplicity, beauty and ease of browsing in mind', '-f', 'hanna']

  rdoc_opts.concat(['--main', 'README.rdoc', "-o", rdoc_dir] +
    %w"README.rdoc CHANGELOG LICENSE" +
    Dir["lib/**/*.rb"]
  )

  FileUtils.rm_rf(rdoc_dir)

  require "rdoc"
  RDoc::RDoc.new.document(rdoc_opts)
end

desc "Run tests"
task :test do |p|
  sh %{#{FileUtils::RUBY} #{"-w" if RUBY_VERSION >= '3'} #{'-W:strict_unused_block' if RUBY_VERSION >= '3.4'} test/test_hanna.rb}
end
task :default=>:test

desc "Run tests with coverage"
task :test_cov do
  ENV['COVERAGE'] = '1'
  sh %{#{FileUtils::RUBY} test/test_hanna.rb}
end
