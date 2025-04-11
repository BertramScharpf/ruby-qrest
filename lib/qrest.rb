#
#  qrest.rb  --  QR code library
#

require "qrest/base"
require "qrest/version"
require "qrest/segment"
require "qrest/rsblocks"
require "qrest/modules"


module QRest

  class Code

    class <<self
      alias [] new
    end

    attr_reader :modules

    def initialize input, *more, level: nil, max_version: nil, mode: nil, version: nil
      input = [ input, *more] if not more.empty? or Hash === input
      input = Segment.create input, mode
      level ||= :h
      error_correct_level = level.downcase.to_sym
      Modules::ERRORCORRECTLEVEL[error_correct_level] or
        raise ArgumentError, "Unknown error correction level: #{level}"
      if version then
        Modules::VERSIONS.include? version or
          raise ArgumentError, "Requested version not in #{Modules::VERSIONS}"
      else
        if max_version then
          Modules::VERSIONS.include? max_version or
            raise ArgumentError, "Maximum version mot in #{Modules::VERSIONS}"
        else
          max_version = Modules::VERSIONS.end
        end
        mb = Modules::MAXBITS[error_correct_level]
        version = Modules::VERSIONS.find { |v|
          v <= max_version or
            raise Error, "Data length exceeds requested maximum version of #{max_version}"
            (input.size v) <= mb[ v - 1]
        }
      end
      data = RSData.new version, error_correct_level, input
      @modules = Modules.create_best data
    end

    def to_s dark: nil, light: nil, quiet_size: nil
      @modules.to_s dark: dark, light: light, quiet_size: quiet_size
    end

    def method_missing sym, *args, **kwargs, &block
      if @modules.respond_to? sym then
        @modules.send sym, *args, **kwargs, &block
      else
        super
      end
    end

  end

end

