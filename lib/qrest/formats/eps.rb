#
#  qrest/formats/xpm.rb  --  Build XPM
#

require "qrest/modules"
require "qrest/version"


module QRest

  class Modules

    def eps quiet_size: nil, output: nil
      quiet_size ||= 4
      output     ||= ""

      full = size + 2*quiet_size
      output << <<~EOT
        %!PS
        %%Creator: #{QRest::NAME} #{QRest::VERSION}
        %%BoundingBox: 0 0 #{full} #{full}
        %%EndComments
        /box { newpath moveto 0 -1 rlineto 1 0 rlineto 0 1 rlineto closepath fill } def
      EOT
      LinesOut.open output do |lo|
        each_field_neg quiet_size, full do |ri,ci|
          lo.put "%d %d box" % [ci,ri]
        end
      end
      output << <<~EOT
        showpage
      EOT
      output
    end

    class LinesOut
      class <<self
        private :new
        def open output
          i = new output
          yield i
          output << "\n"
        end
      end
      MAX = 78
      def initialize output
        @output = output
        @line = 0
      end
      def put str
        @line += str.length
        if @line > MAX then
          @output << "\n"
          @line = 0
        else
          @output << " "
        end
        @output << str
      end
    end

  end

end

