require "forwardable"

module Pakyow
  module Routing
    # Expands a route template.
    #
    # @api private
    class Expansion
      attr_reader :expander, :router, :name

      extend Forwardable
      def_delegators :expander, *[:func, :default, :group, :namespace, :template].concat(Router::SUPPORTED_METHODS)

      def initialize(name, template, router)
        @name = name
        @router = router
        @expander = Router.make(router.name, nil, **router.hooks)
        instance_eval(&template)
      end

      def find_route(name)
        expander.routes.values.flatten.find { |route|
          route.name == name
        }
      end

      def find_child(name)
        expander.children.find { |child|
          child.name == name
        }
      end
    end
  end
end
