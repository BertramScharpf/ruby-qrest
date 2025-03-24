#
#  qrest/bch.rb  --  Bose–Chaudhuri–Hocquenghem codes
#

require "qrest/base"


module QRest

  module Bch

    class <<self

      private

      def digit data
        n = 0
        while data != 0 do
          data >>= 1
          n += 1
        end
        n
      end

    end

    G15      = 0b0_0000_0101_0011_0111
    G15_MASK = 0b0_0101_0100_0001_0010
    G18      = 0b0_0001_1111_0010_0101

    G15D = digit G15
    G18D = digit G18

    class <<self

      def format_info data
        d = e = data << 10
        until (m = (digit d) - G15D) < 0 do
          d ^= G15 << m
        end
        (e | d) ^ G15_MASK
      end

      def version data
        d = e = data << 12
        until (m = (digit d) - G18D) < 0 do
          d ^= G18 << m
        end
        e | d
      end

    end

  end

end

