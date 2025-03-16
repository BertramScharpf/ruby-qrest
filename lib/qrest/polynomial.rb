#
#  qrest/polynomial.rb  --  Polynomes
#

require "qrest/base"


module QRest

  class Polynomial

    @ec = {}

    class <<self

      def error_correct error_correct_length
        @ec[ error_correct_length] ||=
          if error_correct_length > 0 then
            e = error_correct_length - 1
            ge = new [1, 0]
            ge.gexp! 1, e
            (error_correct e).multiply ge
          else
            new [1]
          end
      end

      def zeroes len
        new [ 0] * len
      end

    end

    attr_reader :num

    def initialize num
      num.empty? and raise ArgumentError, "Empty polynomial."
      @num = num
    end

    def dup ; Polynomial.new @num.dup ; end

    def [] index ; @num[index] ; end
    def size ; @num.size ; end
    alias length size

    def norm!
      @num.shift while @num.first == 0
      self
    end

    def extend! shift
      shift.times { @num.push 0 }
    end

    def grow! n
      @num.unshift 0 until @num.length >= n
    end

    def first_glog
      Polynomial.glog @num.first
    end

    def each_glog
      @num.each_with_index { |n,i|
        yield (Polynomial.glog n), i
      }
    end

    def gexp! i, n
      @num[ i] ^= Polynomial.gexp n
    end

    def multiply e
      r = Polynomial.zeroes length + e.length - 1
      each_glog { |gi,i|
        e.each_glog { |gj,j|
          r.gexp! i + j, gi + gj
        }
      }
      r
    end

    def error_mod error_count
      e = Polynomial.error_correct error_count
      ef = e.first_glog
      p = dup
      p.extend! error_count
      loop do
        p.norm!
        break if p.length < e.length
        ratio = p.first_glog - ef
        e.each_glog { |gi,i|
          p.gexp! i, ratio + gi
        }
      end
      p.grow! error_count
      p
    end


    EXP_TABLE = []
    (0...8).each do |i|
      EXP_TABLE.push 1 << i
    end
    (8...256).each do |i|
      EXP_TABLE.push EXP_TABLE[i-4] ^ EXP_TABLE[i-5] ^ EXP_TABLE[i-6] ^ EXP_TABLE[i-8]
    end

    LOG_TABLE = [nil] * 256
    255.times do |i|
      LOG_TABLE[EXP_TABLE[i]] = i
    end

    EXP_TABLE.freeze
    LOG_TABLE.freeze

    class <<self

      def glog n
        n >= 1 or raise Error, "Internal error: glog(#{n})."
        LOG_TABLE[n]
      end

      def gexp n
        while n <  0   do n += 255 end
        while n >= 256 do n -= 255 end
        EXP_TABLE[n]
      end

    end

  end

end

