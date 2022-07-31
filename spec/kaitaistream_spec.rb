require 'kaitai/struct/struct'
require 'stringio'
require 'fileutils'

RSpec.describe Kaitai::Struct::Stream do
  before(:all) do
    @old_wd = Dir::getwd
    FileUtils::mkdir_p("test_scratch")
    Dir::chdir("test_scratch")
  end

  after(:all) do
    Dir::chdir(@old_wd)
    FileUtils::rm_rf("test_scratch")
  end

  describe '#initialize' do
    it 'can be initialized from String' do
      stream = Kaitai::Struct::Stream.new("12345")
    end

    it 'can be initialized from StringIO' do
      io = StringIO.new("12345")
      stream = Kaitai::Struct::Stream.new(io)
    end

    it 'can be initialized from IO' do
      File.binwrite('test12345.bin', '12345')
      File.open('test12345.bin', 'r') { |f|
        stream = Kaitai::Struct::Stream.new(f)
      }
    end

    it 'cannot be initialized from an integer' do
      expect { Kaitai::Struct::Stream.new(12345) }.to raise_error(TypeError)
    end
  end

  describe '#open' do
    it 'opens existing local file' do
      File.binwrite('test12345.bin', '12345')
      stream = Kaitai::Struct::Stream.open('test12345.bin')
      expect(stream.read_u1).to eq(0x31)
    end
  end

  describe '#close' do
    it 'closes underlying StringIO stream' do
      io = StringIO.new("12345")
      expect(io.closed?).to be false
      stream = Kaitai::Struct::Stream.new(io)
      expect(io.closed?).to be false
      stream.close
      expect(io.closed?).to be true
    end
  end
end
