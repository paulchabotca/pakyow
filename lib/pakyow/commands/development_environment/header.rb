module Pakyow
  module DevelopmentEnvironment
    class Header
      def initialize(width, background_color, title)
        @title = title

        @window = Curses::Window.new(1, width, 0, 0)
        @window.color_set(background_color)
        @window << @title.center(width)
      end

      def present
        @window.refresh
      end

      def resize(width)
        @window.resize(1, width)
        @window.move(0, 0)
        @window.setpos(0,0)
        @window << @title.center(width)

        present
      end
    end
  end
end
