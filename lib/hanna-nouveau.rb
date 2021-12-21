# = A better RDoc HTML template
#
# Code rewritten by:
#   Erik Hollensbe <erik@hollensbe.org>
#
# RubyGems integration properly done by:
#   James Tucker (aka raggi)
#
# Original Authors:
#   Mislav Marohnic <mislav.marohnic@gmail.com>
#   Tony Strauss (http://github.com/DesigningPatterns)
#   Michael Granger <ged@FaerieMUD.org>, who had maintained the original RDoc template

require 'pathname'
require 'erb'
require 'rdoc/rdoc' unless defined?(RDoc::Markup::ToHtml)
require 'rdoc/generator'

class RDoc::Markup::ToHtml
  LIST_TYPE_TO_HTML[:LABEL] = ['<table class="rdoc-list label-list"><tbody>', '</tbody></table>']
  LIST_TYPE_TO_HTML[:NOTE]  = ['<table class="rdoc-list note-list"><tbody>',  '</tbody></table>']

  alias list_item_start list_item_start
  def list_item_start(list_item, list_type)
    case list_type
    when :BULLET, :LALPHA, :NUMBER, :UALPHA then
      "<li>"
    when :LABEL, :NOTE then
      "<tr><td class='label'>#{Array(list_item.label).map{|label| to_html(label)}.join("<br />")}</td><td>"
    else
      raise RDoc::Error, "Invalid list type: #{list_type.inspect}"
    end
  end

  alias list_end_for list_end_for
  def list_end_for(list_type)
    case list_type
    when :BULLET, :LALPHA, :NUMBER, :UALPHA then
      "</li>"
    when :LABEL, :NOTE then
      "</td></tr>"
    else
      raise RDoc::Error, "Invalid list type: #{list_type.inspect}"
    end
  end
end

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

  # EPIC CUT AND PASTE TIEM NAO -- GG
  RDoc::RDoc.add_generator( self )

  def self::for( options )
    new( options )
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

  rescue StandardError => err
    p [ err.class.name, err.message, err.backtrace.join("\n  ") ]
    raise
  end

  def write_static_files
    css_dir = outjoin('css')

    unless File.directory?(css_dir)
      FileUtils.mkdir css_dir
    end

    File.binwrite(File.join(css_dir, 'style.css'), File.read(templjoin(STYLE)))
  end

  # FIXME refactor
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

    # FIXME non-Ruby files
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

      # FIXME XXX sanity check
      dir = path.dirname
      unless File.directory? dir
        FileUtils.mkdir_p dir
      end

      File.binwrite(outjoin(file.path), result)
    end
  end

  def generate_class_files
    class_page       = erb_template(templjoin(CLASS_PAGE))
    method_list_page = erb_template(templjoin(METHOD_LIST_PAGE))
    sections_page    = erb_template(templjoin(SECTIONS_PAGE))
    # FIXME refactor

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

      # FIXME XXX sanity check
      dir = outfile.dirname
      unless File.directory? dir
        FileUtils.mkdir_p dir
      end

      File.binwrite(outfile, result)
    end
  end

  def with_layout(values)
    layout = erb_template(templjoin(LAYOUT))
    layout.to_html(binding, :values => values) { yield }
  end

  def sanitize_code_blocks(text)
    text.gsub(/<pre>(.+?)<\/pre>/m) do
      code = $1.sub(/^\s*\n/, '')
      indent = code.gsub(/\n[ \t]*\n/, "\n").scan(/^ */).map{ |i| i.size }.min
      code.gsub!(/^#{' ' * indent}/, '') if indent > 0

        "<pre>#{code}</pre>"
    end
  end

  # probably should bring in nokogiri/libxml2 to do this right.. not sure if
  # it's worth it.
  def frame_link(content)
    content.gsub(%r!<a href="http://[^>]*>!).each do |tag|
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

  # XXX may my sins be not visited upon my sons.
  def render_class_tree(entries, parent=nil)
    namespaces = { }

    entries.sort.inject('') do |out, klass|
      unless namespaces[klass.full_name]
        if parent
          text = '<span class="parent">%s::</span>%s' % [parent.full_name, klass.name]
        else
          text = klass.name
        end

        if klass.document_self
          out << '<li>'
          out << link_to(text, classfile(klass))
        end

        subentries = @classes.select { |x| x.full_name[/^#{klass.full_name}::/] }
        subentries.each { |x| namespaces[x.full_name] = true }
        out << "\n<ol>" + render_class_tree(subentries, klass) + "\n</ol>"

        if klass.document_self
          out << '</li>'
        end
      end

      out
    end
  end
    
  def link_to(text, url = nil, classname = nil)
    class_attr = classname ? ' class="%s"' % classname : ''

    if url
        %[<a href="#{url}"#{class_attr}>#{text}</a>]
    elsif classname
        %[<span#{class_attr}>#{text}</span>]
    else
      text
    end
  end

  # +method_text+ is in the form of "ago (ActiveSupport::TimeWithZone)".
  def link_to_method(entry, url = nil, classname = nil)
    method_name = entry.pretty_name rescue entry.name
    module_name = entry.parent_name rescue entry.name
    link_to %Q(<span class="method_name" value="#{entry.name}">#{h method_name}</span> <span class="module_name">(#{h module_name})</span>), url, classname
  end

  def classfile(klass)
    # FIXME sloooooooow
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
end 
