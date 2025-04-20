require 'kaitai/struct/struct'
require 'stringio'
require 'socket'
require 'fileutils'

require 'rspec' # normally not needed, but RubyMine doesn't autocomplete RSpec methods without it
require 'rantly'
require 'rantly/rspec_extensions'

# `.dup` is needed in Ruby 1.9, otherwise `RuntimeError: can't modify frozen String` occurs
IS_RUBY_1_9 = Gem::Version.new(RUBY_VERSION.dup) < Gem::Version.new('2.0.0')

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

    it 'can be initialized from File' do
      File.binwrite('test12345.bin', '12345')
      File.open('test12345.bin', 'r') { |f|
        stream = Kaitai::Struct::Stream.new(f)
      }
    end

    it 'can be initialized from TCPSocket' do
      HOST = '127.0.0.1'
      PORT = 26570

      # Start a new TCP server on designated port. This server will only accept one connection and then will cease to listen.
      server = TCPServer.new(HOST, PORT)

      # Run `accept` in a separate thread (as we still need the main thread for client-to-server connection)
      Thread.start do
        s2c_socket = server.accept
        s2c_socket.write('12345')
        s2c_socket.close
        server.close
      end

      # Start client-to-server connection
      c2s_socket = TCPSocket.new(HOST, PORT)

      stream = Kaitai::Struct::Stream.new(c2s_socket)

      # Check that we can read 1 byte integer from a socket
      expect(stream.read_u1).to eq(0x31)

      # Check that we can't seek in a socket IO
      expect { stream.seek(2) }.to raise_error(Errno::ESPIPE)

      expect { stream.read_bytes(5) }.to raise_error(EOFError, 'attempted to read 5 bytes, got only 4')

      c2s_socket.close
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

  describe '#substream' do
    it 'behaves like #read_bytes + Stream#new' do
      prop = property_of do
        len = range(0, 8)
        s = array(len) { range(0, 255) }.pack('C*')
        ops = array(10) do
          sub_len = branch(
            [:range, -2, len + 1],
            [:float, :normal, { center: 1, scale: 4 }],
            :boolean,
            [:string, :digit],
            [:literal, [1, 2]],
            [:literal, nil],
            [:literal, Complex(2, 0)],
            [:literal, Complex(2, 1)]
          )
          # Since Ruby 2.0, we could use `%i[...]` here instead, but at the time
          # of writing we still support Ruby 1.9.
          options = [:enter_subio, :read, :seek].map { |x| [x, [sub_len]] }
          options.concat([:exit_subio, :eof?, :pos, :size, :getc, :close_io].map { |x| [x, []] })

          choose(*options)
        end
        [s, ops]
      end
      prop.check(2000) do |(s, ops)|
        StringIO.open { |logger|
          logger.write("s: #{s.inspect}, length: #{s.bytesize}\n")
          begin
            old_streams = [Kaitai::Struct::Stream.new(StringIO.new(s))]
            new_streams = [Kaitai::Struct::Stream.new(StringIO.new(s))]
            ops.each do |(op, op_args)|
              exec_stream_op(op, op_args, old_streams, new_streams, logger)
            end
          rescue RSpec::Expectations::ExpectationNotMetError, StandardError
            $stderr.write("\n#{logger.string}\n")
            raise
          end
        }
      end
    end

    def exec_stream_op(op, op_args, old_streams, new_streams, logger)
      # NB: intentionally without a newline ("\n")
      logger.write([op, op_args].inspect)
      old_stream = old_streams.last
      new_stream = new_streams.last
      old_io = old_stream.instance_variable_get(:@_io)
      new_io = new_stream.instance_variable_get(:@_io)
      case op
      when :read, :seek, :eof?, :pos, :size, :getc
        status, ret = call_io_method(op, op_args, old_io, new_io)
        case status
        when :ok
          old_res, new_res = ret
          expect(new_res).to eq(old_res)
          logger.write(" -> #{old_res.inspect}\n")
          if old_res.is_a?(String)
            expect(new_res.encoding).to eq(old_res.encoding)
            expect(new_res.frozen?).to eq(old_res.frozen?)
          end
        when :fail
          logger.write(": #{ret.inspect}\n")
        end
      when :enter_subio
        status, ret = call_io_method(:substream, op_args, old_stream, new_stream, :read_bytes)
        case status
        when :ok
          old_res, new_res = ret
          logger.write(": OK\n")
          old_streams << Kaitai::Struct::Stream.new(old_res)
          new_streams << new_res
        when :fail
          logger.write(": #{ret.inspect}\n")
        end
      when :exit_subio
        if old_streams.length > 1
          old_streams.pop.close
          new_streams.pop.close
          logger.write(": OK\n")
        else
          logger.write(": ignored\n")
        end
      when :close_io
        expect(new_stream.close).to eq(old_stream.close)
        logger.write(": OK\n")
      else
        raise "unknown operation #{op.inspect}"
      end
    end

    def call_io_method(method_new, op_args, old_io, new_io, method_old = method_new)
      old_res = old_io.public_send(method_old, *op_args)
    rescue StandardError => old_err
      expected_msg = old_err.message
      if IS_RUBY_1_9 && method_new == :substream && old_err.is_a?(TypeError) && expected_msg =~ /^can't convert (.*)/
        expected_msg = "no implicit conversion of #{Regexp.last_match(1)}"
      end
      expect do
        new_io.public_send(method_new, *op_args)
      end.to raise_error(old_err.class, expected_msg)
      [:fail, old_err]
    else
      new_res = new_io.public_send(method_new, *op_args)
      [:ok, [old_res, new_res]]
    end
  end
end
