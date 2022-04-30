RSpec.describe Stream do
  describe "#emit" do
    subject(:stream) { described_class.emit(value) }

    let(:value) { "hello" }

    it "produces a stream with a single value" do
      expect(stream.head).to eq(value)
      expect(stream.tail.empty?).to eq(true)
    end
  end

  describe "#emits" do
    subject(:stream) { described_class.emits(enumerable) }

    context "when the enumerable is empty" do
      let(:enumerable) { [] }

      it "returns an empty stream" do
        expect(stream.empty?).to eq(true)
      end
    end

    context "when the enumerable has values" do
      let(:enumerable) { [1, 2, 3] }

      it "returns a stream emitting those values" do
        expect(stream.to_a).to eq([1, 2, 3])
      end
    end

    context "when the enumerable has many values" do
      let(:enumerable) { 1..100000 }

      it "wraps the enumerable and does not overflow the stack" do
        pointer = stream
        expected_value = 1

        until pointer.empty?
          expect(pointer.head).to eq(expected_value)

          pointer = pointer.tail
          expected_value += 1
        end

        expect(expected_value).to eq(100001)
      end
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
    subject(:stream) { described_class.emits([1, 2]) }

    it "returns true when the stream runs out of values" do
      expect(stream.empty?).to eq(false)
      expect(stream.tail.empty?).to eq(false)
      expect(stream.tail.tail.empty?).to eq(true)
    end
  end

  describe "#+" do
    subject(:stream) { stream_1 + stream_2 + stream_3 }

    let(:stream_1) { described_class.emit(1) }
    let(:stream_2) { described_class.emit(2) }
    let(:stream_3) { described_class.emit(3) }

    it "returns the streams concatenated" do
      expect(stream.to_a).to eq([1, 2, 3])
    end
  end

  describe "#to_a" do
    subject(:array) { stream.to_a }

    let(:stream) { Stream.emits([1, 2, 3]) }

    it "converts the stream to an array" do
      expect(array).to eq([1, 2, 3])
    end
  end

  describe "#flat_map" do
    subject(:transformed_stream) { stream.flat_map { |x| x * 2 } }

    context "with an already flat stream" do
      let(:stream) { Stream.emits([1, 2]) }

      it "returns a flat stream with the function applied" do
        expect(transformed_stream.to_a).to eq([2, 4])
      end
    end

    context "with nested streams" do
      let(:stream) { Stream.emits([Stream.emits([1, 2]), Stream.emits([3, 4]), 5]) }

      it "returns a flat stream with the function applied" do
        expect(transformed_stream.to_a).to eq([2, 4, 6, 8, 10])
      end

      context "when the first element is not a stream" do
        let(:stream) { Stream.emits([1, Stream.emits([2, 3]), Stream.emit(4), 5]) }

        it "returns a flat stream with the function applied" do
          expect(transformed_stream.to_a).to eq([2, 4, 6, 8, 10])
        end
      end
    end
  end
end
