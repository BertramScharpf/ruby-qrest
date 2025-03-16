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
        version <= Modules::MAX_VERSION or
          raise ArgumentError, "Requested version exceeds maximum of #{Modules::MAX_VERSION}"
      else
        if max_version then
          max_version <= Modules::MAX_VERSION or
            raise ArgumentError, "Maximum posible version is #{Modules::MAX_VERSION}"
        else
          max_version = Modules::MAX_VERSION
        end
        mb = Modules::MAXBITS[error_correct_level]
        version = 0
        begin
          version += 1
          version <= max_version or
            raise Error, "Data length exceeds maximum capacity of version #{max_version}"
        end until (input.size version) <= mb[version - 1]
      end

      data = (RSBlocks.get version, error_correct_level).create_data input
      @modules = Modules.create_best data, version, error_correct_level
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

