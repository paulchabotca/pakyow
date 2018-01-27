# frozen_string_literal: true

require "pakyow/support/pipeline"

module Pakyow
  module Security
    module Pipelines
      module CSRF
        extend Support::Pipeline

        action :verify_same_origin
        action :verify_authenticity_token

        def verify_same_origin
          config.csrf.protection.call(@__state)
        end

        def verify_authenticity_token
          # TODO: to be implemented
        end
      end
    end
  end
end
