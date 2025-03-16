#
#  qrest/formats/xpm.rb  --  Build XPM
#

require "qrest/modules"
require "qrest/version"


module QRest

  class Modules

    XPM_D, XPM_L = "X", "."

    def xpm name: nil, pixels: nil, quiet_size: nil, output: nil
      name       ||= QRest::NAME
      name = name[ /[a-z_][a-z_0-9]*/i]
      pixels     ||= 3
      quiet_size ||= 4
      output     ||= ""

      output << <<~EOT
        /* XPM */
        static char * #{name}[] = {
      EOT
      dim = (size + 2*quiet_size)*pixels
      output << <<~EOT
        "#{dim} #{dim} 2 1 0 0 XPMEXT",
      EOT
      output << <<~EOT
        "#{XPM_L}\tc #ffffff",
        "#{XPM_D}\tc #000000",
      EOT
      lines dark: XPM_D*pixels, light: XPM_L*pixels, quiet_size: quiet_size do |l|
        pixels.times { output << "\"#{l}\",\n" }
      end
      output << <<~EOT
        "XPMEXT generator #{QRest::NAME} #{QRest::VERSION}",
        "XPMENDEXT"
        };
      EOT
      output
    end

  end

end

