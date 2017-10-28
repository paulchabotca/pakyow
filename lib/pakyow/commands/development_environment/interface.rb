require "curses"
require "tty-screen"
require "io/console"
require "forwardable"

require "pakyow/commands/development_environment/cursor"
require "pakyow/commands/development_environment/header"
require "pakyow/commands/development_environment/input"
require "pakyow/commands/development_environment/output"

module Pakyow
  module DevelopmentEnvironment
    class Interface
      extend Forwardable
      def_delegators :@screen, :height, :width

      def initialize
        @screen = TTY::Screen.new

        Curses.noecho
        Curses.nonl
        Curses.cbreak
        Curses.stdscr.keypad(true)
        Curses.raw
        Curses.stdscr.nodelay = 1
        Curses.init_screen
        Curses.start_color
        Curses.use_default_colors

        Curses.init_pair(1, Curses::COLOR_GREEN, Curses::COLOR_BLACK)
        Curses.init_pair(2, Curses::COLOR_BLACK, Curses::COLOR_GREEN)
        Curses.init_pair(3, Curses::COLOR_BLACK, Curses::COLOR_WHITE)
        Curses.init_pair(4, Curses::COLOR_BLACK, Curses::COLOR_RED)

        Curses.clear

        Curses.mousemask(Curses::BUTTON1_CLICKED|Curses::BUTTON2_CLICKED|Curses::BUTTON3_CLICKED|Curses::BUTTON4_CLICKED)

        Curses.curs_set(0)

        @header = Header.new(width, 3, "pakyow")
        @header.present

        @output = Output.new(width, height)
        @output.present

        @input = Input.new(width, height - 1)
        @input.present

        Signal.trap "SIGWINCH" do
          # TODO: resizing is sketchy... width works but not height
          # @header.resize(width)
          # @input.resize(width, height - 1)
        end
      end

      def pipe(reader)
        Thread.new do
          while message = reader.gets
            @output.write message
          end
        end
      end

      def present
        catch :quit do
          @input.start
        end

        quit
      end

      def quit
        Curses.clear
        Curses.close_screen
      end

      def to_str
        "interface"
      end
    end
  end
end
