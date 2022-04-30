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
    subject(:stream) { described_class.new(head_proc, nil) }

    let(:dummy) do
      Class.new do
        attr_accessor :mutated

        def initialize
          @mutated = false
        end
      end.new
    end

    let(:head_proc) do
      Proc.new { dummy.mutated = true; "hello" }
    end

    it "executes the given proc" do
      expect { stream.head }.to change { dummy.mutated }.from(false).to(true)
      expect(stream.head).to eq("hello")
    end
  end

  describe "#tail" do
    subject(:stream) { described_class.new(nil, tail_proc) }

    let(:dummy) do
      Class.new do
        attr_accessor :mutated

        def initialize
          @mutated = false
        end
      end.new
    end

    let(:tail_proc) do
      Proc.new { dummy.mutated = true; "world" }
    end

    it "executes the given proc" do
      expect { stream.tail }.to change { dummy.mutated }.from(false).to(true)
      expect(stream.tail).to eq("world")
    end
  end
end
