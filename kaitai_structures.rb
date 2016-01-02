module KaitaiStructures
  def ensure_fixed_contents(size, expected)
    actual = @f.read(size).bytes
    if actual != expected
      raise "Unexpected fixed contents: got #{actual.inspect}, was waiting for #{expected.inspect}"
    end
  end

  def read_u1
    @f.read(1).unpack('C')[0]
  end

  def read_u4le
    @f.read(4).unpack('N')[0]
  end

  def read_u8le
    @f.read(8).unpack('Q')[0]
  end

  def read_u4be
    @f.read(4).unpack('V')[0]
  end
end
