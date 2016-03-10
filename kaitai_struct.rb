require 'stringio'

class KaitaiStruct
  def initialize(_io, _parent = nil, _root = self)
    @_io = _io
    @_parent = _parent
    @_root = _root
  end

  def self.from_file(filename)
    self.new(KaitaiStream.open(filename))
  end

  attr_reader :_io
end

class KaitaiStream
  def initialize(arg)
    if arg.is_a?(String)
      @_io = StringIO.new(arg)
    elsif arg.is_a?(IO)
      @_io = arg
    else
      raise TypeError.new('can be initialized with IO or String only')
    end
  end

  def self.open(filename)
    self.new(File.open(filename, 'rb:ASCII-8BIT'))
  end

  # ========================================================================
  # Forwarding of IO API calls
  # ========================================================================

  def eof?; @_io.eof?; end
  def seek(x); @_io.seek(x); end

  # Test endianness of the platform
  @@big_endian = [0x0102].pack('s') == [0x0102].pack('n')

  def ensure_fixed_contents(size, expected)
    buf = @_io.read(size)
    actual = buf.bytes
    if actual != expected
      raise "Unexpected fixed contents: got #{actual.inspect}, was waiting for #{expected.inspect}"
    end
    buf
  end

  # ========================================================================
  # Unsigned
  # ========================================================================

  def read_u1
    read_bytes(1).unpack('C')[0]
  end

  def read_u2le
    read_bytes(2).unpack('v')[0]
  end

  def read_u4le
    read_bytes(4).unpack('V')[0]
  end

  unless @@big_endian
    def read_u8le
      read_bytes(8).unpack('Q')[0]
    end
  else
    def read_u8le
      a, b = read_bytes(8).unpack('VV')
      (b << 32) + a
    end
  end

  def read_u2be
    read_bytes(2).unpack('n')[0]
  end

  def read_u4be
    read_bytes(4).unpack('N')[0]
  end

  if @@big_endian
    def read_u8be
      read_bytes(8).unpack('Q')[0]
    end
  else
    def read_u8be
      a, b = read_bytes(8).unpack('NN')
      (a << 32) + b
    end
  end

  # ========================================================================
  # Signed
  # ========================================================================

  def read_s1
    read_bytes(1).unpack('c')[0]
  end

  def read_s2le
    to_signed(read_u2le, SIGN_MASK_16)
  end

  def read_s4le
    to_signed(read_u4le, SIGN_MASK_32)
  end

  unless @@big_endian
    def read_s8le
      read_bytes(8).unpack('q')[0]
    end
  else
    def read_s8le
      to_signed(read_u8le, SIGN_MASK_64)
    end
  end

  def read_s2be
    to_signed(read_u2be, SIGN_MASK_16)
  end

  def read_s4be
    to_signed(read_u4be, SIGN_MASK_32)
  end

  if @@big_endian
    def read_s8be
      read_bytes(8).unpack('q')[0]
    end
  else
    def read_s8be
      to_signed(read_u8be, SIGN_MASK_64)
    end
  end

  # ========================================================================

  def read_bytes_full
    @_io.read
  end

  def read_bytes(n)
    r = @_io.read(n)
    if r
      rl = r.bytesize
    else
      rl = 0
    end
    raise EOFError.new("attempted to read #{n} bytes, got only #{rl}") if rl < n
    r
  end

  # ========================================================================

  def read_str_byte_limit(byte_size, encoding)
    read_bytes(byte_size).force_encoding(encoding)
  end

  def read_strz(encoding, term, include_term, consume_term, eos_error)
    r = ''
    loop {
      if @_io.eof?
        if eos_error
          raise "End of stream reached, but no terminator #{term} found"
        else
          return r.force_encoding(encoding)
        end
      end
      c = @_io.getc
      if c.ord == term
        r << c if include_term
        @_io.seek(@_io.pos - 1) unless consume_term
        return r.force_encoding(encoding)
      end
      r << c
    }
  end

  private
  SIGN_MASK_16 = (1 << (16 - 1))
  SIGN_MASK_32 = (1 << (32 - 1))
  SIGN_MASK_64 = (1 << (64 - 1))

  def to_signed(x, mask)
    (x & ~mask) - (x & mask)
  end
end