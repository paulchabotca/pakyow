# frozen_string_literal: true

require "pakyow/support/array"

module Pakyow
  class Aargv
    def self.normalize(args, opts)
      Hash[opts.map { |opt_name, opt_types|
        [opt_name, value_of_type(args, Array.ensure(opt_types))]
      }.reject { |pair| pair[1].nil? }]
    end

    def self.value_of_type(values, types)
      if match = values.find { |value| types.find { |type| value.is_a?(type) } }
        values.delete(match)
      else
        nil
      end
    end
  end
end
