#
#  qrest/bitbuffer.rb  --  Bit buffer
#

require "qrest/base"


module QRest

  class BitBuffer

    class <<self
      def build max
        i = new
        yield i
        i.finish max
        i.cont
      end
    end

    attr_reader :cont

    def initialize
      @cont, @rem = [], 0
    end

    # You want to see an example for premature optimization
    # turning into weird code? Okay, here we go.

    def put num, length
      n = []
      l = length - @rem
      if l > 0 then
        if (r = l % 8).zero? then
          prem = 0
        else
          prem = 8 - r
          n.unshift num << prem
          num >>= r
          length -= r
        end
        while length >= 8 do
          n.unshift num
          num >>= 8
          length -= 8
        end
      else
        prem = -l
        num <<= prem
      end
      @cont.last |= num if length > 0
      @cont.concat n.map { |b| b & 0xff }
      @rem = prem
      nil
    end

    def put_bit bit
      if @rem.zero? then
        @rem = 7
        @mask = 1 << @rem
        @cont.push 0
      else
        @mask >>= 1
        @rem -= 1
      end
      @cont.last |= @mask if bit
      nil
    end

    PAD = [ 0xec, 0x11, ]

    def finish max
      @cont.length <= max or raise Error, "Code length overflow: #{length}>#{max}"
      @cont.push 0 if @rem < 4 and @cont.length < max
      @rem = nil
      pad = max - @cont.length
      ps = PAD * (pad/2+1)
      ps.pop if pad.odd?
      @cont.concat ps
    end

  end

end

