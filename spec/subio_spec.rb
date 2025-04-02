require 'kaitai/struct/struct'
require 'stringio'

RSpec.describe Kaitai::Struct::SubIO do
  context "in 12345 asking for 234" do
    before(:each) do
      parent_io = StringIO.new("12345")
      @io = Kaitai::Struct::SubIO.new(parent_io, 1, 3)
      @normal_io = StringIO.new("234")
    end

    describe "#seek" do
      it "can seek to 0" do
        expect(@normal_io.seek(0)).to eq(0)
        expect(@io.seek(0)).to eq(0)

        expect(@normal_io.pos).to eq(0)
        expect(@io.pos).to eq(0)
      end

      it "can seek to 2" do
        expect(@normal_io.seek(2)).to eq(0)
        expect(@io.seek(2)).to eq(0)

        expect(@normal_io.pos).to eq(2)
        expect(@io.pos).to eq(2)
      end

      it "can seek to 10 (beyond EOF)" do
        expect(@normal_io.seek(10)).to eq(0)
        expect(@io.seek(10)).to eq(0)

        expect(@normal_io.pos).to eq(10)
        expect(@io.pos).to eq(10)
      end

      it "cannot seek to -1" do
        expect { @normal_io.seek(-1) }.to raise_error(Errno::EINVAL)
        expect { @io.seek(-1) }.to raise_error(Errno::EINVAL)
      end

      it "cannot seek to \"foo\"" do
        expect { @normal_io.seek("foo") }.to raise_error(TypeError)
        expect { @io.seek("foo") }.to raise_error(TypeError)
      end

      it "can seek to 2.3" do
        expect(@normal_io.seek(2.3)).to eq(0)
        expect(@io.seek(2.3)).to eq(0)

        expect(@normal_io.pos).to eq(2)
        expect(@io.pos).to eq(2)
      end
    end

    describe "#pos" do
      it "returns 0 by default" do
        expect(@normal_io.pos).to eq(0)
        expect(@io.pos).to eq(0)
      end

      it "returns 2 after reading 2 bytes" do
        @normal_io.read(2)
        @io.read(2)

        expect(@normal_io.pos).to eq(2)
        expect(@io.pos).to eq(2)
      end

      it "returns 3 after reading 4 bytes" do
        @normal_io.read(4)
        @io.read(4)

        expect(@normal_io.pos).to eq(3)
        expect(@io.pos).to eq(3)
      end
    end

    describe "#eof?" do
      it "returns false by default" do
        expect(@normal_io.eof?).to eq(false)
        expect(@io.eof?).to eq(false)
      end

      it "returns false after reading 2 bytes" do
        @normal_io.read(2)
        @io.read(2)

        expect(@normal_io.eof?).to eq(false)
        expect(@io.eof?).to eq(false)
      end

      it "returns true after reading 3 bytes" do
        @normal_io.read(3)
        @io.read(3)

        expect(@normal_io.eof?).to eq(true)
        expect(@io.eof?).to eq(true)
      end

      it "returns true after reading 4 bytes" do
        @normal_io.read(4)
        @io.read(4)

        expect(@normal_io.eof?).to eq(true)
        expect(@io.eof?).to eq(true)
      end

      it "returns true after seeking at 3 bytes" do
        @normal_io.seek(3)
        @io.seek(3)

        expect(@normal_io.eof?).to eq(true)
        expect(@io.eof?).to eq(true)
      end

      it "returns true after seeking at 10 bytes" do
        @normal_io.seek(10)
        @io.seek(10)

        expect(@normal_io.eof?).to eq(true)
        expect(@io.eof?).to eq(true)
      end
    end

    describe "#read" do
      it "reads 234 with no arguments" do
        expect(@normal_io.read).to eq("234")
        expect(@io.read).to eq("234")
      end

      it "reads 23 when asked to read 2" do
        expect(@normal_io.read(2)).to eq("23")
        expect(@io.read(2)).to eq("23")
      end

      it "reads 234 when asked to read 3" do
        expect(@normal_io.read(3)).to eq("234")
        expect(@io.read(3)).to eq("234")
      end

      it "reads 234 when asked to read 4" do
        expect(@normal_io.read(4)).to eq("234")
        expect(@io.read(4)).to eq("234")
      end

      it "reads 234 when asked to read 10" do
        expect(@normal_io.read(10)).to eq("234")
        expect(@io.read(10)).to eq("234")
      end

      it "reads 234 + empty when asked to read + read" do
        expect(@normal_io.read).to eq("234")
        expect(@io.read).to eq("234")

        expect(@normal_io.read).to eq("")
        expect(@io.read).to eq("")
      end

      it "reads 2 + 34 when asked to read(1) + read" do
        expect(@normal_io.read(1)).to eq("2")
        expect(@io.read(1)).to eq("2")

        expect(@normal_io.read).to eq("34")
        expect(@io.read).to eq("34")
      end

      it "reads 2 + 34 when asked to read(1) + read(2)" do
        expect(@normal_io.read(1)).to eq("2")
        expect(@io.read(1)).to eq("2")

        expect(@normal_io.read(2)).to eq("34")
        expect(@io.read(2)).to eq("34")
      end

      it "reads 2 + 34 when asked to read(1) + read(10)" do
        expect(@normal_io.read(1)).to eq("2")
        expect(@io.read(1)).to eq("2")

        expect(@normal_io.read(10)).to eq("34")
        expect(@io.read(10)).to eq("34")
      end

      context("after seek to EOF") do
        before(:each) do
          @normal_io.seek(3)
          @io.seek(3)
        end

        it "reads nil when asked to read(1)" do
          expect(@normal_io.read(1)).to eq(nil)
          expect(@io.read(1)).to eq(nil)
        end

        it "reads empty when asked to read()" do
          expect(@normal_io.read).to eq("")
          expect(@io.read).to eq("")
        end

        it "reads empty when asked to read(0)" do
          expect(@normal_io.read(0)).to eq("")
          expect(@io.read(0)).to eq("")
        end
      end

      context("after seek beyond EOF") do
        before(:each) do
          @normal_io.seek(10)
          @io.seek(10)
        end

        it "reads nil when asked to read(1)" do
          expect(@normal_io.read(1)).to eq(nil)
          expect(@io.read(1)).to eq(nil)
        end

        it "reads empty when asked to read()" do
          expect(@normal_io.read).to eq("")
          expect(@io.read).to eq("")
        end

        it "reads empty when asked to read(0)" do
          expect(@normal_io.read(0)).to eq("")
          expect(@io.read(0)).to eq("")
        end
      end
    end

    describe "#getc" do
      it 'restores parent pos if parent #getc fails' do
        @io.parent_io.close_read
        expect { @io.getc }.to raise_error(IOError)
        expect(@io.parent_io.pos).to eq(0)
      end
    end
  end
end
