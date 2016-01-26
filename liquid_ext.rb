module Liquid
  class Template
    def render_with_info!(*args)
      render_with_info(*args)
    end

    def render_with_info(*args)
      raise ArgumentError unless args.first.is_a? Hash
      context = Context.new([args.shift, assigns], instance_assigns, registers, @rethrow_errors, @resource_limits)

      result = render(context, args.last)

      [
        result,
        {
          included_files: [],
          missing_filters: _missing_filters(context),
          missing_variables: _missing_variables(context),
          used_filters: _used_filters(context),
          used_variables: _used_variables(context)
        }
      ]
    end

    private

    def _all_variables
      @_all_variables ||= @root.nodelist.map do |node|
        if node.is_a?(Liquid::Variable)
          if node.name.is_a?(Liquid::VariableLookup)
            variable_name = node.name.name
            variable_name << ".#{node.name.lookups.join('.')}" if node.name.lookups.any?
            variable_name
          else
            nil
          end
        else
          nil
        end
      end.compact
    end

    def _all_filters
      @_all_filters ||= @root.nodelist.flat_map do |node|
        if node.is_a?(Liquid::Variable)
          node.filters.map { |filter| filter[0] }
        else
          nil
        end
      end.compact
    end

    def _used_variables(context)
      _all_variables - _missing_variables(context)
    end

    def _missing_variables(context)
      @_missing_variables ||= _all_variables - context.environments.flat_map(&:keys)
    end

    def _used_filters(context)
      @_used_filters ||= _all_filters.select do |filter|
        context.strainer.class.invokable? filter
      end
    end

    def _missing_filters(context)
      _all_filters - _used_filters(context)
    end
  end
end
