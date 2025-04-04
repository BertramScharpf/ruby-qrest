# Ruby-QRest

A library for generating QR Codes in pure and true Ruby.

*Keep the classes small,\
Methods short and readable.\
Tests suites can't do that.*


## Installation

```ruby
gem install qrest
```

(In case you are using [Neovim](https://github.com/neovim/neovim), you may like
to execute the commands below inside the editor; please see
[Ruby-Nvim](https://github.com/BertramScharpf/ruby-nvim#calling-the-ruby-interface)
for an example.)


## Basic Usage

```ruby
require "qrest"
qr = QRest::Code.new "https://example.com"
puts qr.to_s
```

Show it on the console:

```ruby
design = {
  dark:       "\e[30;40mXX\e[m",
  light:      "\e[37;47m  \e[m",
  quiet_size: 4,
}
puts qr.to_s **design
```

If you use [Tmux](https://tmux.github.io) you might prefer
to do this in the editor:

```ruby
IO.popen %w(tmux load-buffer -), "w" do |pipe|
  pipe.puts qr.to_s **design
end
```

Then open a new pane and say:

```sh
tmux save-buffer -
```


### Pixel graphics

```ruby
require "qrest/formats/xpm"
File.open "example.xpm", "w" do |f|
  qr.xpm pixels: 1, quiet_size: 2, output: f
end
```

For other formats, pipe the output to
[ImageMagick](https://imagemagick.org).

```ruby
require "qrest/formats/xpm"
IO.popen [ "convert", "-", "example.png"], "w" do |p|
  qr.xpm output: p
end
```


### Embedded PostScript

```ruby
require "qrest/formats/eps"
File.open "example.eps", "w" do |f|
  qr.eps output: f
end
```

As PostScript images can freely be scaled, there is no such thing as a size or a
dimension parameter.


### SVG for Web pages

```ruby
require "qrest/formats/svg"
File.open "example.svg", "w" do |f|
  qr.svg dimen: "132px", title: "example.com", id: "url_example", output: f
end
```

Here's an example how to embed it into your HTML page:

```ruby
require "qrest/formats/svg"
path = File.expand_path "~/public_html/example.html"
File.open path, "w" do |f|
  qr.html output: f
end
```


## Multiple Encoding Support

```ruby
require "qrest"
qr = QRest::Code[
  {data: "299792458",        mode: "number"      },
  {data: "THX 1138",         mode: "alphanumeric"},
  {data: "tränenüberströmt", mode: "8bit"        },
]
```


## Copyright

  * (C) 2025 Bertram Scharpf <software@bertram-scharpf.de>
  * License: [BSD-2-Clause+](./LICENSE)
  * Repository: [ruby-qrest](https://github.com/BertramScharpf/ruby-qrest)

The word "QR Code" is a trademark of [Denso Wave Inc.](https://www.qrcode.com).

Special thanks to:

  * [RQRCodeCore](https://github.com/whomwah/rqrcode_core)
  * [qrcode-generator](https://github.com/kazuhikoarase/qrcode-generator)
  * [qrencode](https://github.com/fukuchi/libqrencode)
  * [qr](https://github.com/pcapriotti/qr)
  * [haskell-qrcode](https://github.com/kizzx2/haskell-qrcode)

