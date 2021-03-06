require 'byebug'
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

  describe "#render_with_info" do
    describe "when wrong parameters are provided" do
      it "raises an exception" do
        template = Liquid::Template.parse(".. {{ x }} {{ x.y }} !!")
        -> { template.render_with_info('Wrong param') }.must_raise Liquid::ArgumentError
      end
    end

    describe "when document has deep structure" do
      it "collects correct information" do
        Liquid::Template.file_system = Class.new do
          def self.read_template_file(file)
            "Contents of #{file}"
          end
        end

        template = <<-eos
        <div>
          <ul>
            <li><a href="">{{ x }}</a></li>
            <li><a href="">{{ a.b.c }}</a></li>
            <li><a href="">{{ y.z }}</a></li>
            <li><a href="">{{ t }}</a></li>
          </ul>
          <strong>{{ 'foobar' | upcase | missingfilter | somefilter }}</strong>
          <div>
            {% include 'sidebar' %}
          </div>
          <ul>
          {% for item in items %}
            {% if item.valid %}
            <li>{{item.name}}</li>
            {% endif %}
          {% endfor %}
          </ul>
        </div>
        eos
        template = Liquid::Template.parse(template)
        result = template.render_with_info(
          'x' => 5,
          'y' => { 'z' => 20 },
          'items' => [
            { 'valid' => true, 'name' => 'Item1' },
            { 'valid' => false, 'name' => 'Item2' },
            { 'valid' => true, 'name' => 'Item3' }
          ]
        )
        expected = <<-eos
        <div>
          <ul>
            <li><a href="">5</a></li>
            <li><a href=""></a></li>
            <li><a href="">20</a></li>
            <li><a href=""></a></li>
          </ul>
          <strong>FOOBAR</strong>
          <div>
            Contents of sidebar
          </div>
          <ul>
            <li>Item1</li>
            <li>Item3</li>
          </ul>
        </div>
        eos
        result[0].gsub(/\n\s{2,}$/, "\n").squeeze("\n").must_equal expected

        result[1][:included_files].must_equal ["sidebar"]
        result[1][:missing_filters].must_equal ["missingfilter", "somefilter"]
        result[1][:missing_variables].must_equal ["a.b.c", "y.z", "t"]
        result[1][:used_filters].must_equal ["upcase"]
        result[1][:used_variables].must_equal ["x"]
      end
    end

    describe "when template includes other templates" do
      it "saves info for those templates as well" do
        Liquid::Template.file_system = Class.new do
          def self.read_template_file(file)
            if file == "partial1"
              "{% include 'partial2' %} {{ x }} {{ x.y }} {{ 'FOOBAR' | downcase | somefilter1 | somefilter2 }}"
            elsif file == "partial2"
              "{{ a }} {{ b }}"
            end
          end
        end

        template = Liquid::Template.parse(
          "{% include 'partial1' %} {{ z }} {{ z.y }} {{ 'barbaz' | upcase | somefilter3 | somefilter4 }}"
        )
        result = template.render_with_info({'z' => 5, 'x' => 12, 'a' => 3})
        result[0].must_equal "3  12  foobar 5  BARBAZ"

        result[1][:included_files].must_equal ["partial1", "partial2"]
        result[1][:used_variables].must_equal ["a", "x", "z"]
        result[1][:missing_variables].must_equal ["b", "x.y", "z.y"]
        result[1][:missing_filters].must_equal ["somefilter1", "somefilter2", "somefilter3", "somefilter4"]
        result[1][:used_filters].must_equal ["downcase", "upcase"]
      end
    end

    it "saves a list of variables" do
      template = Liquid::Template.parse(".. {{ x }} {{ x.y }} !!")
      result = template.render_with_info({'x' => 5})
      result[0].must_equal ".. 5  !!"

      result[1][:included_files].must_equal []
      result[1][:missing_filters].must_equal []
      result[1][:missing_variables].must_equal ["x.y"]
      result[1][:used_filters].must_equal []
      result[1][:used_variables].must_equal ["x"]
    end

    it "saves a list of filters" do
      template = Liquid::Template.parse("{{ 'foobar' | upcase | missingfilter }}")
      result = template.render_with_info({})
      result[0].must_equal "FOOBAR"

      result[1][:included_files].must_equal []
      result[1][:missing_filters].must_equal ["missingfilter"]
      result[1][:missing_variables].must_equal []
      result[1][:used_filters].must_equal ["upcase"]
      result[1][:used_variables].must_equal []
    end

    it "saves a list of filters - multiple missing filters" do
      template = Liquid::Template.parse("{{ 'barbaz' | missingfilter2 | upcase | missingfilter }}")
      result = template.render_with_info({})
      result[0].must_equal "BARBAZ"

      result[1][:included_files].must_equal []
      result[1][:missing_filters].must_equal ["missingfilter2", "missingfilter"]
      result[1][:missing_variables].must_equal []
      result[1][:used_filters].must_equal ["upcase"]
      result[1][:used_variables].must_equal []
    end

    it "saves a list of includes" do
      Liquid::Template.file_system = Class.new do
        def self.read_template_file(file)
          "Contents of #{file}"
        end
      end

      template = Liquid::Template.parse("{% include 'my-file' %}")
      result = template.render_with_info
      result[0].must_equal "Contents of my-file"

      result[1][:included_files].must_equal ["my-file"]
      result[1][:missing_filters].must_equal []
      result[1][:missing_variables].must_equal []
      result[1][:used_filters].must_equal []
      result[1][:used_variables].must_equal []
    end
  end
end
