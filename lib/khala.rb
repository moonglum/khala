require "nokogiri"

module Khala
  class Tag
    attr_reader :name
    attr_reader :replace
    attr_reader :if

    def initialize(name, attributes, loader)
      @name = name
      @attributes = Hash[attributes]
      @loader = loader
      @replace = @attributes.delete("data-replace")
      @each = @attributes.delete("data-each")
      @if = @attributes.delete("data-if")
      @ignore = @attributes.key?("data-ignore")
    end

    def attributes
      @attributes.each_with_object("") do |(key, val), result|
        result << " #{key}=\"#{val}\""
      end
    end

    def expandable?
      false
    end

    def ignore?
      @ignore
    end

    def iterator?
      !!@each
    end

    def iterator_item
      @each.split(":").first.strip
    end

    def iterator_collection
      @each.split(":").last.strip
    end

    def as_opening_tag
      "'<#{name}#{attributes}>'"
    end

    def as_closing_tag
      "'</#{name}>'"
    end
  end

  class Component < Tag
    def expandable?
      true
    end

    def expand
      # use lambda to open a new scope
      "lambda do\n#{prelude}\n#{template.buffer}end[]\n"
    end

    def prelude
      @attributes.map { |key, val| "#{key} = #{val}" }.join("\n")
    end

    def template
      Khala::Template.new(@loader.load(template_name), skip_tags: %w[html body])
    end

    def template_name
      /\Ac-(?<template>.*)/.match(name)[:template]
    end
  end

  class Document < Nokogiri::XML::SAX::Document
    attr_reader :loader
    attr_reader :buffer
    attr_reader :skip_tags

    def initialize(loader:, buffer:, skip_tags:)
      @loader = loader
      @buffer = buffer
      @skip_tags = skip_tags
    end

    def start_document
      @open_tags = []
    end

    def start_element(name, attributes)
      return if @ignore

      tag = if /\Ac-(?<template>.*)/ =~ name
              Component.new(name, attributes, loader)
            else
              Tag.new(name, attributes, loader)
            end
      @open_tags << tag

      @ignore = true if tag.ignore? || tag.replace || tag.expandable?
      return if tag.ignore?
      add_code "if #{tag.if}" if tag.if
      add_code "#{tag.iterator_collection}.each do |#{tag.iterator_item}|" if tag.iterator?
      add_expression tag.as_opening_tag unless tag.expandable? || skip_tags.include?(name)
      add_expression tag.replace if tag.replace
      @buffer << tag.expand if tag.expandable?
    end

    def end_element(name)
      return if @ignore && name != @open_tags.last.name
      @ignore = false

      tag = @open_tags.pop
      add_expression tag.as_closing_tag unless tag.expandable? || skip_tags.include?(name)
      add_code "end" if tag.iterator? || tag.if
    end

    def characters(string)
      add_expression "'#{string}'" unless @ignore
    end

    def error(error_message)
      return if /Tag .*-.* invalid/ =~ error_message # custom elements are valid

      raise error_message
    end

    private

    def add_expression(code)
      @buffer += "_buf << (#{code}).to_s\n"
    end

    def add_code(code)
      @buffer << "#{code}\n"
    end
  end

  class NoLoader
    def load(_template_name)
      raise "No loader configured"
    end
  end

  class Loader
    def initialize(templates)
      @templates = templates
    end

    def load(template)
      File.read("#{@templates}/#{template}.html")
    end
  end

  class Template
    attr_reader :buffer

    def self.load(template, templates:)
      loader = Loader.new(templates)
      Template.new(loader.load(template), loader: loader)
    end

    def initialize(template, buffer: "", loader: NoLoader.new, debug: false, skip_tags: [])
      document = Document.new(
        loader: loader,
        buffer: buffer,
        skip_tags: skip_tags
      )
      parser = Nokogiri::HTML::SAX::Parser.new(document)
      parser.parse(template)
      @buffer = document.buffer
      puts @buffer if debug
    end

    def execute(view_model)
      view_model.instance_eval("_buf = ''\n#{@buffer}_buf")
    end
  end
end
