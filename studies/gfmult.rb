require "qrest"
include QRest

def qr_mult x, y
  xl = Polynomial.gflog x
  yl = Polynomial.gflog y
  Polynomial.gfexp xl + yl
end
(100..110).map { |x|
  (100..110).map { |y|
    q = qr_mult x, y
  }
}


def raise_byte w
  w <<= 1
  w_ = w
  w_ &= 0xff
  w_ ^= 0x1d if w_ != w
  w_
end
(0...256).map { |i| raise_byte i }

def mult x, y
  mult_acc 0, x, y
end
def mult_acc a, x, y
  if x.zero? then
    a
  else
    x_ = x >> 1
    y_ = raise_byte y
    r = x.even? ? 0 : y
    mult_acc (a ^ r), x_, y_
  end
end
(100..110).map { |x|
  (100..110).map { |y|
    p = mult x, y
  }
}

def mult x, y
  a = 0
  until x.zero? do
    r = x.even? ? 0 : y
    x >>= 1
    y = raise_byte y
    a ^= r
  end
  a
end
(100..110).map { |x|
  (100..110).map { |y|
    p = mult x, y
  }
}


def mult x, y
  a = 0
  until x.zero? do
    r = x.even? ? 0 : y
    x >>= 1
    # ---
    z = (y & 0x80).zero?
    y <<= 1
    y &= 0xff
    y ^= 0x1d unless z
    # ---
    a ^= r
  end
  a
end
(100..110).map { |x|
  (100..110).map { |y|
    p = mult x, y
  }
}





(1..255).each { |x|
  (1..255).each { |y|
    q = qr_mult x, y
    p = mult x, y
    raise "D'oh! x=#{x} y=#{y} p=#{p} q=#{q}" if p != q
  }
}
:success



100.times { |i|
  e = Polynomial.error_correct i
  puts e.inspect
}


require "qrest"
include QRest
$debug = true
p = Polynomial.new (65..90).to_a
(20..36).map { |c|
  (p.error_mod c).num
}

