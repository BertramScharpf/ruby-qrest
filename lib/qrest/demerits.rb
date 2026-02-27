#
#  qrest/demerits.rb  --  Compute demerits
#

require "qrest/base"


module QRest

  class Demerits

    def initialize fields
      @fields = fields
    end

    def total **weigths
      weigths.inject 0 do |sum,(k,v)|
        e = ([*(send k)].zip [*v]).inject 0 do |s,(r,f)| s += r*f end
        sum + e.round
      end
    end

    private

    def same_color
      points, add = 0, 0
      each_pixel do |row,col|
        same = 0
        dark = @fields[row][col]
        each_around row, col do |d|
          same += 1 if dark == d
        end
        a = same - 5
        if a > 0 then
          points += 1
          add    += a
        end
      end
      [ points, add]
    end

    def each_pixel
      @fields.size.times do |row|
        @fields.size.times do |col|
          yield row, col
        end
      end
    end

    def same_region i
      n = i+1
      (i == 0 ? 0 : -1)..(n >= @fields.size ? 0 : 1)
    end

    def each_around row, col
      (same_region row).each do |r|
        rn = row + r
        (same_region col).each do |c|
          next if r == 0 && c == 0
          cn = col + c
          yield @fields[rn][cn]
        end
      end
    end


    def full_blocks
      points = 0
      each_block do |b|
        b.uniq!
        points += 1 unless b.length > 1
      end
      points
    end

    def each_block
      sp = @fields.size - 1
      sp.times do |ri|
        rn = ri + 1
        sp.times do |ci|
          cn = ci + 1
          yield [ @fields[ri][ci], @fields[rn][ci], @fields[ri][cn], @fields[rn][cn], ]
        end
      end
    end


    def dangerous
      points = 0
      @fields.each do |rs|
        rs.each_cons 7 do |fs|
          points += 1 if is_probe? fs
        end
      end
      @fields.each_cons 7 do |rs|
        @fields.size.times do |c|
          points += 1 if is_probe? rs.map { |r| r[c] }
        end
      end
      points
    end

    def is_probe? fields
      f0, f1, f2, f3, f4, f5, f6 = fields
      f0 && !f1 && f2 && f3 && f4 && !f5 && f6
    end


    def dark_ratio
      dark = @fields.sum do |col| col.count true end
      all  = @fields.size*@fields.size
      (dark.to_f / all - 0.5).abs * 100
    end

  end

end

