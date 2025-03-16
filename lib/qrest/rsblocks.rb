#
#  qrest/rsblocks.rb  --  Reed-Solomon-Code blocks
#

require "qrest/base"
require "qrest/bitbuffer"
require "qrest/polynomial"


module QRest

  class RSBlocks

    class Block

      attr_reader :data_count, :total_count

      def initialize total_count, data_count
        @total_count, @data_count = total_count, data_count
      end

      def error_count ; total_count - data_count ; end

    end

    def initialize version, bs
      @version = version
      @list = bs.map { |num,total,data| [ num, (Block.new total, data)] }
    end

    def each    ; @list.each { |(n,b)| n.times { yield b } }     ; end
    def sum sym ; @list.map  { |(n,b)| n * (b.send sym)    }.sum ; end
    def max sym ; @list.map  { |(_,b)| (b.send sym)        }.max ; end

    def create_data data
      l = sum :data_count
      b = BitBuffer.build l do |buf| data.write buf, @version end
      create_bytes b
    end

    private

    def create_bytes buffer
      dcdata, ecdata = [], []
      i = 0
      each do |rs|
        p = Polynomial.new buffer[ i, rs.data_count]
        i += rs.data_count
        dcdata.push p.num
        ecdata.push (p.error_mod rs.error_count).num
      end
      data = []
      (max :data_count).times do |j|
        dcdata.each do |dc|
          data.push dc[j] if j < dc.size
        end
      end
      (max :error_count).times do |j|
        ecdata.each do |ec|
          data.push ec[j] if j < ec.size
        end
      end
      data.length == (sum :total_count) or
        raise Error, "Internal error. Please consider a report."
      data
    end

    @blocks = Hash.new { |h,k|
      v = nil
      RS_BLOCK_TABLE.each_line { |l|
        n, l = l.split nil, 2
        if n.to_i == k then
          v = {}
          while l =~ /([a-z])\b([ 0-9,]+)/ do
            n, b, l = $1, $2, $'
            b.rstrip!
            v[ n.to_sym] = (b.split /,/).map { |t| t.split.map { |i| i.to_i } }
          end
          break
        end
      }
      h[k] = v
    }

    class <<self

      private :new

      def get version, error_correct_level
        v = @blocks[version] or raise ArgumentError, "No RS block for version #{version}"
        new version, v[error_correct_level]
      end

    end

    # http://www.thonky.com/qr-code-tutorial/error-correction-table/
    RS_BLOCK_TABLE = <<~EOT
      1  l  1  26  19,             m  1 26 16,           q  1 26 13,           h  1 26  9,
      2  l  1  44  34,             m  1 44 28,           q  1 44 22,           h  1 44 16,
      3  l  1  70  55,             m  1 70 44,           q  2 35 17,           h  2 35 13,
      4  l  1 100  80,             m  2 50 32,           q  2 50 24,           h  4 25  9,
      5  l  1 134 108,             m  2 67 43,           q  2 33 15,  2 34 16, h  2 33 11,  2 34 12,
      6  l  2  86  68,             m  4 43 27,           q  4 43 19,           h  4 43 15,
      7  l  2  98  78,             m  4 49 31,           q  2 32 14,  4 33 15, h  4 39 13,  1 40 14,
      8  l  2 121  97,             m  2 60 38,  2 61 39, q  4 40 18,  2 41 19, h  4 40 14,  2 41 15,
      9  l  2 146 116,             m  3 58 36,  2 59 37, q  4 36 16,  4 37 17, h  4 36 12,  4 37 13,
      10 l  2  86  68,  2  87  69, m  4 69 43,  1 70 44, q  6 43 19,  2 44 20, h  6 43 15,  2 44 16,
      11 l  4 101  81,             m  1 80 50,  4 81 51, q  4 50 22,  4 51 23, h  3 36 12,  8 37 13,
      12 l  2 116  92,  2 117  93, m  6 58 36,  2 59 37, q  4 46 20,  6 47 21, h  7 42 14,  4 43 15,
      13 l  4 133 107,             m  8 59 37,  1 60 38, q  8 44 20,  4 45 21, h 12 33 11,  4 34 12,
      14 l  3 145 115,  1 146 116, m  4 64 40,  5 65 41, q 11 36 16,  5 37 17, h 11 36 12,  5 37 13,
      15 l  5 109  87,  1 110  88, m  5 65 41,  5 66 42, q  5 54 24,  7 55 25, h 11 36 12,  7 37 13,
      16 l  5 122  98,  1 123  99, m  7 73 45,  3 74 46, q 15 43 19,  2 44 20, h  3 45 15, 13 46 16,
      17 l  1 135 107,  5 136 108, m 10 74 46,  1 75 47, q  1 50 22, 15 51 23, h  2 42 14, 17 43 15,
      18 l  5 150 120,  1 151 121, m  9 69 43,  4 70 44, q 17 50 22,  1 51 23, h  2 42 14, 19 43 15,
      19 l  3 141 113,  4 142 114, m  3 70 44, 11 71 45, q 17 47 21,  4 48 22, h  9 39 13, 16 40 14,
      20 l  3 135 107,  5 136 108, m  3 67 41, 13 68 42, q 15 54 24,  5 55 25, h 15 43 15, 10 44 16,
      21 l  4 144 116,  4 145 117, m 17 68 42,           q 17 50 22,  6 51 23, h 19 46 16,  6 47 17,
      22 l  2 139 111,  7 140 112, m 17 74 46,           q  7 54 24, 16 55 25, h 34 37 13,
      23 l  4 151 121,  5 152 122, m  4 75 47, 14 76 48, q 11 54 24, 14 55 25, h 16 45 15, 14 46 16,
      24 l  6 147 117,  4 148 118, m  6 73 45, 14 74 46, q 11 54 24, 16 55 25, h 30 46 16,  2 47 17,
      25 l  8 132 106,  4 133 107, m  8 75 47, 13 76 48, q  7 54 24, 22 55 25, h 22 45 15, 13 46 16,
      26 l 10 142 114,  2 143 115, m 19 74 46,  4 75 47, q 28 50 22,  6 51 23, h 33 46 16,  4 47 17,
      27 l  8 152 122,  4 153 123, m 22 73 45,  3 74 46, q  8 53 23, 26 54 24, h 12 45 15, 28 46 16,
      28 l  3 147 117, 10 148 118, m  3 73 45, 23 74 46, q  4 54 24, 31 55 25, h 11 45 15, 31 46 16,
      29 l  7 146 116,  7 147 117, m 21 73 45,  7 74 46, q  1 53 23, 37 54 24, h 19 45 15, 26 46 16,
      30 l  5 145 115, 10 146 116, m 19 75 47, 10 76 48, q 15 54 24, 25 55 25, h 23 45 15, 25 46 16,
      31 l 13 145 115,  3 146 116, m  2 74 46, 29 75 47, q 42 54 24,  1 55 25, h 23 45 15, 28 46 16,
      32 l 17 145 115,             m 10 74 46, 23 75 47, q 10 54 24, 35 55 25, h 19 45 15, 35 46 16,
      33 l 17 145 115,  1 146 116, m 14 74 46, 21 75 47, q 29 54 24, 19 55 25, h 11 45 15, 46 46 16,
      34 l 13 145 115,  6 146 116, m 14 74 46, 23 75 47, q 44 54 24,  7 55 25, h 59 46 16,  1 47 17,
      35 l 12 151 121,  7 152 122, m 12 75 47, 26 76 48, q 39 54 24, 14 55 25, h 22 45 15, 41 46 16,
      36 l  6 151 121, 14 152 122, m  6 75 47, 34 76 48, q 46 54 24, 10 55 25, h  2 45 15, 64 46 16,
      37 l 17 152 122,  4 153 123, m 29 74 46, 14 75 47, q 49 54 24, 10 55 25, h 24 45 15, 46 46 16,
      38 l  4 152 122, 18 153 123, m 13 74 46, 32 75 47, q 48 54 24, 14 55 25, h 42 45 15, 32 46 16,
      39 l 20 147 117,  4 148 118, m 40 75 47,  7 76 48, q 43 54 24, 22 55 25, h 10 45 15, 67 46 16,
      40 l 19 148 118,  6 149 119, m 18 75 47, 31 76 48, q 34 54 24, 34 55 25, h 20 45 15, 61 46 16,
    EOT

  end

end

