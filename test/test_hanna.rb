if ENV.delete('COVERAGE')
  require 'simplecov'

  SimpleCov.start do
    enable_coverage :branch
    add_filter "/test/"
    add_group('Missing'){|src| src.covered_percent < 100}
    add_group('Covered'){|src| src.covered_percent == 100}
  end
end

ENV['MT_NO_PLUGINS'] = '1' # Work around stupid autoloading of plugins
require 'minitest/hooks/default'
require 'minitest/global_expectations/autorun'

$: << File.join(File.dirname(__FILE__), '..', 'lib')

require 'rdoc/rdoc'
require 'fileutils'
require 'find'

describe 'hanna-nouveau' do
  before(:all) do
    Dir.chdir("test") do
      RDoc::RDoc.new.document(%w'-q -O -f hanna -o rdoc lib')
    end
  end
  after(:all) do
    FileUtils.rm_r('test/rdoc')
  end

  it "should generate files expected" do
    files = []
    Find.find('test/rdoc') do |f|
      files << f
    end

    files.sort!
    files.join("\n").must_equal(<<END.chomp)
test/rdoc
test/rdoc/classes
test/rdoc/classes/A
test/rdoc/classes/A.html
test/rdoc/classes/A/B.html
test/rdoc/classes/A/F.html
test/rdoc/classes/A/G
test/rdoc/classes/A/G.html
test/rdoc/classes/A/G/H.html
test/rdoc/created.rid
test/rdoc/css
test/rdoc/css/style.css
test/rdoc/files
test/rdoc/files/lib
test/rdoc/files/lib/a_rb.html
test/rdoc/fr_class_index.html
test/rdoc/fr_file_index.html
test/rdoc/fr_method_index.html
test/rdoc/index.html
test/rdoc/method_search.js
END
  end

  it "should set target to _top for both http and http links" do
    t = File.binread('test/rdoc/classes/A.html')
    t.must_include 'target="_top" href="http://github.com/jeremyevans/hanna-nouveau">github.com/jeremyevans/hanna-nouveau</a></p>'
    t.must_include 'target="_top" href="https://github.com/jeremyevans/hanna-nouveau">github.com/jeremyevans/hanna-nouveau</a></p>'
  end

  it "should use tables for labeled lists" do
    t = File.binread('test/rdoc/classes/A.html')
    t.must_include(<<END)
<table class="rdoc-list note-list"><tbody><tr><td class='label'>label-lists </td><td>
<p>Now use tables</p>
</td></tr></tbody></table>
END
  end

  it "should use details/summary for class list" do
    t = File.binread('test/rdoc/fr_class_index.html')
    t.scan(/(<\/?(?:details(?: open)?|summary)>|<a .*<\/a>)/).join("\n").must_equal(<<END.chomp)
<details open>
<summary>
<a href="classes/A.html">A</a>
</summary>
<a href="classes/A/B.html"><span class="parent">A::</span>B</a>
<a href="classes/A/F.html"><span class="parent">A::</span>F</a>
<details>
<summary>
<a href="classes/A/G.html"><span class="parent">A::</span>G</a>
</summary>
<a href="classes/A/G/H.html"><span class="parent">A::G::</span>H</a>
</details>
</details>
END
  end
end
