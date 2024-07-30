require 'stringio'

module Kaitai
module Struct

VERSION = '0.11'

##
# Common base class for all structured generated by Kaitai Struct.
# Stores stream object that this object was parsed from in {#_io},
# stores reference to parent structure in {#_parent} and root
# structure in {#_root} and provides a few helper methods.
class Struct

  def initialize(_io, _parent = nil, _root = nil)
    @_io = _io
    @_parent = _parent
    @_root = _root
  end

  ##
  # Factory method to instantiate a Kaitai Struct-powered structure,
  # parsing it from a local file with a given filename.
  # @param filename [String] local file to parse
  def self.from_file(filename)
    self.new(Stream.open(filename))
  end

  ##
  # Implementation of {Object#inspect} to aid debugging (at the very
  # least, to aid exception raising) for KS-based classes. This one
  # uses a bit terser syntax than Ruby's default one, purposely skips
  # any internal fields (i.e. starting with `_`, such as `_io`,
  # `_parent` and `_root`) to reduce confusion, and does no
  # recursivity tracking (as proper general-purpose `inspect`
  # implementation should do) because there are no endless recursion
  # in KS-based classes by design (except for already mentioned
  # internal navigation variables).
  def inspect
    vars = []
    instance_variables.each { |nsym|
      nstr = nsym.to_s

      # skip all internal variables
      next if nstr[0..1] == '@_'

      # strip mandatory `@` at the beginning of the name for brevity
      nstr = nstr[1..-1]

      nvalue = instance_variable_get(nsym).inspect

      vars << "#{nstr}=#{nvalue}"
    }

    "#{self.class}(#{vars.join(' ')})"
  end

  attr_reader :_io, :_parent, :_root
end

##
# Kaitai::Struct::Stream is an implementation of
# {Kaitai Stream API}[https://doc.kaitai.io/stream_api.html] for Ruby.
# It's implemented as a wrapper for generic IO objects.
#
# It provides a wide variety of simple methods to read (parse) binary
# representations of primitive types, such as integer and floating
# point numbers, byte arrays and strings, and also provides stream
# positioning / navigation methods with unified cross-language and
# cross-toolkit semantics.
#
# Typically, end users won't access Kaitai Stream class manually, but
# would describe a binary structure format using .ksy language and
# then would use Kaitai Struct compiler to generate source code in
# desired target language.  That code, in turn, would use this class
# and API to do the actual parsing job.
class Stream
  ##
  # Unused since Kaitai Struct Compiler v0.9+ - compatibility with
  # older versions.
  #
  # Exception class for an error that occurs when some fixed content
  # was expected to appear, but actual data read was different.
  class UnexpectedDataError < Exception
    def initialize(actual, expected)
      super("Unexpected fixed contents: got #{Stream.format_hex(actual)}, " \
            "was waiting for #{Stream.format_hex(expected)}")
      @actual = actual
      @expected = expected
    end
  end


  ##
  # Constructs new Kaitai Stream object.
  # @param arg [String, IO, StringIO, SubIO] if String, it will be used as byte
  #   array to read data from; if IO (or StringIO, or SubIO), if will be used literally
  #   as the source of data
  def initialize(arg)
    if arg.is_a?(String)
      @_io = StringIO.new(arg)
    elsif arg.is_a?(IO) or arg.is_a?(StringIO) or arg.is_a?(SubIO)
      @_io = arg
    else
      raise TypeError.new('can be initialized with IO, StringIO, SubIO or String only')
    end
    align_to_byte
  end

  ##
  # Convenience method to create a Kaitai Stream object, opening a
  # local file with a given filename.
  # @param filename [String] local file to open
  def self.open(filename)
    self.new(File.open(filename, 'rb:ASCII-8BIT'))
  end

  ##
  # Closes underlying IO object.
  def close
    @_io.close
  end

  # Test endianness of the platform
  @@big_endian = [0x0102].pack('s') == [0x0102].pack('n')

  # @!group Stream positioning

  ##
  # Check if stream pointer is at the end of stream.
  # @return [true, false] true if we are located at the end of the stream
  def eof?; @_io.eof? and @bits_left == 0; end

  ##
  # Set stream pointer to designated position.
  # @param x [Fixnum] new position (offset in bytes from the beginning of the stream)
  def seek(x); @_io.seek(x); end

  ##
  # Get current position of a stream pointer.
  # @return [Fixnum] pointer position, number of bytes from the beginning of the stream
  def pos; @_io.pos; end

  ##
  # Get total size of the stream in bytes.
  # @return [Fixnum] size of the stream in bytes
  def size; @_io.size; end

  # @!endgroup

  # @!group Integer numbers

  # ------------------------------------------------------------------------
  # Signed
  # ------------------------------------------------------------------------

  def read_s1
    read_bytes(1).unpack('c')[0]
  end

  # ........................................................................
  # Big-endian
  # ........................................................................

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

  # ........................................................................
  # Little-endian
  # ........................................................................

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

  # ------------------------------------------------------------------------
  # Unsigned
  # ------------------------------------------------------------------------

  def read_u1
    read_bytes(1).unpack('C')[0]
  end

  # ........................................................................
  # Big-endian
  # ........................................................................

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

  # ........................................................................
  # Little-endian
  # ........................................................................

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

  # @!endgroup

  # @!group Floating point numbers

  # ------------------------------------------------------------------------
  # Big-endian
  # ------------------------------------------------------------------------

  def read_f4be
    read_bytes(4).unpack('g')[0]
  end

  def read_f8be
    read_bytes(8).unpack('G')[0]
  end

  # ------------------------------------------------------------------------
  # Little-endian
  # ------------------------------------------------------------------------

  def read_f4le
    read_bytes(4).unpack('e')[0]
  end

  def read_f8le
    read_bytes(8).unpack('E')[0]
  end

  # @!endgroup

  # @!group Unaligned bit values

  def align_to_byte
    @bits_left = 0
    @bits = 0
  end

  def read_bits_int_be(n)
    res = 0

    bits_needed = n - @bits_left
    @bits_left = -bits_needed % 8

    if bits_needed > 0
      # 1 bit  => 1 byte
      # 8 bits => 1 byte
      # 9 bits => 2 bytes
      bytes_needed = ((bits_needed - 1) / 8) + 1 # `ceil(bits_needed / 8)`
      buf = read_bytes(bytes_needed)
      buf.each_byte { |byte|
        res = res << 8 | byte
      }

      new_bits = res
      res = res >> @bits_left | @bits << bits_needed
      @bits = new_bits # will be masked at the end of the function
    else
      res = @bits >> -bits_needed # shift unneeded bits out
    end

    mask = (1 << @bits_left) - 1 # `@bits_left` is in range 0..7
    @bits &= mask

    res
  end

  # Unused since Kaitai Struct Compiler v0.9+ - compatibility with
  # older versions.
  def read_bits_int(n)
    read_bits_int_be(n)
  end

  def read_bits_int_le(n)
    res = 0
    bits_needed = n - @bits_left

    if bits_needed > 0 then
      # 1 bit  => 1 byte
      # 8 bits => 1 byte
      # 9 bits => 2 bytes
      bytes_needed = ((bits_needed - 1) / 8) + 1 # `ceil(bits_needed / 8)`
      buf = read_bytes(bytes_needed)
      i = 0
      buf.each_byte { |byte|
        res |= byte << (i * 8)
        i += 1
      }

      new_bits = res >> bits_needed
      res = res << @bits_left | @bits
      @bits = new_bits
    else
      res = @bits
      @bits >>= n
    end

    @bits_left = -bits_needed % 8

    mask = (1 << n) - 1 # no problem with this in Ruby (arbitrary precision integers)
    res &= mask
    return res
  end

  # @!endgroup

  # @!group Byte arrays

  ##
  # Reads designated number of bytes from the stream.
  # @param n [Fixnum] number of bytes to read
  # @return [String] read bytes as byte array
  # @raise [EOFError] if there were less bytes than requested
  #   available in the stream
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

  ##
  # Reads all the remaining bytes in a stream as byte array.
  # @return [String] all remaining bytes in a stream as byte array
  def read_bytes_full
    @_io.read
  end

  def read_bytes_term(term, include_term, consume_term, eos_error)
    term_byte = term.chr
    r = ''
    loop {
      c = @_io.getc
      if c.nil?
        if eos_error
          raise EOFError.new("end of stream reached, but no terminator #{term} found")
        end

        return r
      end
      if c == term_byte
        r << c if include_term
        @_io.seek(@_io.pos - 1) unless consume_term
        return r
      end
      r << c
    }
  end

  ##
  # Unused since Kaitai Struct Compiler v0.9+ - compatibility with
  # older versions.
  #
  # Reads next len bytes from the stream and ensures that they match
  # expected fixed byte array. If they differ, throws a
  # {UnexpectedDataError} runtime exception.
  # @param expected [String] contents to be expected
  # @return [String] read bytes as byte array, which are guaranteed to
  #   equal to expected
  # @raise [UnexpectedDataError]
  def ensure_fixed_contents(expected)
    len = expected.bytesize
    actual = @_io.read(len)
    raise UnexpectedDataError.new(actual, expected) if actual != expected
    actual
  end

  def self.bytes_strip_right(bytes, pad_byte)
    new_len = bytes.length
    while new_len > 0 and bytes.getbyte(new_len - 1) == pad_byte
      new_len -= 1
    end

    bytes[0, new_len]
  end

  def self.bytes_terminate(bytes, term, include_term)
    term_index = bytes.index(term.chr)
    if term_index.nil?
      bytes.dup
    else
      bytes[0, term_index + (include_term ? 1 : 0)]
    end
  end

  # @!endgroup

  # @!group Byte array processing

  ##
  # Performs a XOR processing with given data, XORing every byte of
  # input with a single given value. Uses pure Ruby implementation suggested
  # by [Thomas Leitner](https://github.com/gettalong), borrowed from
  # https://github.com/fny/xorcist/blob/master/bin/benchmark
  # @param data [String] data to process
  # @param key [Fixnum] value to XOR with
  # @return [String] processed data
  def self.process_xor_one(data, key)
    out = data.dup
    i = 0
    max = data.length
    while i < max
      out.setbyte(i, data.getbyte(i) ^ key)
      i += 1
    end
    out
  end

  ##
  # Performs a XOR processing with given data, XORing every byte of
  # input with a key array, repeating key array many times, if
  # necessary (i.e. if data array is longer than key array).
  # Uses pure Ruby implementation suggested by
  # [Thomas Leitner](https://github.com/gettalong), borrowed from
  # https://github.com/fny/xorcist/blob/master/bin/benchmark
  # @param data [String] data to process
  # @param key [String] array of bytes to XOR with
  # @return [String] processed data
  def self.process_xor_many(data, key)
    out = data.dup
    kl = key.length
    ki = 0
    i = 0
    max = data.length
    while i < max
      out.setbyte(i, data.getbyte(i) ^ key.getbyte(ki))
      ki += 1
      ki = 0 if ki >= kl
      i += 1
    end
    out
  end

  ##
  # Performs a circular left rotation shift for a given buffer by a
  # given amount of bits, using groups of groupSize bytes each
  # time. Right circular rotation should be performed using this
  # procedure with corrected amount.
  # @param data [String] source data to process
  # @param amount [Fixnum] number of bits to shift by
  # @param group_size [Fixnum] number of bytes per group to shift
  # @return [String] copy of source array with requested shift applied
  def self.process_rotate_left(data, amount, group_size)
    raise NotImplementedError.new("unable to rotate group #{group_size} bytes yet") unless group_size == 1

    mask = group_size * 8 - 1
    anti_amount = -amount & mask

    # NB: actually, left bit shift (<<) in Ruby would have required
    # truncation to type_bits size (i.e. something like "& 0xff" for
    # group_size == 8), but we can skip this one, because later these
    # number would be packed with Array#pack, which will do truncation
    # anyway

    data.bytes.map { |x| (x << amount) | (x >> anti_amount) }.pack('C*')
  end

  # @!endgroup

  ##
  # Reserves next n bytes from current stream as a
  # Kaitai::Struct::Stream substream. Substream has its own pointer
  # and addressing in the range of [0, n) bytes. This stream's pointer
  # is advanced to the position right after this substream.
  # @param n [Fixnum] number of bytes to reserve for a substream
  # @return [Stream] substream covering n bytes from the current
  #   position
  def substream(n)
    sub = Stream.new(SubIO.new(@_io, @_io.pos, n))
    @_io.seek(@_io.pos + n)
    sub
  end

  ##
  # Resolves value using enum: if the value is not found in the map,
  # we'll just use literal value per se.
  def self.resolve_enum(enum_map, value)
    enum_map[value] || value
  end

  # ========================================================================

  private
  SIGN_MASK_16 = (1 << (16 - 1))
  SIGN_MASK_32 = (1 << (32 - 1))
  SIGN_MASK_64 = (1 << (64 - 1))

  def to_signed(x, mask)
    (x & ~mask) - (x & mask)
  end

  def self.format_hex(bytes)
    bytes.unpack('H*')[0].gsub(/(..)/, '\1 ').chop
  end

  ###
  # Guess if the given args are most likely byte arrays.
  # <p>
  # There's no way to know for sure, but {@code Encoding::ASCII_8BIT} is a special encoding that is
  # usually used for a byte array(/string), not a character string. For those reasons, that encoding
  # is NOT planned to be allowed for human readable texts by KS in general as well.
  # </p>
  # @param args [...] Something to check.
  # @see <a href="https://ruby-doc.org/core-3.0.0/Encoding.html">Encoding</a>
  # @see <a href="https://github.com/kaitai-io/kaitai_struct/issues/116">List of supported encodings</a>
  #
  def self.is_byte_array?(*args)
    args.all? { |arg| arg.is_a?(String) and (arg.encoding == Encoding::ASCII_8BIT) }
  end

  def self.inspect_values(*args)
    reprs = args.map { |arg|
      if Stream.is_byte_array?(arg)
        "[#{Stream.format_hex(arg)}]"
      else
        arg.inspect
      end
    }
    reprs.length == 1 ? reprs[0] : reprs
  end
end

##
# Substream IO implementation: a IO object which wraps existing IO object
# and provides similar byte/bytes reading functionality, but only for a
# limited set of bytes starting from specified offset and spanning up to
# specified length.
class SubIO
  ##
  # Parent IO object that this substream is projecting data from.
  attr_reader :parent_io

  ##
  # Offset of start of substream in coordinates of parent stream. In
  # coordinates of substream itself start will be always 0.
  attr_reader :parent_start

  ##
  # Size of substream in bytes.
  attr_reader :size

  ##
  # Current position in a substream. Independent from a position in a
  # parent IO.
  attr_reader :pos

  def initialize(parent_io, parent_start, size)
    @parent_io = parent_io
    @parent_start = parent_start
    @size = size
    @pos = 0
    @closed = false
  end

  def eof?
    raise IOError.new("closed stream") if @closed

    @pos >= @size
  end

  def seek(amount, whence = IO::SEEK_SET)
    raise IOError.new("closed stream") if @closed
    raise ArgumentError.new("Anything but IO::SEEK_SET is not supported in SubIO::seek") if whence != IO::SEEK_SET
    raise TypeError.new("Need an integer argument for amount in SubIO::seek") unless amount.respond_to?(:to_int)
    raise Errno::EINVAL.new("Negative position requested") if amount < 0
    @pos = amount.to_int
    return 0
  end

  def getc
    raise IOError.new("closed stream") if @closed

    return nil if @pos >= @size

    # remember position in parent IO
    old_pos = @parent_io.pos
    @parent_io.seek(@parent_start + @pos)
    res = @parent_io.getc
    @pos += 1

    # restore position in parent IO
    @parent_io.seek(old_pos)

    res
  end

  def read(len = nil)
    raise IOError.new("closed stream") if @closed

    # remember position in parent IO
    old_pos = @parent_io.pos

    # read until the end of substream
    if len.nil?
      len = @size - @pos
      return "" if len < 0
    else
      # special case to requesting exactly 0 bytes
      return "" if len == 0

      # cap intent to read if going beyond substream boundary
      left = @size - @pos

      # if actually requested reading and we're beyond the boundary, return nil
      return nil if left <= 0

      # otherwise, still return something, but less than requested
      len = left if len > left
    end

    @parent_io.seek(@parent_start + @pos)
    res = @parent_io.read(len)
    read_len = res.size
    @pos += read_len

    # restore position in parent IO
    @parent_io.seek(old_pos)

    res
  end

  def close
    @closed = true
  end
end

##
# Common ancestor for all error originating from Kaitai Struct usage.
# Stores KSY source path, pointing to an element supposedly guilty of
# an error.
class KaitaiStructError < Exception
  def initialize(msg, src_path)
    super("#{src_path}: #{msg}")
    @src_path = src_path
  end
end

##
# Error that occurs when default endianness should be decided with
# a switch, but nothing matches (although using endianness expression
# implies that there should be some positive result).
class UndecidedEndiannessError < KaitaiStructError
  def initialize(src_path)
    super("unable to decide on endianness for a type", src_path)
  end
end

##
# Common ancestor for all validation failures. Stores pointer to
# KaitaiStream IO object which was involved in an error.
class ValidationFailedError < KaitaiStructError
  def initialize(msg, io, src_path)
    super("at pos #{io.pos}: validation failed: #{msg}", src_path)
    @io = io
  end
end

##
# Signals validation failure: we required "actual" value to be equal to
# "expected", but it turned out that it's not.
class ValidationNotEqualError < ValidationFailedError
  def initialize(expected, actual, io, src_path)
    expected_repr, actual_repr = Stream.inspect_values(expected, actual)
    super("not equal, expected #{expected_repr}, but got #{actual_repr}", io, src_path)

    @expected = expected
    @actual = actual
  end
end

##
# Signals validation failure: we required "actual" value to be greater
# than or equal to "min", but it turned out that it's not.
class ValidationLessThanError < ValidationFailedError
  def initialize(min, actual, io, src_path)
    min_repr, actual_repr = Stream.inspect_values(min, actual)
    super("not in range, min #{min_repr}, but got #{actual_repr}", io, src_path)
    @min = min
    @actual = actual
  end
end

##
# Signals validation failure: we required "actual" value to be less
# than or equal to "max", but it turned out that it's not.
class ValidationGreaterThanError < ValidationFailedError
  def initialize(max, actual, io, src_path)
    max_repr, actual_repr = Stream.inspect_values(max, actual)
    super("not in range, max #{max_repr}, but got #{actual_repr}", io, src_path)
    @max = max
    @actual = actual
  end
end

##
# Signals validation failure: we required "actual" value to be any of
# the given list, but it turned out that it's not.
class ValidationNotAnyOfError < ValidationFailedError
  def initialize(actual, io, src_path)
    actual_repr = Stream.inspect_values(actual)
    super("not any of the list, got #{actual_repr}", io, src_path)
    @actual = actual
  end
end

##
# Signals validation failure: we required "actual" value to match
# the expression, but it turned out that it doesn't.
class ValidationExprError < ValidationFailedError
  def initialize(actual, io, src_path)
    actual_repr = Stream.inspect_values(actual)
    super("not matching the expression, got #{actual_repr}", io, src_path)
    @actual = actual
  end
end

end
end
