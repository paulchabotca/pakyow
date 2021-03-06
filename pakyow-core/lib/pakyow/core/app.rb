# frozen_string_literal: true

require "pakyow/support/configurable"
require "pakyow/support/definable"
require "pakyow/support/hookable"
require "pakyow/support/recursive_require"
require "pakyow/support/deep_freeze"
require "pakyow/support/class_level_state"
require "pakyow/support/pipelined"
require "pakyow/support/inspectable"

require "pakyow/core/connection"
require "pakyow/core/loader"
require "pakyow/core/endpoints"

require "forwardable"

module Pakyow
  # Pakyow's main application object. Can be defined directly or subclassed to
  # create multiple application objects, each containing its own state. These
  # applications can then be mounted as an endpoint within the environment.
  #
  # For example:
  #
  #   Pakyow::App.define do
  #     # define shared state here
  #   end
  #
  #   class APIApp < Pakyow::App
  #     # define state here
  #   end
  #
  #   Pakyow.configure do
  #     mount Pakyow::App, at: "/"
  #     mount APIApp, at: "/api"
  #   end
  #
  # One or more routers can be registered to process incoming requests.
  #
  # For example:
  #
  #   Pakyow::App.router do
  #     default do
  #       logger.info "hello world"
  #     end
  #   end
  #
  # Each request is processed in an instance of {Controller}.
  #
  # = Application Configuration
  #
  # Application objects can be configured. For example:
  #
  #   Pakyow::App.configure do
  #     config.app.name = "my-app"
  #   end
  #
  # It's possible to configure for specific environments. For example, here's
  # how to override +app.name+ in the +development+ environment:
  #
  #   Pakyow::App.configure :development do
  #     config.app.name = "my-dev-app"
  #   end
  #
  # The +app+ config namespace can be extended with custom options. For example:
  #
  #   Pakyow::App.configure do
  #     config.app.foo = "bar"
  #   end
  #
  # == Configuration Options
  #
  # These config options are available:
  #
  # - +config.app.name+ defines the name of the application, used when a human
  #   readable unique identifier is necessary. Default is "pakyow".
  #
  # - +config.app.root+ defines the root directory of the application, relative
  #   to where the environment is started from. Default is +./+.
  #
  # - +config.app.src+ defines where the application code lives, relative to
  #   where the environment is started from. Default is +{app.root}/app/lib+.
  #
  # - +config.app.dsl+ determines whether or not objects creation will be exposed
  #   through the simpler dsl.
  #
  # - +config.routing.enabled+ determines whether or not routing is enabled for
  #   the application. Default is +true+, except when running in the
  #   +prototype+ environment.
  #
  # - +config.cookies.path+ sets the URL path that must exist in the requested
  #   resource before sending the Cookie header. Default is +/+.
  #
  # - +config.cookies.expiry+ sets when cookies should expire, specified in
  #   seconds. Default is +60 * 60 * 24 * 7+ seconds, or 7 days.
  #
  # - +config.session.enabled+ determines whether sessions are enabled for the
  #   application. Default is +true+.
  #
  # - +config.session.key+ defines the name of the key that holds the session
  #   object. Default is +{app.name}.session+.
  #
  # - +config.session.secret+ defines the value used to verify that the session
  #   has not been tampered with. Default is the value of the +SESSION_SECRET+
  #   environment variable.
  #
  # - +config.session.old_secret+ defines the old session secret, which is
  #   used to rotate session secrets in a graceful manner.
  #
  # - +config.session.expiry+ sets when sessions should expire, specified in
  #   seconds.
  #
  # - +config.session.path+ defines the path for the session cookie.
  #
  # - +config.session.domain+ defines the domain for the session cookie.
  #
  # - +config.session.options+ contains options passed to the session store.
  #
  # - +config.session.object+ defines the object used to store sessions. Default
  #   is +Rack::Session::Cookie+.
  #
  # See {Support::Configurable} for more information.
  #
  # = Application Hooks
  #
  # Hooks can be defined for these events:
  #
  # - initialize
  # - configure
  # - load
  # - freeze
  #
  # For example, here's how to write to the log after initialization:
  #
  #   Pakyow.after :initialize do
  #     logger.info "application initialized"
  #   end
  #
  # See {Support::Hookable} for more information.
  #
  class App
    include Support::Definable

    include Support::Hookable
    known_events :initialize, :configure, :load, :finalize, :boot

    extend Forwardable

    # @!method use
    # Delegates to {builder}.
    def_delegators :builder, :use

    include Support::Configurable

    include Pakyow::Support::Inspectable
    inspectable :environment

    settings_for :app, extendable: true do
      setting :name, "pakyow"
      setting :root, File.dirname("")

      setting :src do
        File.join(config.app.root, "backend")
      end

      setting :dsl, true
      setting :helpers, []
      setting :aspects, []
      setting :frameworks, []
    end

    settings_for :cookies do
      setting :path, "/"

      setting :expiry, 60 * 60 * 24 * 7
    end

    settings_for :session do
      setting :enabled, true

      setting :key do
        "#{config.app.name}.session"
      end

      setting :secret do
        ENV["SESSION_SECRET"]
      end

      setting :object, Rack::Session::Cookie
      setting :old_secret
      setting :expiry
      setting :path
      setting :domain
    end

    # Loads and configures the session middleware.
    #
    after :configure do
      if config.session.enabled
        options = {
          key: config.session.key,
          secret: config.session.secret
        }

        # set expiry if set
        if expiry = config.session.expiry
          options[:expire_after] = expiry
        end

        # set optional options if available
        %i(domain path old_secret).each do |option|
          if value = config.session.send(option)
            options[option] = value
          end
        end

        builder.use config.session.object, options
      end
    end

    before :finalize do
      load_endpoints
      load_pipeline
    end

    # The environment the app is defined in.
    #
    attr_reader :environment

    # The rack builder.
    #
    attr_reader :builder

    # Endpoint lookup.
    #
    attr_reader :endpoints

    extend Support::DeepFreeze
    unfreezable :builder

    include Support::Pipelined

    def initialize(environment, builder: nil, stage: false, &block)
      @endpoints = Endpoints.new
      @environment = environment
      @builder = builder

      performing :initialize do
        performing :configure do
          use_config(environment)
        end

        unless stage
          performing :load do
            load_app
          end
        end
      end

      # Call the Pakyow::Definable initializer.
      #
      # This ensures that any state registered in the passed block
      # has the proper priority against instance and global state.
      defined!(&block) unless stage
    end

    def booted
      call_hooks :after, :boot
    end

    def call(env)
      begin
        connection = super(Connection.new(self, env))

        if connection.halted?
          connection.finalize
        else
          error_404
        end
      rescue StandardError => error
        env[Rack::RACK_LOGGER].houston(error)
        error_500
      end
    end

    def freeze
      performing :finalize do
        super
      end
    end

    protected

    def error_404
      [404, { Rack::CONTENT_TYPE => "text/plain" }, ["404 Not Found"]]
    end

    def error_500
      [500, { Rack::CONTENT_TYPE => "text/plain" }, ["500 Internal Server Error"]]
    end

    def load_app
      $LOAD_PATH.unshift(File.join(config.app.src, "lib"))

      config.app.aspects.each do |aspect|
        load_app_aspect(File.join(config.app.src, aspect.to_s), aspect)
      end
    end

    def load_app_aspect(state_path, state_type, load_target = self.class)
      Dir.glob(File.join(state_path, "*.rb")) do |path|
        if config.app.dsl
          Loader.new(load_target, Support::ClassNamespace.new(config.app.name, state_type), path).call
        else
          require path
        end
      end

      Dir.glob(File.join(state_path, "*")).select { |path| File.directory?(path) }.each do |directory|
        load_app_aspect(directory, state_type, load_target)
      end
    end

    def load_endpoints
      state.each_with_object(@endpoints) { |(_, state_object), endpoints|
        state_object.instances.each do |state_instance|
          endpoints << state_instance if state_instance.respond_to?(:path_to)
        end
      }
    end

    def load_pipeline
      if self.class.includes_framework?(:routing) && !Pakyow.env?(:prototype)
        state_for(:controller).each do |controller|
          @__pipeline.action(controller)
        end
      end

      if self.class.includes_framework?(:presenter) && !Pakyow.env?(:production)
        @__pipeline.action(Presenter::AutoRender)
      end

      if self.class.includes_framework?(:routing) && !Pakyow.env?(:prototype)
        @__pipeline.action(Routing::RespondMissing, self)
      end
    end

    class << self
      # Includes one or more frameworks into the app class.
      #
      def include_frameworks(*frameworks)
        tap do
          frameworks.each do |framework_name|
            include_framework(framework_name)
          end
        end
      end

      # Includes a framework into the app class.
      #
      def include_framework(framework_name)
        framework_name = framework_name.to_sym
        Pakyow.frameworks[framework_name].new(self).boot
        (config.app.frameworks << framework_name).uniq!
      end

      # Returns true if +framework+ is loaded.
      #
      def includes_framework?(framework_name)
        config.app.frameworks.include?(framework_name.to_sym)
      end

      # Registers an app aspect by name.
      #
      def aspect(name)
        (config.app.aspects << name.to_sym).uniq!
      end

      # Registers a helper module to be loaded on defined endpoints.
      #
      def helper(helper_module)
        (config.app.helpers << helper_module).uniq!
      end
    end
  end
end
