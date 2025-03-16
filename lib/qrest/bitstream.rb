#
#  qrest/bitstream.rb  --  Bit Stream
#

require "qrest/base"


module QRest

  class BitStream

    def initialize data
      @cur, @data = [], data.dup
    end

    def get
      if @cur.empty? and not @data.empty? then
        n = @data.shift
        8.times { @cur.push n.odd? ; n >>= 1 }
      end
      @cur.pop
    end

  end

end

