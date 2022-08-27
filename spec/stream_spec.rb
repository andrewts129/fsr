RSpec.describe Stream do
  describe ".emit" do
    context "when given an argument" do
      subject(:stream) { described_class.emit(value) }

      let(:value) { "hello" }
  
      it "produces a stream with a single value" do
        expect(stream.to_a).to eq([value])
      end
    end

    context "when given a block" do
      subject(:stream) do
        described_class.emit do
          hello = "hello"
          world = "world"

          "#{hello} #{world}"
        end
      end

      it "produces a stream with a single value" do
        expect(stream.to_a).to eq(["hello world"])
      end
    end

    context "when given invalid input" do
      context "too many args" do
        subject(:stream) { described_class.emit(1, 2) }

        it "raises an ArgumentError" do
          expect { stream }.to raise_error(ArgumentError)
        end
      end

      context "no args" do
        subject(:stream) { described_class.emit }

        it "raises an ArgumentError" do
          expect { stream }.to raise_error(ArgumentError)
        end
      end

      context "an arg and a block" do
        subject(:stream) { described_class.emit(1) { 2 } }

        it "raises an ArgumentError" do
          expect { stream }.to raise_error(ArgumentError)
        end
      end

      context "multiple args and a block" do
        subject(:stream) { described_class.emit(1, 2) { 3 } }

        it "raises an ArgumentError" do
          expect { stream }.to raise_error(ArgumentError)
        end
      end
    end
  end

  describe ".emits" do
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

  describe ".empty" do
    subject(:stream) { described_class.empty }

    it "returns an empty stream" do
      expect(stream.empty?).to eq(true)
    end
  end

  describe ".concat" do
    subject(:stream) { described_class.concat(stream_1, stream_2) }

    let(:stream_1) { described_class.emits([1, 2]) }
    let(:stream_2) { described_class.emits([3, 4, 5]) }

    it "returns the streams concatenated" do
      expect(stream.to_a).to eq([1, 2, 3, 4, 5])
    end

    context "when adding something to an empty stream" do
      let(:stream_1) { Stream.empty }

      it "returns the streams concatenated" do
        expect(stream.to_a).to eq([3, 4, 5])
      end
    end

    context "when adding an empty stream to something" do
      let(:stream_2) { Stream.empty }

      it "returns the streams concatenated" do
        expect(stream.to_a).to eq([1, 2])
      end
    end

    context "when adding empty streams together" do
      let(:stream_1) { Stream.empty }
      let(:stream_2) { Stream.empty }
      let(:stream_3) { Stream.empty }

      it "returns an empty stream" do
        expect(stream.to_a).to eq([])
      end
    end
  end

  describe "#head" do
    subject(:stream) { described_class.new(emitter) }

    let(:dummy) do
      Class.new do
        attr_accessor :mutated

        def initialize
          @mutated = false
        end
      end.new
    end

    let(:emitter) do
      FSR::Emitter.new("hello", ->(x) { dummy.mutated = true; "#{x} world" }) { nil }
    end

    it "triggers the given emitter" do
      expect { stream.head }.to change { dummy.mutated }.from(false).to(true)
      expect(stream.head).to eq("hello world")
    end
  end

  describe "#tail" do
    subject(:stream) { described_class.new(emitter) }

    let(:dummy) do
      Class.new do
        attr_accessor :mutable_buffer

        def initialize
          @mutable_buffer = "foo"
        end
      end.new
    end

    let(:emitter) do
      FSR::Emitter.new("hello", ->(x) { dummy.mutable_buffer += "boo"; "#{x} world" } ) do |x|
        dummy.mutable_buffer += "bar"; "hello #{x}"
      end
    end

    it "returns a new stream, with the second value of the emitter as the head" do
      tail = nil
      expect { tail = stream.tail }.to change { dummy.mutable_buffer }.from("foo").to("foobar")

      new_head = nil
      expect { new_head = tail.head }.to change { dummy.mutable_buffer }.from("foobar").to("foobarboo")
      expect(new_head).to eq("hello hello world")
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

    context "when adding something to an empty stream" do
      let(:stream_1) { Stream.empty }

      it "returns the streams concatenated" do
        expect(stream.to_a).to eq([2, 3])
      end
    end

    context "when adding an empty stream to something" do
      let(:stream_2) { Stream.empty }

      it "returns the streams concatenated" do
        expect(stream.to_a).to eq([1, 3])
      end
    end

    context "when adding empty streams together" do
      let(:stream_1) { Stream.empty }
      let(:stream_2) { Stream.empty }
      let(:stream_3) { Stream.empty }

      it "returns an empty stream" do
        expect(stream.to_a).to eq([])
      end
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

    context "with singly nested streams" do
      let(:stream) { Stream.emits([1, Stream.emits([2]), Stream.emits([3, 4]), 5]) }

      it "returns a flat stream with the function applied" do
        expect(transformed_stream.to_a).to eq([2, 4, 6, 8, 10])
      end

      context "when the stream wraps another" do
        let(:stream) { Stream.emit(Stream.emits([1, 2, 3])) }

        it "returns the nested stream with the function applied" do
          expect(transformed_stream.to_a).to eq([2, 4, 6])
        end
      end

      context "when the stream wraps an empty stream" do
        let(:stream) { Stream.emit(Stream.empty) }

        it "returns an empty stream" do
          expect(transformed_stream.to_a).to eq([])
        end
      end

      context "when the first element is not a stream" do
        let(:stream) { Stream.emits([1, Stream.emits([2, 3]), Stream.emit(4), 5]) }

        it "returns a flat stream with the function applied" do
          expect(transformed_stream.to_a).to eq([2, 4, 6, 8, 10])
        end
      end
    end

    context "with doubly nested streams" do
      subject(:transformed_stream) { stream.flat_map(&:empty?) }

      let(:stream) { Stream.emit(Stream.emits([Stream.emits([Stream.emit(1), Stream.emit(2)]), Stream.emit(3)])) }

      it "only flattens the top level" do
        expect(transformed_stream.to_a).to eq([false, false])
      end
    end

    context "with an empty stream" do
      let(:stream) { Stream.empty }

      it "does nothing" do
        expect(transformed_stream).to eq(stream)
      end
    end
  end

  describe "#map" do
    subject(:transformed_stream) { stream.flat_map { |x| x - 1 } }

    let(:stream) { Stream.emits([1, 2]) }

    it "returns a stream with the function applied" do
      expect(transformed_stream.to_a).to eq([0, 1])
    end

    context "with an empty stream" do
      let(:stream) { Stream.empty }

      it "returns an empty stream" do
        expect(transformed_stream.to_a).to eq([])
      end
    end
  end

  describe "#flatten" do
    subject(:flattened_stream) { stream.flatten }

    context "with an empty stream" do
      let(:stream) { Stream.empty }

      it "returns another empty stream" do
        expect(flattened_stream.empty?).to eq(true)
      end
    end

    context "with a stream that is already flat" do
      let(:stream) { Stream.emits([1, 2, 3]) }

      it "returns the same stream" do
        expect(flattened_stream.to_a).to eq([1, 2, 3])
      end
    end

    context "with a stream that is nested one layer deep" do
      let(:stream) { Stream.emits([Stream.emits([1, 2]), 3, Stream.emit(4)]) }

      it "returns the flattened stream" do
        expect(flattened_stream.to_a).to eq([1, 2, 3, 4])
      end
    end

    context "with a stream that is nested multiple layers deep" do
      let(:stream) { Stream.emits([Stream.emits([1, Stream.emit(2)]), 3, Stream.emit(4)]) }

      it "returns the stream flattened one level" do
        expect(flattened_stream.head).to eq(1)
        expect(flattened_stream.tail.head.to_a).to eq([2])
        expect(flattened_stream.tail.tail.to_a).to eq([3, 4])
      end
    end
  end

  describe "#each" do
    context "on a non empty stream" do
      subject(:stream) { Stream.emits([1, 2, 3]) }

      it "iterates over each element in order" do
        seen = []

        stream.each do |x|
          seen << x
        end

        expect(seen).to eq([1, 2, 3])
      end
    end

    context "over an empty list" do
      subject(:stream) { Stream.empty }

      it "does not execute the block" do
        expect do
          stream.each do |x|
            raise StandardError(x)
          end
        end.not_to raise_error
      end
    end
  end

  describe "#take" do
    subject(:taken_stream) { stream.take(n) }

    context "when the stream is empty" do
      let(:stream) { Stream.empty }
      let(:n) { 5 }

      it "returns an empty stream" do
        expect(taken_stream.empty?).to eq(true)
      end
    end

    context "when the stream is non-empty" do
      let(:stream) { Stream.emits([1, 2, 3, 4, 5]) }

      context "when n is less than the length of the stream" do
        let(:n) { 3 }
  
        it "returns the first n elements of the stream" do
          expect(taken_stream.to_a).to eq([1, 2, 3])
        end
      end
  
      context "when n is equal to the length of the stream" do
        let(:n) { 5 }
  
        it "returns the entire stream" do
          expect(taken_stream.to_a).to eq([1, 2, 3, 4, 5])
        end
      end
  
      context "when n is greater than the length of the stream" do
        let(:n) { 5 }
  
        it "returns the entire stream" do
          expect(taken_stream.to_a).to eq([1, 2, 3, 4, 5])
        end
      end

      context "when n is zero" do
        let(:n) { 0 }
  
        it "returns an empty stream" do
          expect(taken_stream.empty?).to eq(true)
        end
      end
    end

    context "when given a negative n" do
      let(:stream) { Stream.emit(1) }
      let(:n) { -1 }

      it "raises an ArgumentError" do
        expect { taken_stream }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#drop" do
    subject(:cut_stream) { stream.drop(n) }

    context "when the stream is empty" do
      let(:stream) { Stream.empty }
      let(:n) { 5 }

      it "returns an empty stream" do
        expect(cut_stream.empty?).to eq(true)
      end
    end

    context "when the stream is non-empty" do
      let(:stream) { Stream.emits([1, 2, 3, 4, 5]) }

      context "when n is less than the length of the stream" do
        let(:n) { 3 }
  
        it "returns all but the first n elements of the stream" do
          expect(cut_stream.to_a).to eq([4, 5])
        end
      end
  
      context "when n is equal to the length of the stream" do
        let(:n) { 5 }
  
        it "returns an empty stream" do
          expect(cut_stream.empty?).to eq(true)
        end
      end
  
      context "when n is greater than the length of the stream" do
        let(:n) { 5 }
  
        it "returns an empty stream" do
          expect(cut_stream.empty?).to eq(true)
        end
      end

      context "when n is zero" do
        let(:n) { 0 }
  
        it "returns the same stream" do
          expect(cut_stream.to_a).to eq([1, 2, 3, 4, 5])
        end
      end
    end

    context "when given a negative n" do
      let(:stream) { Stream.emit(1) }
      let(:n) { -1 }

      it "raises an ArgumentError" do
        expect { cut_stream }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#repeat" do
    subject(:repetitive_stream) { stream.repeat }

    context "when the stream is empty" do
      subject(:stream) { Stream.empty }

      it "returns another empty stream" do
        expect(repetitive_stream.empty?).to eq(true)
      end
    end

    context "when the stream is not empty" do
      subject(:stream) { Stream.emits([1, 2]) }

      it "returns an infinitely repeating version of it" do
        expect(repetitive_stream.take(9).to_a).to eq([1, 2, 1, 2, 1, 2, 1, 2, 1])
      end
    end
  end

  describe "#filter" do
    subject(:filtered_stream) { stream.filter { |x| x % 2 == 0 } }

    context "when the stream is empty" do
      let(:stream) { Stream.empty }

      it "returns another empty stream" do
        expect(filtered_stream.empty?).to eq(true)
      end
    end

    context "when the stream is not empty" do
      context "when the first element does not meet the condition" do
        let(:stream) { Stream.emits([1, 2, 3, 4, 5, 6, 7]) }

        it "filters out all the elements that does not meet the condition" do
          expect(filtered_stream.to_a).to eq([2, 4, 6])
        end
      end

      context "when the first element meets the condition" do
        let(:stream) { Stream.emits([2, 3, 4, 5, 6, 7]) }

        it "filters out all the elements that does not meet the condition" do
          expect(filtered_stream.to_a).to eq([2, 4, 6])
        end
      end
    end
  end
end
