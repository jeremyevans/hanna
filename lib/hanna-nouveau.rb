# frozen-string-literal: true

# = A better RDoc HTML template

require 'pathname'
require 'erb'
# :nocov:
require 'rdoc/rdoc' unless defined?(RDoc::Markup::ToHtml)
# :nocov:
require 'rdoc/generator'

# Hanna version of RDoc::Generator
class RDoc::Generator::Hanna 
  STYLE            = 'styles.css'
  LAYOUT           = 'layout.erb'

  INDEX_PAGE       = 'index.erb'
  CLASS_PAGE       = 'page.erb'
  METHOD_LIST_PAGE = 'method_list.erb'
  FILE_PAGE        = CLASS_PAGE
  SECTIONS_PAGE    = 'sections.erb'

  FILE_INDEX       = 'file_index.erb'
  CLASS_INDEX      = 'class_index.erb'
  METHOD_INDEX     = 'method_index.erb'

  CLASS_DIR        = 'classes'
  FILE_DIR         = 'files'

  INDEX_OUT        = 'index.html'
  FILE_INDEX_OUT   = 'fr_file_index.html'
  CLASS_INDEX_OUT  = 'fr_class_index.html'
  METHOD_INDEX_OUT = 'fr_method_index.html'
  STYLE_OUT        = File.join('css', 'style.css')

  METHOD_SEARCH_JS = "method_search.js"

  DESCRIPTION = 'RDoc generator designed with simplicity, beauty and ease of browsing in mind'

  RDoc::RDoc.add_generator( self )

  class << self
    alias for new
  end

  def initialize( store, options )
    @options = options
    @store = store

    @templatedir = Pathname.new File.expand_path('../hanna-nouveau/template_files', __FILE__)

    @files      = nil
    @classes    = nil
    @methods    = nil
    @attributes = nil

    @basedir = Pathname.pwd.expand_path
  end

  def generate
    @outputdir = Pathname.new( @options.op_dir ).expand_path( @basedir )

    @files      = @store.all_files.sort
    @classes    = @store.all_classes_and_modules.sort
    @methods    = @classes.map {|m| m.method_list }.flatten.sort
    @attributes = @classes.map(&:attributes).flatten.sort

    # Now actually write the output
    write_static_files
    generate_indexes
    generate_class_files
    generate_file_files
  end

  def write_static_files
    css_dir = outjoin('css')
    FileUtils.mkdir_p css_dir
    File.binwrite(File.join(css_dir, 'style.css'), File.read(templjoin(STYLE)))
  end

  def generate_indexes
    @main_page_uri = @files.find { |f| f.name == @options.main_page }.path rescue ''
    File.binwrite(outjoin(INDEX_OUT), erb_template(templjoin(INDEX_PAGE)).to_html(binding))

    generate_index(FILE_INDEX_OUT,   FILE_INDEX,   'File',   { :files => @files})
    generate_index(CLASS_INDEX_OUT,  CLASS_INDEX,  'Class',  { :classes => @classes })
    generate_index(METHOD_INDEX_OUT, METHOD_INDEX, 'Method', { :methods => @methods, :attributes => @attributes })

    File.binwrite(outjoin(METHOD_SEARCH_JS), File.binread(templjoin(METHOD_SEARCH_JS)))
  end

  def generate_index(outfile, templfile, index_name, values)
    values.merge!({
      :stylesheet => STYLE_OUT,
      :list_title => "#{index_name} Index"
    })

    index = erb_template(templjoin(templfile))

    File.binwrite(outjoin(outfile), with_layout(values){index.to_html(binding, values)})
  end

  def generate_file_files
    file_page = erb_template(templjoin(FILE_PAGE))
    method_list_page = erb_template(templjoin(METHOD_LIST_PAGE))

    @files.each do |file|
      path = Pathname.new(file.path)
      stylesheet = Pathname.new(STYLE_OUT).relative_path_from(path.dirname)
      
      values = { 
        :file => file, 
        :entry => file,
        :stylesheet => stylesheet,
        :classmod => nil, 
        :title => file.base_name, 
        :list_title => nil,
        :description => file.description
      } 

      result = with_layout(values) do 
        file_page.to_html(binding, :values => values) do 
          method_list_page.to_html(binding, values) 
        end
      end

      dir = path.dirname
      FileUtils.mkdir_p dir
      File.binwrite(outjoin(file.path), result)
    end
  end

  def generate_class_files
    class_page       = erb_template(templjoin(CLASS_PAGE))
    method_list_page = erb_template(templjoin(METHOD_LIST_PAGE))
    sections_page    = erb_template(templjoin(SECTIONS_PAGE))

    @classes.each do |klass|
      outfile = classfile(klass)
      stylesheet = Pathname.new(STYLE_OUT).relative_path_from(outfile.dirname)
      sections = {}
      klass.each_section do |section, constants, attributes|
        method_types = []
        alias_types = []
        klass.methods_by_type(section).each do |type, visibilities|
          visibilities.each do |visibility, methods|
            aliases, methods = methods.partition{|x| x.is_alias_for}
            method_types << ["#{visibility.to_s.capitalize} #{type.to_s.capitalize}", methods.sort] unless methods.empty?
            alias_types << ["#{visibility.to_s.capitalize} #{type.to_s.capitalize}", aliases.sort] unless aliases.empty?
          end
        end
        sections[section] = {:constants=>constants, :attributes=>attributes, :method_types=>method_types, :alias_types=>alias_types}
      end

      values = { 
        :file => klass.path, 
        :entry => klass,
        :stylesheet => stylesheet,
        :classmod => klass.type,
        :title => klass.full_name,
        :list_title => nil,
        :description => klass.description,
        :sections => sections
      } 

      result = with_layout(values) do 
        h = {:values => values}
        class_page.to_html(binding, h) do 
          method_list_page.to_html(binding, h) + sections_page.to_html(binding, h)
        end
      end

      dir = outfile.dirname
      FileUtils.mkdir_p dir
      File.binwrite(outfile, result)
    end
  end

  def with_layout(values)
    layout = erb_template(templjoin(LAYOUT))
    layout.to_html(binding, :values => values) { yield }
  end

  def frame_link(content)
    content.gsub(%r!<a[ \n]href="https?://[^>]*>!).each do |tag|
      a_tag, rest = tag.split(' ', 2)
      rest.gsub!(/target="[^"]*"/, '')
      a_tag + ' target="_top" ' + rest
    end
  end

  def class_dir
    CLASS_DIR
  end

  def file_dir
    FILE_DIR
  end

  def h(html)
    CGI::escapeHTML(html.to_s)
  end

  def render_class_tree(entries, parent=nil)
    namespaces = { }
    out = String.new

    entries.sort.each do |klass|
      next if namespaces[klass.full_name]

      text = if parent
        "<span class=\"parent\">#{parent.full_name}::</span>#{klass.name}"
      else
        klass.name
      end

      prefix = "#{klass.full_name}::"
      subentries = @classes.select{|c| c.full_name.start_with?(prefix)}
      subentries.each { |x| namespaces[x.full_name] = true }

      out << '<li>' << link_to(text, classfile(klass)) << "\n<ol>" << render_class_tree(subentries, klass) << "\n</ol></li>"
    end

    out
  end
    
  def link_to(text, url)
    %[<a href="#{url}">#{text}</a>]
  end

  def link_to_method(entry, url)
    method_name = entry.pretty_name rescue entry.name
    module_name = entry.parent_name rescue entry.name
    link_to %Q(<span class="method_name" value="#{entry.name}">#{h method_name}</span> <span class="module_name">(#{h module_name})</span>), url
  end

  def classfile(klass)
    Pathname.new(File.join(CLASS_DIR, klass.full_name.split('::')) + '.html')
  end

  def outjoin(name)
    File.join(@outputdir, name)
  end

  def templjoin(name)
    File.join(@templatedir, name)
  end

  class ERB < ::ERB
    def to_html(binding, values = nil, &block)
      local_values = {}
      binding.local_variables.each do |lv|
        local_values[lv] = binding.local_variable_get(lv)
      end
      binding.local_variable_set(:values, values) if values
      binding.local_variable_set(:block, block) if block
      html = result(binding)
      local_values.each do |lv, val|
        binding.local_variable_set(lv, val)
      end
      html
    end
  end

  def erb_template(file)
    ERB.new(File.read(file))
  end

  module LabelListTable
    def list_item_start(list_item, list_type)
      case list_type
      when :LABEL, :NOTE
        "<tr><td class='label'>#{Array(list_item.label).map{|label| to_html(label)}.join("<br />")}</td><td>"
      else
        super
      end
    end

    def list_end_for(list_type)
      case list_type
      when :LABEL, :NOTE then
        "</td></tr>"
      else
        super
      end
    end
  end
end 

class RDoc::Markup::ToHtml
  LIST_TYPE_TO_HTML[:LABEL] = ['<table class="rdoc-list label-list"><tbody>', '</tbody></table>']
  LIST_TYPE_TO_HTML[:NOTE]  = ['<table class="rdoc-list note-list"><tbody>',  '</tbody></table>']

  prepend RDoc::Generator::Hanna::LabelListTable
end
