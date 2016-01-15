module KaitaiStructures
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
    @_io.read(1).unpack('C')[0]
  end

  def read_u2le
    @_io.read(2).unpack('v')[0]
  end

  def read_u4le
    @_io.read(4).unpack('V')[0]
  end

  unless @@big_endian
    def read_u8le
      @_io.read(8).unpack('Q')[0]
    end
  else
    def read_u8le
      a, b = @_io.read(8).unpack('VV')
      (b << 32) + a
    end
  end

  def read_u2be
    @_io.read(2).unpack('n')[0]
  end

  def read_u4be
    @_io.read(4).unpack('N')[0]
  end

  if @@big_endian
    def read_u8be
      @_io.read(8).unpack('Q')[0]
    end
  else
    def read_u8be
      a, b = @_io.read(8).unpack('NN')
      (a << 32) + b
    end
  end

  # ========================================================================
  # Signed
  # ========================================================================

  def read_s1
    @_io.read(1).unpack('c')[0]
  end

  def read_s2le
    to_signed(read_u2le, SIGN_MASK_16)
  end

  def read_s4le
    to_signed(read_u4le, SIGN_MASK_32)
  end

  unless @@big_endian
    def read_s8le
      @_io.read(8).unpack('q')[0]
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
      @_io.read(8).unpack('q')[0]
    end
  else
    def read_s8be
      to_signed(read_u8be, SIGN_MASK_64)
    end
  end

  # ========================================================================

  def read_str_byte_limit(byte_size, encoding)
    @_io.read(byte_size).force_encoding(encoding)
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
