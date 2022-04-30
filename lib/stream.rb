class Stream
  class EOF
    def empty?
      true
    end

    def +(other_stream)
      other_stream
    end

    def method_missing(*)
      self
    end

    def respond_to_missing?(*)
      true
    end
  end

  def self.emit(value)
    Stream.new(
      lambda { value },
      lambda { EOF.new }
    )
  end

  def initialize(head_func, tail_func)
    @head_func = head_func
    @tail_func = tail_func
  end

  def head
    @head_func.call
  end

  def tail
    @tail_func.call
  end

  def empty?
    head.instance_of?(EOF)
  end

  def +(other_stream)
    Stream.new(
      @head_func,
      lambda do
        @tail_func.call + other_stream
      end
    )
  end
end
