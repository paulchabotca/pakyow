module Pakyow
  module DevelopmentEnvironment
    class Cursor
      class << self
        def pos
          res = ''
          $stdin.raw do |stdin|
            $stdout << "\e[6n"
            $stdout.flush
            while (c = stdin.getc) != 'R'
              res << c if c
            end
          end
          m = res.match /(?<row>\d+);(?<column>\d+)/
          { row: Integer(m[:row]), column: Integer(m[:column]) }
        end
      end
    end
  end
end
