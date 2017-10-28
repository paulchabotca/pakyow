require "pakyow/commands/development_environment/interface"

module Pakyow
  # @api private
  module Commands
    # @api private
    class Environment
      def run
        if running_in_app?
          @path = "./"
        else
          # TODO: present two options:
          #   - walk through the process of generating an app at some location
          #   - ask them for a path to an application they'd like to launch

          # TODO: maybe also store locations in a ~/.pakyow/apps.yml file and
          # present a third option: choose an app to run

          # whatever we do, we'll end with a path
        end

        @interface = DevelopmentEnvironment::Interface.new

        # TODO: we add a tab for every process. environment keeps up with the
        # processes while the interface maintains the rest of the reader state
        #
        # @interface.add_tab(:pakyow)

        # if dependency?(:sidekiq)
        #   @interface.add_tab(:sidekiq)
        # end

        Pakyow::STOP_SIGNALS.each do |signal|
          Signal.trap(signal) {
            @interface.quit
            stop_process
            exit
          }
        end

        reader, writer = IO.pipe
        @pid = Process.fork do
          $stdout.reopen(writer)
          $stderr.reopen(writer)
          start_server
        end

        @interface.pipe(reader)
        @interface.present

        stop_process
        exit
      end

      def running_in_app?
        dependency? :pakyow
      end

      def dependency?(name)
        if File.exist?(lockfile)
          dependencies.include?(name.to_s)
        else
          false
        end
      end

      def dependencies
        Bundler::LockfileParser.new(
          Bundler.read_file(lockfile)
        ).dependencies
      end

      def lockfile
        Bundler.default_lockfile
      end

      def start_server
        require "./config/environment"
        Pakyow.setup(env: @env).run(port: @port, host: @host, server: @server)
      end

      def stop_process
        Process.kill("INT", @pid) if @pid
      end
    end
  end
end
