# frozen_string_literal: true

require "pakyow/support/hookable"

module Pakyow
  module Security
    module Protection
      class Base
        include Support::Hookable
        known_events :reject

        SAFE_HTTP_METHODS = %i(get head options trace).freeze

        def initialize(config)
          @config = config
        end

        def call(connection)
          unless safe?(connection) || allowed?(connection)
            reject(connection)
          end
        end

        def reject(connection)
          performing :reject do
            logger(connection)&.warn "Request rejected by #{self.class}; env: #{loggable_env(connection.request.env).inspect}"
            connection.response.status = 403
            throw :halt
          end
        end

        def logger(connection)
          connection.request.env["rack.logger"]
        end

        def safe?(connection)
          SAFE_HTTP_METHODS.include? connection.request.method
        end

        def allowed?(_)
          false
        end

        protected

        def loggable_env(env)
          env.delete("puma.config"); env
        end
      end
    end
  end
end
