require 'liquid'
require 'minitest/autorun'
require_relative './liquid_ext'

describe Liquid do
  before { Liquid::Template.file_system = Liquid::BlankFileSystem.new }

  describe "existing functionality" do
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

      it "evaluates the included file" do
        Liquid::Template.file_system = Class.new do
          def self.read_template_file(file)
            "{{ 'foobar' | upcase }}"
          end
        end

        Liquid::Template.parse("{% include 'my-file' %}").render!.must_equal "FOOBAR"
      end

      it "raises when a file is missing" do
        Liquid::Template.file_system = Class.new do
          def self.read_template_file(_)
            raise Liquid::FileSystemError
          end
        end

        -> { Liquid::Template.parse("{% include 'error' %}").render! }.must_raise Liquid::FileSystemError
      end
    end
  end

  describe "new functionality" do
    it "saves a list of variables" do
      template = Liquid::Template.parse(".. {{ x }} {{ x.y }} !!")
      template.render!({'x' => 5}).must_equal ".. 5  !!"
      template.missing_variables.must_equal ["x.y"]
      template.used_variables.must_equal ["x", "x.y"]
    end

    it "saves a list of filters" do
      template = Liquid::Template.parse("{{ 'foobar' | upcase | camelcase }}")
      template.render!({}).must_equal "FOOBAR"
      template.missing_filters.must_equal ["camelcase"]
      template.used_filters.must_equal ["upcase", "camelcase"]
    end

    it "saves a list of filters - multiple missing filters" do
      template = Liquid::Template.parse("{{ 'barbaz' | snakecase | upcase | camelcase }}")
      template.render!({}).must_equal "BARBAZ"
      template.missing_filters.must_equal ["snakecase", "camelcase"]
      template.used_filters.must_equal ["snakecase", "upcase", "camelcase"]
    end

    it "saves a list of includes" do
      Liquid::Template.file_system = Class.new do
        def self.read_template_file(file)
          "Contents of #{file}"
        end
      end

      template = Liquid::Template.parse("{% include 'my-file' %}")
      template.render!.must_equal "Contents of my-file"
      template.included_files.must_equal ["my-file"]
    end
  end
end