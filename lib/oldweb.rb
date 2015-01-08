# Copyright (C) 2015, all contributors <olddoc-public@80x24.org>
# License: GPLv3 or later (https://www.gnu.org/licenses/gpl-3.0.txt)
# Loosely derived from Darkfish in the main rdoc distribution
require 'rdoc'
require 'erb'
require 'pathname'
require 'yaml'
require 'cgi'
require 'uri'

class Oldweb
  RDoc::RDoc.add_generator(self)
  include ERB::Util
  attr_reader :class_dir
  attr_reader :file_dir

  # description of the generator
  DESCRIPTION = 'minimal HTML generator'

  # version of this generator
  VERSION = '1'

  def initialize(store, options)
    # just because we're capable of generating UTF-8 to get human names
    # right does not mean we should overuse it for quotation marks and such,
    # our clients may not have the necessary fonts.
    RDoc::Text::TO_HTML_CHARACTERS[Encoding::UTF_8] =
      RDoc::Text::TO_HTML_CHARACTERS[Encoding::ASCII]

    @store = store
    @options = options
    @base_dir = Pathname.pwd.expand_path
    @dry_run = options.dry_run
    @file_output = true
    @template_dir = Pathname.new(File.join(File.dirname(__FILE__), 'oldweb'))
    @template_cache = {}
    @classes = nil
    @context = nil
    @files = nil
    @methods = nil
    @modsort = nil
    @class_dir = nil
    @file_dir = nil
    @outputdir = nil
    @old_vcs_url = nil
    @git_tag = nil

    # olddoc-specific stuff
    # infer title from README
    if options.title == 'RDoc Documentation' && File.readable?('README')
      line = File.open('README') { |fp| fp.gets.strip }
      line.sub!(/\A=+\s*/, '')
      options.title = line
    end

    # load olddoc config
    cfg = '.olddoc.yml'
    if File.readable?(cfg)
      @old_cfg = YAML.load(File.read(cfg))
    else
      @old_cfg = {}
      warn "#{cfg} not readable"
    end
    %w(toc_max).each { |k| v = @old_cfg[k] and @old_cfg[k] = v.to_i }
    @old_cfg['toc_max'] ||= 6

    ni = {}
    noindex = @old_cfg['noindex'] and noindex.each { |k| ni[k] = true }
    @old_cfg['noindex'] = ni

    if cgit_url = @old_cfg['cgit_url']
      cgit_url += '/tree/%s' # path name
      tag = @git_tag and cgit_url << "id=#{URI.escape(tag)}"
      cgit_url << '#n%d' # lineno
      @old_vcs_url = cgit_url
    end
  end

  def generate
    setup
    generate_class_files
    generate_file_files
    generate_table_of_contents
    src = Dir["#@outputdir/README*.html"].first
    begin
      dst = "#@outputdir/index.html"
      File.link(src, dst)
    rescue SystemCallError
      IO.copy_stream(src, dst)
    end if src
  end

  def rel_path(out_file)
    rel_prefix = @outputdir.relative_path_from(out_file.dirname)
    rel_prefix == '.' ? '' : "#{rel_prefix}/"
  end

  # called standalone by servelet
  def generate_class(klass, template_file = nil)
    setup
    current = klass
    template_file ||= @template_dir + 'class.rhtml'
    out_file = @outputdir + klass.path
    rel_prefix = rel_path(out_file)
    @title = "#{klass.type} #{klass.full_name}"
    @suppress_warning = [ rel_prefix, current ]
    render_template(template_file, out_file) { |io| binding }
  end

  # Generate a documentation file for each class and module
  def generate_class_files
    setup
    template_file = @template_dir + 'class.rhtml'
    current = nil

    @classes.each do |klass|
      current = klass
      generate_class(klass, template_file)
    end
  rescue => e
    e!(e, "error generating #{current.path}: #{e.message} (#{e.class})")
  end

  # Generate a documentation file for each file
  def generate_file_files
    setup
    @files.each do |file|
      generate_page(file) if file.text?
    end
  end

  # Generate a page file for +file+
  def generate_page(file, out_file = @outputdir + file.path)
    setup
    template_file = @template_dir + 'page.rhtml'
    rel_prefix = rel_path(out_file)
    current = file

    @title = "#{file.page_name} - #{@options.title}"

    # use the first header as title instead of page_name if there is one
    File.open("#{@options.root}/#{file.absolute_name}") do |f|
      line = f.gets.strip
      line.sub!(/^=+\s*/, '') and @title = line
    end

    @suppress_warning = [ current, rel_prefix ]

    render_template(template_file, out_file) { |io| binding }
  rescue => e
    e!(e, "error generating #{out_file}: #{e.message} (#{e.class})")
  end

  # Generates the 404 page for the RDoc servlet
  def generate_servlet_not_found(message)
    setup
    template_file = @template_dir + 'servlet_not_found.rhtml'
    rel_prefix = ''
    @suppress_warning = rel_prefix
    @title = 'Not Found'
    render_template(template_file) { |io| binding }
  rescue => e
    e!(e, "error generating servlet_not_found: #{e.message} (#{e.class})")
  end

  # Generates the servlet root page for the RDoc servlet
  def generate_servlet_root(installed)
    setup

    template_file = @template_dir + 'servlet_root.rhtml'

    rel_prefix = ''
    @suppress_warning = rel_prefix

    @title = 'Local RDoc Documentation'
    render_template(template_file) { |io| binding }
  rescue => e
    e!(e, "error generating servlet_root: #{e.message} (#{e.class})")
  end

  def generate_table_of_contents
    setup
    template_file = @template_dir + 'table_of_contents.rhtml'
    out_file = @outputdir + 'table_of_contents.html'
    rel_prefix = rel_path(out_file)
    @suppress_warning = rel_prefix
    @title = "Table of Contents - #{@options.title}"
    render_template(template_file, out_file) { |io| binding }
  rescue => e
    e!(e, "error generating table_of_contents.html: #{e.message} (#{e.class})")
  end

  def setup
    return if @outputdir
    @outputdir = Pathname.new(@options.op_dir).expand_path(@base_dir)
    return unless @store
    @classes = @store.all_classes_and_modules.sort
    @files = @store.all_files.sort
    @methods = @classes.map(&:method_list).flatten.sort
    @modsort = @classes.select(&:display?).sort
  end

  # Creates a template from its components and the +body_file+.
  def assemble_template(body_file)
    body = body_file.read
    head = @template_dir + '_head.rhtml'
    tail = @template_dir + '_tail.rhtml'
    "<html><head>#{head.read.strip}</head><body\n" \
      "id=\"top\">#{body.strip}#{tail.read.strip}</body></html>"
  end

  # Renders the ERb contained in +file_name+ relative to the template
  # directory and returns the result based on the current context.
  def render(file_name)
    template_file = @template_dir + file_name
    template = template_for(template_file, false, RDoc::ERBPartial)
    template.filename = template_file.to_s
    template.result(@context)
  end

  # Load and render the erb template in the given +template_file+ and write
  # it out to +out_file+.
  # Both +template_file+ and +out_file+ should be Pathname-like objects.
  # An io will be yielded which must be captured by binding in the caller.
  def render_template(template_file, out_file = nil) # :yield: io
    io_output = out_file && !@dry_run && @file_output
    erb_klass = io_output ? RDoc::ERBIO : ERB
    template = template_for(template_file, true, erb_klass)

    if io_output
      out_file.dirname.mkpath
      out_file.open('w', 0644) do |io|
        io.set_encoding(@options.encoding)
        @context = yield io
        template_result(template, @context, template_file)
      end
    else
      @context = yield nil
      template_result(template, @context, template_file)
    end
  end

  # Creates the result for +template+ with +context+.  If an error is raised a
  # Pathname +template_file+ will indicate the file where the error occurred.
  def template_result(template, context, template_file)
    template.filename = template_file.to_s
    template.result(context)
  rescue NoMethodError => e
    e!(e, "Error while evaluating #{template_file.expand_path}: #{e.message}")
  end

  def template_for(file, page = true, klass = ERB)
    template = @template_cache[file]

    return template if template

    if page
      template = assemble_template(file)
      erbout = 'io'
    else
      template = file.read
      template = template.encode(@options.encoding)
      file_var = File.basename(file).sub(/\..*/, '')
      erbout = "_erbout_#{file_var}"
    end

    template = klass.new(template, nil, '<>', erbout)
    @template_cache[file] = template
  end

  def e!(e, msg)
    raise RDoc::Error, msg, e.backtrace
  end

  def method_srclink(m)
    url = @old_vcs_url or return ""
    line = m.line or return ""
    path = URI.escape(m.file_name)
    %Q(<a href="#{url % [ path, line ]}">source</a>)
  end

  # reach into RDoc internals to generate less HTML
  module LessHtml
    def accept_verbatim(verbatim)
      @res << "\n<pre>#{CGI.escapeHTML(verbatim.text.rstrip)}</pre>\n"
    end

    def accept_heading(heading)
      level = [6, heading.level].min
      label = heading.label(@code_object)
      @res << "<h#{level}"
      @res << (@options.output_decoration ? "\nid=\"#{label}\">" : ">")
      @res << to_html(heading.text)
      @res << "</h#{level}>"
    end
  end
end

class RDoc::Markup::ToHtml # :nodoc:
  remove_method :accept_heading
  remove_method :accept_verbatim
  include Oldweb::LessHtml
end
