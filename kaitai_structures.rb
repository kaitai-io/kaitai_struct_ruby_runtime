module KaitaiStructures
  def ensure_fixed_contents(size, expected)
    actual = @_io.read(size).bytes
    if actual != expected
      raise "Unexpected fixed contents: got #{actual.inspect}, was waiting for #{expected.inspect}"
    end
  end

  def read_u1
    @_io.read(1).unpack('C')[0]
  end

  def read_u4le
    @_io.read(4).unpack('N')[0]
  end

  def read_u8le
    @_io.read(8).unpack('Q')[0]
  end

  def read_u4be
    @_io.read(4).unpack('V')[0]
  end
end
