RSpec.describe FSR::Emitter do
  describe "#emit" do
    context "when no transformation function is given" do
      subject(:emitter) { described_class.new(42) { nil } }

      it "returns the initial value" do
        expect(emitter.emit).to eq(42)
      end
    end

    context "when a transformation function is given" do
      subject(:emitter) { described_class.new(42, ->(x) { "value: #{x}" }) { nil } }

      it "returns the initial value run through the function" do
        expect(emitter.emit).to eq("value: 42")
      end
    end
  end

  describe "#unfold" do
    subject(:emitter) { described_class.new(42, ->(x) { "---#{x}---" } ) { |x| x + 1 } }

    it "returns a new emitter with the unfold function applied to the initial value" do
      new_emitter = emitter.unfold

      expect(new_emitter).to be_a(described_class)
      expect(new_emitter.emit).to eq("---43---")
    end
  end

  describe "#map" do
    subject(:mapped_emitter) { emitter.map { |x| x * 2 } }
    
    let(:emitter) { described_class.new(42, ->(x) { x + 1 }) { nil } }

    it "layers the new function on top of the existing emitter function" do
      expect(mapped_emitter.emit).to eq(86)
    end
  end
end
