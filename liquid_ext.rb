module Liquid
  class Template #:nodoc:
    # Renders a template and returns the result and a hash with additional info:
    # :included_files – a list of all fiels included in the template
    # :missing_filters – a list of filters that were not invoked
    # :missing_variables – a list of variables that were not passed to the template during rendering
    # :used_filers – a list of successfully invoked filters
    # :used_variables – a list of passed and used variables
    def render_with_info(*args)
      context = case args.first
      when Hash
        Context.new([args.shift, assigns], instance_assigns, registers, @rethrow_errors, @resource_limits)
      when nil
        Context.new(assigns, instance_assigns, registers, @rethrow_errors, @resource_limits)
      else
        raise ArgumentError, 'Expected Hash as first parameter'
      end

      [
        render(*[context, args]),
        {
          included_files: _included_files(context),
          missing_filters: _missing_filters(context),
          missing_variables: _missing_variables(context),
          used_filters: _used_filters(context),
          used_variables: _used_variables(context)
        }
      ]
    end

    private

    def _all_variables(context, root = nil)
      root ||= @root

      @_all_variables ||= root.nodelist.flat_map do |node|
        if node.is_a?(Liquid::Include)
          template = node.send(
            :load_cached_partial,
            node.instance_variable_get(:@template_name_expr),
            context
          )
          _all_variables(context, template.root)
        elsif node.is_a?(Liquid::Variable) && node.name.is_a?(Liquid::VariableLookup)
          variable_name = node.name.name
          variable_name << ".#{node.name.lookups.join('.')}" if node.name.lookups.any?
          variable_name
        end
      end.compact
    end

    def _all_filters(context, root = nil)
      root ||= @root

      @_all_filters ||= root.nodelist.flat_map do |node|
        if node.is_a?(Liquid::Include)
          template = node.send(
            :load_cached_partial,
            node.instance_variable_get(:@template_name_expr),
            context
          )
          _all_filters(context, template.root)
        elsif node.is_a?(Liquid::Variable)
          node.filters.map { |filter| filter[0] }
        end
      end.compact.uniq
    end

    def _used_variables(context)
      _all_variables(context) - _missing_variables(context)
    end

    def _missing_variables(context)
      @_missing_variables ||= _all_variables(context) - context.environments.flat_map(&:keys)
    end

    def _used_filters(context)
      @_used_filters ||= _all_filters(context).select do |filter|
        context.strainer.class.invokable? filter
      end
    end

    def _missing_filters(context)
      _all_filters(context) - _used_filters(context)
    end

    def _included_files(context, root = nil)
      root ||= @root
      includes = []

      root.nodelist.each do |node|
        if node.is_a?(Liquid::Include)
          includes << node.instance_variable_get(:@template_name_expr)

          template = node.send(
            :load_cached_partial,
            includes.last,
            context
          )
          includes << _included_files(context, template.root)
        end
      end

      includes.flatten.compact
    end
  end
end
