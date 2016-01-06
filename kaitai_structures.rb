module KaitaiStructures
  def ensure_fixed_contents(size, expected)
    actual = @_io.read(size).bytes
    if actual != expected
      raise "Unexpected fixed contents: got #{actual.inspect}, was waiting for #{expected.inspect}"
    end
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

  def read_u8le
    @_io.read(8).unpack('Q')[0]
  end

  def read_u2be
    @_io.read(2).unpack('n')[0]
  end

  def read_u4be
    @_io.read(4).unpack('N')[0]
  end

  # ========================================================================
  # Signed
  # ========================================================================

  def read_s1
    @_io.read(1).unpack('c')[0]
  end

  def read_s2le
    @_io.read(2).unpack('v')[0]
  end

  def read_s4le
    @_io.read(4).unpack('V')[0]
  end

  def read_s8le
    @_io.read(8).unpack('q')[0]
  end

  def read_s2be
    @_io.read(2).unpack('n')[0]
  end

  def read_s4be
    @_io.read(4).unpack('N')[0]
  end

  # ========================================================================

  def read_str_byte_limit(byte_size, encoding)
    @_io.read(byte_size).force_encoding(encoding)
  end
end
