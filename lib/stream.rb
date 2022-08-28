class Stream
  class EOF
    def empty?
      true
    end

    def +(other_stream)
      other_stream
    end

    def to_a
      []
    end

    def method_missing(*)
      self
    end

    def respond_to_missing?(*)
      true
    end
  end

  def self.emit(*args, &block)
    if block_given?
      raise ArgumentError unless args.empty?

      transform_func = ->(at_head) { at_head ? block.call : empty }
    else
      raise ArgumentError unless args.size == 1

      transform_func = ->(at_head) { at_head ? args[0] : empty }
    end

    Stream.new(
      FSR::Emitter.new(true, transform_func) { false }
    )
  end

  def self.emits(enumerable)
    return Stream.emit(enumerable) unless enumerable.respond_to?(:each)

    enumerator = enumerable.to_enum

    begin
      initial_value = enumerator.next
    rescue StopIteration
      return empty
    end

    Stream.new(
      FSR::Emitter.new(initial_value) do
        begin
          enumerator.next
        rescue StopIteration
          empty
        end
      end
    )
  end

  def self.empty
    EOF.new
  end

  # kernel methods

  def initialize(emitter)
    @emitter = emitter
  end

  def head
    @emitter.emit
  end

  def tail
    Stream.new(@emitter.unfold)
  end

  def empty?
    head.instance_of?(EOF)
  end

  def +(other_stream)
    other_stream = Stream.emits(other_stream) if other_stream.is_a?(Enumerable)

    first_stream_pointer = self
    second_stream_pointer = other_stream

    emitter_wrapping_both = FSR::Emitter.new(
      first_stream_pointer.empty?,
       ->(has_exhausted_first) { has_exhausted_first ? second_stream_pointer.head : first_stream_pointer.head }
    ) do |has_exhausted_first|
      if has_exhausted_first
        second_stream_pointer = second_stream_pointer.tail

        true
      else
        first_stream_pointer = first_stream_pointer.tail

        first_stream_pointer.empty?
      end
    end

    Stream.new(emitter_wrapping_both)
  end

  def map(&block)
    Stream.new(@emitter.map(&block))
  end

  # enhancement methods

  def to_a
    [].tap do |arr|
      each do |element|
        arr << element
      end
    end
  end

  def flat_map(&block)
    return self if empty?

    if head.is_a?(Stream)
      Stream.new(
        lambda { block.call(head.head) },
        lambda { head.tail.map(&block) + tail.flat_map(&block) }
      )
    else
      Stream.new(
        lambda { block.call(head) },
        lambda { tail.flat_map(&block) }
      )
    end
  end

  def flatten
    flat_map(&:itself)
  end

  def each(&block)
    pointer = self

    until pointer.empty?
      block.call(pointer.head)
      pointer = pointer.tail
    end
  end

  def take(n)
    raise ArgumentError unless n >= 0

    return Stream.empty if empty? || n == 0

    Stream.new(
      @head_func,
      lambda { tail.take(n - 1) }
    )
  end

  def drop(n)
    raise ArgumentError unless n >= 0

    return Stream.empty if empty?
    return self if n == 0

    tail.drop(n - 1)
  end

  def repeat
    Stream.new(
      @head_func,
      lambda { tail + self.repeat }
    )
  end

  def filter(&block)
    if block.call(head)
      Stream.new(
        @head_func,
        lambda { tail.filter(&block) }
      )
    else
      tail.filter(&block)
    end
  end
end
