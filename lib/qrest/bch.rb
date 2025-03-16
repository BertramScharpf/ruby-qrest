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

    G15      = 0b000010100110111
    G15_MASK = 0b101010000010010
    G18      = 0b001111100100101

    G15D = digit G15
    G18D = digit G18

    class <<self

      def format_info data
        d = data << 10
        until (m = (digit d) - G15D) < 0 do
          d ^= G15 << m
        end
        ((data << 10) | d) ^ G15_MASK
      end

      def version data
        d = data << 12
        until (m = (digit d) - G18D) < 0 do
          d ^= G18 << m
        end
        (data << 12) | d
      end

    end

  end

end

