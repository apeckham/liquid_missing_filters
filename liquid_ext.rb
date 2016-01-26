module Liquid
  class Template
    def render_with_info(*args)
    end

    def render_with_info!(*args)
      result = render!(*args)
      [
        result,
        {
          all_variables: _all_variables,
          included_files: [],
          missing_filters: [],
          missing_variables: _missing_variables(*args),
          used_filters: [],
          used_variables: _used_variables
        }
      ]
    end

    private

    def _all_variables
      @_all_variables ||= @root.nodelist.map do |node|
        if node.is_a?(Liquid::Variable)
          variable_name = node.name.name
          variable_name << ".#{node.name.lookups.join('.')}" if node.name.lookups.any?
          variable_name
        else
          nil
        end
      end.compact
    end

    def _used_variables
      _all_variables - _missing_variables
    end

    def _missing_variables(*args)
      @_missing_variables ||= begin
        registers = case args.first
        when Liquid::Context
          args.first.registers
        when Hash
          args.first.keys
        end

        _all_variables - registers
      end
    end
  end
end
