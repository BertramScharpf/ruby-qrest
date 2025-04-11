#
#  qrest/segment.rb  --  Segments
#

require "qrest/base"


module QRest

  class Segment

    def initialize data
      @data = data
    end

    def write_to buffer, version
      buffer.put self.class::ID, 4
      buffer.put @data.bytesize, (get_length_in_bits version)
    end

    def size version
      4 + (get_length_in_bits version) + (
        chunk_size, bit_length, extra = cbe
        num, rest = @data.bytesize.divmod chunk_size
        r = num * bit_length
        r += extra if rest.nonzero?
        r
      )
    end

    private

    def get_length_in_bits version
      macro_version =
        case version
        when 1.. 9 then 0
        when  ..26 then 1
        when  ..40 then 2
        else            raise Error, "Unknown version: #{version}"
        end
      self.class::BITS_FOR_MODE[macro_version]
    end


    @sub = []

    class <<self

      def [] *args, **kwargs
        new *args, **kwargs
      end

      def inherited cls
        @sub.push cls
      end

      def create data, mode = nil
        case data
        when String then
          if mode then
            type = @sub.find { |t| mode.to_s == t::NAME }
            type or raise ArgumentError, "Not a valid segment type: #{mode}"
            type.new data
          else
            @sub.each do |t|
              break t.new data
            rescue ArgumentError, NotImplementedError
            end
          end
        when Array then
          Multi.new data
        when Segment
          data
        else
          raise ArgumentError, "Data must be a String, an Array, or a Segment"
        end
      end

    end

  end


  class Multi

    def initialize data
      @segs = data.map! { |s|
        args =
          case s
          when String then s
          when Hash   then [ s[ :data], s[ :mode]]
          end
        Segment.create *args
      }
    end

    def write_to buffer, version
      @segs.each { |s| s.write_to buffer, version }
    end

    def size version
      @segs.sum { |s| s.size version }
    end

  end


  class Numeric < Segment

    NAME          = "number"
    ID            = 1
    BITS_FOR_MODE = [10, 12, 14]

    def initialize data
      data =~ /[^0-9]/ and raise ArgumentError, "Not numeric: #{data}"
      super
    end

    NUMBER_LENGTH = { 3 => 10, 2 => 7, 1 => 4 }

    def write_to buffer, version
      super
      @data.scan /\d{1,3}/ do |chars|
        buffer.put chars.to_i, NUMBER_LENGTH[ chars.length]
      end
    end

    def cbe ; [3, NUMBER_LENGTH[3], NUMBER_LENGTH[ @data.size % 3]||0] ; end

  end

  class Alphanumeric < Segment

    NAME          = "alphanumeric"
    ID            = 2
    BITS_FOR_MODE = [ 9, 11, 13]

    ALPHANUMERIC, = [
      *("0".."9"), *("A".."Z"), " ", "$", "%", "*", "+", "-", ".", "/", ":",
    ].inject [{},0] do |(r,i),e| r[ e] = i ; [r,i+1] end

    def initialize data
      data.each_char { |c|
        ALPHANUMERIC[ c] or raise ArgumentError, "Not alphanumeric uppercase: #{data}"
      }
      super
    end

    def write_to buffer, version
      super
      @data.scan /(.)(.)?/ do |c,d|
        val = ALPHANUMERIC[ c]
        len = 6
        if d then
          val = (val * ALPHANUMERIC.length) + ALPHANUMERIC[ d]
          len += 5
        end
        buffer.put val, len
      end
    end

    def cbe ; [2, 11, 6] ; end

  end

  class Bytes < Segment

    NAME          = "8bit"
    ID            = 4
    BITS_FOR_MODE = [ 8, 16, 16]

    def write_to buffer, version
      super
      @data.each_byte do |b|
        buffer.put b, 8
      end
    end

    def cbe ; [1, 8, 0] ; end

  end

  class Kanji < Segment

    NAME          = "kanji"
    ID            = 8
    BITS_FOR_MODE = [ 8, 10, 12]

    def initialize data
      super
      not_implemented
    end

    def write_to buffer, version
      super
      not_implemented
    end

    def cbe ; not_implemented ; end

    private

    def not_implemented
      raise NotImplementedError, "Not implemented yet. Please contribute."
    end

  end

  class ECI < Segment

    NAME          = "eci"
    ID            = 7
    BITS_FOR_MODE = [ 0, 0, 0]

    def initialize data
      super
      not_implemented
    end

    def write_to buffer, version
      super
      not_implemented
    end

    def cbe ; not_implemented ; end

    private

    def not_implemented
      raise NotImplementedError, "Not implemented yet. Please contribute."
    end

  end

end

