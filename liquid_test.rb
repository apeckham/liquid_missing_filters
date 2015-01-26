require 'liquid'
require 'minitest/autorun'

module Liquid
  class Strainer
    def invoke(method, *args)
      raise "Filter missing: #{method}" unless invokable?(method)
      super method, *args
    end
  end
end

describe Liquid::Template do
  it 'renders' do
    Liquid::Template.parse('{{ x }}').render('x' => 5).must_equal '5'
  end

  it 'raises syntax errors' do
    -> do
      Liquid::Template.parse('{% if %}')
    end.must_raise Liquid::SyntaxError
  end

  it 'raises when a variable is missing' do
    -> do
      hash = {}
      hash.default_proc = lambda { |_, key| raise "missing #{key}" }
      Liquid::Template.parse("{{ x }}").render!(hash)
    end.must_raise RuntimeError
  end

  it 'raises when a filter is missing' do
    -> do
      Liquid::Template.parse("{{ 1 | x }}").render!
    end.must_raise RuntimeError
  end
end