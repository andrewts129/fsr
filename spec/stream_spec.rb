RSpec.describe Stream do
  describe "#emit" do
    subject(:stream) { described_class.emit(value) }

    let(:value) { "hello" }

    it "produces a stream with a single value" do
      expect(stream.head).to eq(value)
      expect(stream.tail.empty?).to eq(true)
    end
  end

  describe "#head" do
    subject(:stream) { described_class.new(head_func, nil) }

    let(:dummy) do
      Class.new do
        attr_accessor :mutated

        def initialize
          @mutated = false
        end
      end.new
    end

    let(:head_func) do
      lambda { dummy.mutated = true; "hello" }
    end

    it "executes the given func" do
      expect { stream.head }.to change { dummy.mutated }.from(false).to(true)
      expect(stream.head).to eq("hello")
    end
  end

  describe "#tail" do
    subject(:stream) { described_class.new(nil, tail_func) }

    let(:dummy) do
      Class.new do
        attr_accessor :mutated

        def initialize
          @mutated = false
        end
      end.new
    end

    let(:tail_func) do
      lambda { dummy.mutated = true; "world" }
    end

    it "executes the given func" do
      expect { stream.tail }.to change { dummy.mutated }.from(false).to(true)
      expect(stream.tail).to eq("world")
    end
  end

  describe "#empty?" do
    subject(:stream) { described_class.emit(1) }

    it "returns true when the stream runs out of values" do
      expect(stream.empty?).to eq(false)
      expect(stream.tail.empty?).to eq(true)
    end
  end

  describe "#+" do
    subject(:stream) { stream_1 + stream_2 + stream_3 }

    let(:stream_1) { described_class.emit(1) }
    let(:stream_2) { described_class.emit(2) }
    let(:stream_3) { described_class.emit(3) }

    it "returns the streams concatenated" do
      expect(stream.head).to eq(1)
      expect(stream.tail.head).to eq(2)
      expect(stream.tail.tail.head).to eq(3)
      expect(stream.tail.tail.tail.empty?).to eq(true)
    end
  end
end
