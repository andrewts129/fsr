module FSR
  class Emitter
    IDENTITY_FUNC = ->(x) { x }

    def initialize(initial = nil, emitter_func = IDENTITY_FUNC, &unfold_func)
      raise ArgumentError unless block_given?
      
      @initial = initial
      @emitter_func = emitter_func
      @unfold_func = unfold_func
    end

    def emit
      @emitter_func.call(@initial)
    end

    def unfold
      Emitter.new(@unfold_func.call(@initial), @emitter_func, &@unfold_func)
    end

    def map(&emitter_func)
      Emitter.new(@initial, ->(x) { emitter_func.call(@emitter_func.call(x)) }, &@unfold_func)
    end
  end
end