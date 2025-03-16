#
#  qrest.gemspec  --  Build the Gem
#

$:.unshift File.join (File.dirname __FILE__), "lib"

require "qrest/foreign/supplement"
require "qrest/version"


Gem::Specification.new do |s|
  s.name        = QRest::NAME
  s.version     = QRest::VERSION
  s.authors     = [ "Bertram Scharpf"]
  s.email       = "<software@bertram-scharpf.de>"
  s.homepage    = "https://github.com/BertramScharpf/ruby-qrest.git"
  s.license     = "BSD-2-Clause+"

  s.summary     = "Generate QR Codes"
  s.description = <<~EOF
                    A Ruby library that generates QR Codes
                    as XPM, SVG or EPS graphics.
                  EOF

  s.files         = Dir[ "lib/**/*.rb"] + Dir[ "exe/*"]
  s.require_paths = %w(lib)

  s.bindir        = "bin"
  s.executables = (Dir.new s.bindir).entries! if Dir.exist? s.bindir

  s.required_ruby_version = ">= 3.1.0"
  if false then
    s.add_dependency "supplement", "~> 2.24"
  end
end

