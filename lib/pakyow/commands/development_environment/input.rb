module Pakyow
  module DevelopmentEnvironment
    class Input
      def initialize(width, height)
        @window = Curses::Window.new(1, width, height, 0)
        @window.keypad = true
        @window << "> "
      end

      def present
        @window.refresh
      end

      def start
        loop do
          input = @window.getch

          if input == "q"
            throw :quit
          end

          # TODO: use left/right to cycle between tabs
          # TODO: place tabs on the right of the input

          # if input == Curses::KEY_LEFT
          #   next if Cursor.pos[:column] == 3
          #   @window.setpos(0, Cursor.pos[:column] - 2)
          #   present
          #   next
          # end

          # if input == Curses::KEY_RIGHT
          #   next if Cursor.pos[:column] - 2 > @len
          #   @window.setpos(0, Cursor.pos[:column])
          #   next
          # end

          if input.is_a?(Integer)
            if input == 3
              break
            end
          #   if input == 127
          #     next if Cursor.pos[:column] == 3
          #     @len -= 1
          #     @window.setpos(0, Cursor.pos[:column] - 2)
          #     @window.delch
          #   end
          else
            @window << input
            present
          end
        end
      end

      def resize(width, height)
        @window.resize(1, width)
        @window.move(height, 0)
        # @window.setpos(0,0)

        present
      end
    end
  end
end
