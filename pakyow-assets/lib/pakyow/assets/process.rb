# frozen_string_literal: true

require "pakyow/process"

module Pakyow
  module Assets
    # Manages the webpack process.
    #
    class Process < Process
      def initialize(server, app)
        super(server)
        @app = app
      end

      def start
        @pid = ::Process.spawn("PAKYOW_ASSETS_CONFIG='#{Base64.encode64(@app.config.assets.to_hash.to_json)}' #{@app.config.assets.webpack_command} --watch", out: File.open(File::NULL, "w"), err: $stderr)

        # TODO: in the future, we may also start the webpack-dev-server based on config options
      end

      protected

      def watch_callback(modified, added, removed)
        if restart?(modified, added, removed)
          @app.build_packs
          restart
        end
      end

      def restart?(modified, added, removed)
        return true if (added + removed).find { |path|
          @app.config.assets.extensions.include?(File.extname(path))
        }

        expanded_presenter_path = File.expand_path(@app.config.presenter.path)
        return true if modified.find { |path|
          !@app.config.assets.extensions.include?(File.extname(path)) && File.expand_path(path).start_with?(expanded_presenter_path)
        }

        false
      end
    end
  end
end
