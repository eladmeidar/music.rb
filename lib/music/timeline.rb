module Music
  
  class Event
    include Comparable
    
    attr_reader :time, :object
    
    def initialize(time, obj)
      @time, @object = time, obj
    end
    
    def ==(other)
      [time, object] == [other.time, other.object]
    end
    
    def <=>(other)
      time <=> other.time
    end
  end
  
  class Timeline
    extend Forwardable
    include Enumerable
    
    attr_reader :events
    def_delegators :@events, :each, :[]    
    def self.[](*events) new(events.flatten) end
    
    def initialize(events) @events = events end
    
    def merge(other)
      self.class.new((events + other.events).sort)
    end
    
    def +(other)
      self.class.new(events + other.events)
    end
    
    def ==(other)
      events == other.events
    end
  end
  
  class TimelinePerformer < Performer::Base
    def perform_seq(left, right, context)
      left + right
    end
    
    def perform_par(top, bottom, context)
      top.merge(bottom)
    end
    
    def perform_note(note, context)
      Timeline.new([Event.new(context.time, note)])
    end
    
    def perform_silence(silence, context)
      Timeline.new([])
    end
  end
end