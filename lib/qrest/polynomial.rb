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
            ge.gfexp! 1, e
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

    def first_gflog
      Polynomial.gflog @num.first
    end

    def each_gflog
      @num.each_with_index { |n,i|
        yield (Polynomial.gflog n), i
      }
    end

    def gfexp! i, n
      @num[ i] ^= Polynomial.gfexp n
    end

    def multiply e
      r = Polynomial.zeroes length + e.length - 1
      each_gflog { |gi,i|
        e.each_gflog { |gj,j|
          r.gfexp! i + j, gi + gj
        }
      }
      r
    end

    def error_mod error_count
      p = dup
      p.error_mod! error_count
    end

    def error_mod! error_count
      e = Polynomial.error_correct error_count
      extend! error_count
      loop do
        norm!
        break if length < e.length
        f = first_gflog
        e.each_gflog { |gi,i|
          gfexp! i, gi + f
        }
      end
      grow! error_count
      self
    end


    EXP_TABLE = [1]
    loop do
      x = x_ = EXP_TABLE.last << 1
      x &= 0xff
      x ^= 0x1d if x != x_
      break if x == EXP_TABLE.first
      EXP_TABLE.push x
    end
    EXP_TABLE


    LOG_TABLE = [nil] * 256
    255.times do |i|
      LOG_TABLE[EXP_TABLE[i]] = i
    end

    EXP_TABLE.freeze
    LOG_TABLE.freeze

    class <<self

      def gflog n
        LOG_TABLE[n] or raise ArgumentError, "Argument is out of domain: gflog(#{n})."
      end

      def gfexp n
        EXP_TABLE[n % 255]
      end

    end

  end

end

