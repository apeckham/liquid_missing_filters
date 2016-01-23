# https://github.com/jekyll/jekyll/issues/3008
# https://github.com/Shopify/liquid/issues/490
# https://github.com/bluerail/liquid/commit/a7796ff431e5b3b7b8107251d59335a6a0154f99

require 'liquid'
require 'minitest/autorun'

module Liquid
  # Monkey patches go here
end

describe Liquid do
  before { Liquid::Template.file_system = Liquid::BlankFileSystem.new }

  describe "existing functionality" do
    describe "file system" do
      it "does not include from BlankFileSystem" do
        block = -> { Liquid::Template.parse("{% include 'my-file' %}").render! }
        error = block.must_raise Liquid::FileSystemError
        error.message.must_equal "Liquid error: This liquid context does not allow includes."
      end

      it "includes a file" do
        Liquid::Template.file_system = Class.new do
          def self.read_template_file(file)
            "Contents of #{file}"
          end
        end

        Liquid::Template.parse("{% include 'my-file' %}").render!.must_equal "Contents of my-file"
      end

      it "includes a missing file" do
        Liquid::Template.file_system = Class.new do
          def self.read_template_file(_)
            raise Errno::ENOENT
          end
        end

        -> { Liquid::Template.parse("{% include 'error' %}").render! }.must_raise Errno::ENOENT
      end
    end

    describe "rendering" do
      it "renders x" do
        Liquid::Template.parse('hello {{ x }} world!').render!('x' => 5).must_equal 'hello 5 world!'
      end

      it "renders x.y" do
        Liquid::Template.parse('{{ x.y }} {{ x.y }}').render!('x' => {'y' => 'foo'}).must_equal 'foo foo'
      end

      it "renders upcase filter" do
        Liquid::Template.parse('{{ "foo" | upcase }}').render!.must_equal 'FOO'
      end

      it "renders append filter" do
        Liquid::Template.parse('{{ "sales" | append: ".jpg" }}').render!.must_equal 'sales.jpg'
      end

      it "raises on syntax errors" do
        block = -> { Liquid::Template.parse('{% if %}') }
        error = block.must_raise Liquid::SyntaxError
        error.message.must_equal "Liquid syntax error: Syntax Error in tag 'if' - Valid syntax: if [expression]"
      end
    end
  end

  describe "new functionality" do
    it "saves a list of missing includes" do
      Liquid::Template.file_system = Class.new do
        def self.read_template_file(file)
          raise Errno::ENOENT unless file == "existing"
        end
      end

      Liquid::Template.parse("{% include 'missing' %} {% include 'existing' %}").render!
      Liquid::Template.missing_includes.must_equal ["missing"]
    end

    it "saves a list of missing variables" do
      Liquid::Template.parse(".. {{ x }} {{ x.y }} !!").render!({'x' => 5}).must_equal ".. 5  !!"
      Liquid::Template.missing_variables.must_equal ["x.y"]
    end

    it "saves a list of missing filters" do
      Liquid::Template.parse("{{ 'foobar' | upcase | camelcase }}").render!({}).must_equal "FOOBAR"
      Liquid::Template.missing_filters.must_equal ["camelcase"]
    end
  end
end