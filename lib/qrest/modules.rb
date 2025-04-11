#
#  qrest/modules.rb  --  Modules
#

require "qrest/base"
require "qrest/bitstream"
require "qrest/demerits"
require "qrest/bch"


module QRest

  class Modules

    VERSIONS = 1..40

    POSITIONPATTERNLENGTH = (7 + 1) * 2 + 1

    ERRORCORRECTLEVEL = { l: 1, m: 0, q: 3, h: 2 }

    # http://web.archive.org/web/20110710094955/http://www.denso-wave.com/qrcode/vertable1-e.html
    # http://web.archive.org/web/20110710094955/http://www.denso-wave.com/qrcode/vertable2-e.html
    # http://web.archive.org/web/20110710094955/http://www.denso-wave.com/qrcode/vertable3-e.html
    # http://web.archive.org/web/20110710094955/http://www.denso-wave.com/qrcode/vertable4-e.html
    MAXBITS = {
      l: [152, 272, 440, 640, 864, 1088, 1248, 1552, 1856, 2192, 2592, 2960, 3424, 3688, 4184, 4712, 5176, 5768, 6360, 6888, 7456, 8048, 8752, 9392, 10_208, 10_960, 11_744, 12_248, 13_048, 13_880, 14_744, 15_640, 16_568, 17_528, 18_448, 19_472, 20_528, 21_616, 22_496, 23_648],
      m: [128, 224, 352, 512, 688, 864, 992, 1232, 1456, 1728, 2032, 2320, 2672, 2920, 3320, 3624, 4056, 4504, 5016, 5352, 5712, 6256, 6880, 7312, 8000, 8496, 9024, 9544, 10_136, 10_984, 11_640, 12_328, 13_048, 13_800, 14_496, 15_312, 15_936, 16_816, 17_728, 18_672],
      q: [104, 176, 272, 384, 496, 608, 704, 880, 1056, 1232, 1440, 1648, 1952, 2088, 2360, 2600, 2936, 3176, 3560, 3880, 4096, 4544, 4912, 5312, 5744, 6032, 6464, 6968, 7288, 7880, 8264, 8920, 9368, 9848, 10288, 10832, 11408, 12016, 12656, 13328],
      h: [72, 128, 208, 288, 368, 480, 528, 688, 800, 976, 1120, 1264, 1440, 1576, 1784, 2024, 2264, 2504, 2728, 3080, 3248, 3536, 3712, 4112, 4304, 4768, 5024, 5288, 5608, 5960, 6344, 6760, 7208, 7688, 7888, 8432, 8768, 9136, 9776, 10_208],
    }

    MASK_PATTERNS = [
      proc { |i,j| (i + j) % 2                     },
      proc { |i,j| i % 2                           },
      proc { |i,j| j % 3                           },
      proc { |i,j| (i + j) % 3                     },
      proc { |i,j| ((i / 2) + (j / 3)) % 2         },
      proc { |i,j| (i * j) % 2 + (i * j) % 3       },
      proc { |i,j| ((i * j) % 2 + (i * j) % 3) % 2 },
      proc { |i,j| ((i * j) % 3 + (i + j) % 2) % 2 },
    ]

    attr_reader :version, :count, :fields

    class <<self

      WEIGHTS = {
        same_color:  [ 3, 1],
        full_blocks: 3,
        dangerous:   40,
        dark_ratio:  2,
      }

      def create_best data
        demerits, pattern = nil, nil
        MASK_PATTERNS.length.times { |i|
          t = ModulesTest.new data, i
          d = t.demerits.total **WEIGHTS
          demerits, pattern = d, i if not pattern or demerits > d
        }
        new data, pattern
      end

    end

    def initialize data, mask_pattern
      count = data.version * 4 + POSITIONPATTERNLENGTH
      @fields = Array.new count do Array.new count end
      place_position_probe_pattern 0, 0
      place_position_probe_pattern @fields.size - 7, 0
      place_position_probe_pattern 0, @fields.size - 7
      place_position_adjust_pattern @fields.size
      place_timing_pattern
      place_format_info (ERRORCORRECTLEVEL[data.error_correct_level]<<3) | mask_pattern
      place_version_info data.version
      bs = BitStream.new data.data
      walk_fields mask_pattern do bs.get end
    end

    def inspect
      d = [
        "#{self.class}:",
        (@fields.map { |row| row.map { |x| x.nil? ? "?" : x ? "X" : "." }.join }.join " "),
      ].join " "
      "#<#{d}>"
    end

    def size  ; @fields.size        ; end
    def range ; @range ||= 0...size ; end

    def check? row, col
      range === row or raise Error, "Invalid row: #{row}/#{col}"
      range === col or raise Error, "Invalid column: #{row}/#{col}"
    end

    def []  row, col      ; check? roq, col ; @fields[ row][col]       ; end
    def []= row, col, val ; check? row, col ; @fields[ row][col] = val ; end

    def each_row &block
      @fields.each &block
    end

    def each_field quiet, start = 0
      ri = start + quiet
      each_row { |row|
        ci = quiet
        row.each { |field|
          yield ri, ci if field
          ci += 1
        }
        ri += 1
      }
    end

    def each_field_neg quiet, start = 0
      ri = start - quiet
      each_row { |row|
        ci = quiet
        row.each { |field|
          yield ri, ci if field
          ci += 1
        }
        ri -= 1
      }
    end

    def to_s dark: nil, light: nil, quiet_size: nil
      r = []
      lines dark: dark, light: light, quiet_size: quiet_size do |l| r.push l end
      r.join "\n"
    end

    def lines dark: nil, light: nil, quiet_size: nil
      dark  ||= "X"
      light ||= " "
      quiet_size ||= 0
      qr = light * (@fields.size + 2*quiet_size)
      quiet_size.times do yield qr end
      qc = light * quiet_size
      dl = { true => dark, false =>light, nil => "?"}
      @fields.each do |row|
        yield "" << qc << (row.map do |col| dl[ col] end.join) << qc
      end
      quiet_size.times do yield qr end
    end

    private

    R08 = 0..8
    R17 = 1..7
    R35 = 3..5

    def place_position_probe_pattern row, col
      R08.each do |i|
        r = row + i - 1
        next unless range === r
        iv = R17 ===             i
        ih = R17.minmax.include? i
        R08.each do |j|
          c = col + j - 1
          next unless range === c
          @fields[ r][ c] = (iv && (R17.minmax.include? j)) ||
                            (ih &&  R17 ===             j ) ||
                            (R35 === i && R35 === j)
        end
      end
    end


    @adjust_pattern = {}

    class <<self

      ADJUST_FIRST = 6
      def adjust_pattern_pos size
        @adjust_pattern[ size] ||= begin
          s = size - ADJUST_FIRST*2 - 1
          if s < ADJUST_FIRST*2 then
            []
          else
            kat = (s-1)/28
            ds = [ 0]
            case kat
            when 0 then             ds.push s
            when 1 then h = s / 2 ; ds.push h, h
            else
              28.step 20, -2 do |h|
                m = s - kat*h
                if m > h - [kat,3].max*2 then
                  ds.push m, *([ h] * kat)
                  break
                end
              end
            end
            p = ADJUST_FIRST
            ds.map { |e| p += e }
          end
        end
      end

    end

    R_22 = -2..2

    def place_position_adjust_pattern size
      ps = Modules.adjust_pattern_pos size
      rd = R_22.minmax
      ps.each do |row|
        ps.each do |col|
          next unless @fields[ row][ col].nil?
          R_22.each do |r|
            pr = row + r
            R_22.each do |c|
              pc = col + c
              @fields[ pr][ pc] = (rd.include? r) || (rd.include? c) || (r == 0 && c == 0)
            end
          end
        end
      end
    end

    def place_timing_pattern
      (8...@fields.size-8).each do |i|
        next unless @fields[ i][ 6].nil?
        @fields[ i][ 6] = @fields[ 6][ i] = i.even?
      end
    end

    def set_bit n
      n.odd?
    end

    def place_format_info ecl
      bits = Bch.format_info ecl
      15.times do |i|
        m = set_bit bits
        r =
          case i
          when ...6 then 0
          when ...8 then 1
          else           @fields.size - 15
          end
        @fields[ r + i][ 8] = m
        c =
          case i
          when ...8 then @fields.size
          when ...9 then 16
          else           15
          end
        @fields[ 8][ c - i - 1] = m
        bits >>= 1
      end
      @fields[ @fields.size - 8][ 8] = set_bit 1
    end

    def place_version_info version
      return if version < 7
      bits = Bch.version version
      18.times do |i|
        id, im = i.divmod 3
        im += @fields.size - 8 - 3
        @fields[ id][ im] = @fields[ im][ id] = set_bit bits
        bits >>= 1
      end
    end

    def walk_fields mask_pattern
      # An image says more than a thousand statements:
      # <https://en.wikipedia.org/wiki/QR_code#Message_placement>
      mp = MASK_PATTERNS[ mask_pattern] or
        raise ArgumentError, "Bad mask_pattern: #{mask_pattern}"
      row = c2 = @fields.size - 1
      inc = -1
      loop do
        loop do
          2.times do |c|
            col = c2 - c
            next unless @fields[ row][ col].nil?
            @fields[ row][ col] = (mp.call row, col).zero? ^ yield
          end
          ri = row + inc
          unless range === ri then
            inc = -inc
            break
          end
          row = ri
        end
        break if c2 == 1
        c2 -= 2
        c2 -= 1 if c2 == 6
      end
    end

  end

  class ModulesTest < Modules

    attr_reader :demerits

    def initialize data, mask_pattern
      super
      @demerits = Demerits.new @fields
    end

    def set_bit _ ; false ; end

  end

end

