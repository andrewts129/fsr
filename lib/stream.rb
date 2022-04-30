class Stream
  class EOF
    def empty?
      true
    end

    def method_missing(*)
      self
    end
  end

  def self.emit(value)
    Stream.new(
      Proc.new { value },
      Proc.new { EOF.new }
    )
  end

  def initialize(head_proc, tail_proc)
    @head_proc = head_proc
    @tail_proc = tail_proc
  end

  def head
    @head_proc.call
  end

  def tail
    @tail_proc.call
  end
end
