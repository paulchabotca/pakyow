require "pastel"

module Pakyow
  module DevelopmentEnvironment
    class Output
      def initialize(width, height)
        @window = Curses::Window.new(height, width, 1, 1)

        @pastel = Pastel.new
      end

      def present
        @window.refresh
      end

      def resize(width, height)
        @window.resize(1, width)
        @window.move(height, 0)

        present
      end

      def write(text)
        @window << @pastel.strip(text)
        present
      end
    end
  end
end
