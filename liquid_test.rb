# https://github.com/jekyll/jekyll/issues/3008
# https://github.com/Shopify/liquid/issues/490

require 'liquid'
require 'minitest/autorun'

module Liquid
  class Strainer
    def invoke(method, *args)
      if invokable?(method)
        send(method, *args)
      else
        raise "Filter missing: #{method}" unless invokable?(method)
      end
    rescue ::ArgumentError => e
      raise Liquid::ArgumentError.new(e.message)
    end
  end
end

# https://github.com/bluerail/liquid/commit/a7796ff431e5b3b7b8107251d59335a6a0154f99
module Liquid
  class Context
    def lookup_and_evaluate(obj, key)
      if (value = obj[key]).is_a?(Proc) && obj.respond_to?(:[]=)
        obj[key] = (value.arity == 0) ? value.call : value.call(self)
      elsif !obj.has_key?(key)
        raise RuntimeError, "The variable `#{key}' is not defined"
      else
        value
      end
    end
  end
end

describe Liquid::Template do
  before do
    Liquid::Template.file_system = Liquid::BlankFileSystem.new
  end

  it 'renders' do
    Liquid::Template.parse('{{ x }}').render!('x' => 5).must_equal '5'
  end

  it 'renders' do
    Liquid::Template.parse('{{ x.y }}').render!('x' => {'y' => 6}).must_equal '6'
  end

  it 'renders a filter' do
    Liquid::Template.parse('{{ "x" | upcase }}').render!.must_equal 'X'
  end

  it 'renders a filter' do
    Liquid::Template.parse('{{ "sales" | append: ".jpg" }}').render!.must_equal 'sales.jpg'
  end

  it 'includes a file' do
    block = -> { Liquid::Template.parse("{% include 'open-graph-tags' %}").render! }
    error = block.must_raise Liquid::FileSystemError
    error.message.must_equal "Liquid error: This liquid context does not allow includes."
  end

  it 'includes a file' do
    class FakeFileSystem
      def read_template_file(file)
        "Content of #{file}"
      end
    end

    Liquid::Template.file_system = FakeFileSystem.new
    Liquid::Template.parse("{% include 'open-graph-tags' %}").render!.must_equal "Content of open-graph-tags"
  end

  it 'raises on syntax errors' do
    block = -> { Liquid::Template.parse('{% if %}') }
    error = block.must_raise Liquid::SyntaxError
    error.message.must_equal "Liquid syntax error: Syntax Error in tag 'if' - Valid syntax: if [expression]"
  end

  it 'raises when a variable is missing' do
    block = -> { Liquid::Template.parse("{{ x }}").render!({}) }
    error = block.must_raise RuntimeError
    error.message.must_equal "The variable `x' is not defined"
  end

  it 'raises when a filter is missing' do
    block = -> { Liquid::Template.parse("{{ 1 | x }}").render! }
    error = block.must_raise RuntimeError
    error.message.must_equal "Filter missing: x"
  end
end