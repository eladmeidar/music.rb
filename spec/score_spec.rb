require File.join( File.dirname(__FILE__), 'spec_helper')

shared_examples_for "all scores" do
  it "can be composed sequentially" do
    seq = Seq.new(@object, rest(0))
    (@object & rest(0)).should  == seq
  end
  
  it "can be composed in parallel" do
    par = Par.new(@object, rest(0))
    (@object | rest(0)).should  == par
  end
  
  it "preserves its structure when mapped with the identity function" do
    @object.map(&ID).should == @object
  end
  
  describe "when repeated" do
    it "sequences an object with itself" do
      (@object * 2).should == (@object & @object) # sequential composition
      (@object * 3).should == (@object & @object & @object) # left-to-right
    end
    
    it "preserves left-to-right ordering" do
      (@object * 3).should == (@object & @object & @object)
    end
    
    it "is equal to itself under the identity" do
      (@object * 1).should == @object
    end
    
    it "returns the unit when given 0" do
      (@object * 0).should == Score::Base.none
    end
    
    it "requires a non-negative Integer" do
      proc { @object * @object }.should raise_error(TypeError)
      proc { @object * 1.0 }.should raise_error(TypeError)
      proc { @object * -1 }.should raise_error(ArgumentError)
    end
  end
    
  it "can be delayed with a rest" do
    @object.delay(4).should == Seq.new(rest(4), @object)
  end
  
  describe "when reversed" do
    it "preserves its duration" do
      @object.reverse.duration.should == @object.duration
    end
    
    it "is equivalent when reversed twice" do
      @object.reverse.reverse.should === @object
    end
  end
end

describe Score::Base do
  it "should return the empty Score" do
    Score::Base.none.should == Rest.new(0)
  end
end

describe Seq do
  before(:all) do
    @object = ((@left = note(60, 2)) & (@right = rest(3)))
  end
  
  it_should_behave_like "all scores"
  
  it "has a left value" do
    @object.left.should == @left
  end
  
  it "has a right value" do
    @object.right.should == @right
  end
  
  it "has a duration" do
    @object.duration.should == ( @left.duration + @right.duration )
  end
  
  it "can be compared" do
    (@left & @right).should == @object
    (@right & @left).should_not == @object
  end
  
  it "can be transposed" do
    @object.transpose(5).should == @left.transpose(5) & @right.transpose(5)
  end
  
  it "can be mapped" do
    @object.map { |n| n.transpose(7) }.should ==
        @object.left.transpose(7) & @object.right.transpose(7)
  end
end

describe Par do
  before(:all) do
    @object = ((@top = note(60, 2)) | (@bottom = rest(3)))
  end
  
  it_should_behave_like "all scores"
  
  it "has a top value" do
    @object.top.should === @top
  end
  
  it "has a bottom value" do
    @object.bottom.should === @bottom
  end
  
  it "has a duration" do
    @object.duration.should == [@top.duration, @bottom.duration].max
  end
  
  it "can be compared" do
    (@top | @bottom).should == @object
    (@bottom | @top).should_not == @object
  end
  
  it "can be transposed" do
    @object.transpose(5).should == @top.transpose(5) | @bottom.transpose(5)
  end
  
  it "can be mapped" do
    @object.map { |n| n.transpose(7) }.should ==
        @object.top.transpose(7) | @object.bottom.transpose(7)
  end
end

describe Group do
  before(:all) do
    @object = group(
    @expr   =   note(60, 2),
    @attrs  =   { :slur => true, :accented => true })
  end
  
  it_should_behave_like "all scores"
  
  it "wraps a Score" do
    @object.score.should == @expr
  end
  
  it "has a duration" do
    @object.duration.should == @expr.duration
  end
  
  it "has attributes" do
    @object.attributes.should == @attrs
  end
  
  it "can be compared" do
    Group.new(@expr, @attrs).should == @object
  end
  
  it "can be compared independently of its attributes" do
    Group.new(@expr).should == @object
  end
  
  it "can be transposed" do
    @object.transpose(5).should == Group.new(@expr.transpose(5), @attrs)
  end
  
  it "should provide inherited attributes when interpreted" do
    timeline = @object.to_timeline
    timeline.all? { |e| e.attributes[:slur] }.should be_true
    timeline[0].attributes[:accented].should be_true
  end
  
  it "can be mapped" do
    @object.map { |n| n.transpose(7) }.should ==
        group( @object.score.transpose(7), @object.attributes )
  end
end

describe Rest do
  before(:all) do
    @object = Rest.new(1, :fermata => true)
  end
  
  it_should_behave_like "all scores"
  
  it "should have a duration" do
    @object.duration.should == 1
  end
  
  it "can be constructed with attributes" do
    @object.fermata.should be_true
  end
end

describe Note do
  before(:all) do
    @object = Note.new(60, 1, :dynamic => :mf)
  end
  
  it_should_behave_like "all scores"
  
  it "should have a pitch" do
    @object.pitch.should == 60
  end
  
  it "should have a duration" do
    @object.duration.should == 1
  end
  
  it "can be constructed with attributes" do
    @object.dynamic.should == :mf
  end
  
  it "can be transposed" do
    @object.transpose(2).should == Note.new(@object.pitch+2, @object.duration, @object.attributes)
  end
  
  it "can be compared" do
    [ Note.new(60,1),
      Note.new(60,1.0),
      Note.new(60,1.quo(1))
    ].each { |val| val.should == @object }
    [ Rest.new(1),
      Score::Base.allocate
    ].each { |val| val.should_not == @object }
  end
end

describe Controller do
  before(:all) do
    @object = Controller.new(:tempo, :tempo => 120)
  end
  
  it_should_behave_like "all scores"
  
  it "should carry associated data" do
    @object.tempo.should == 120
  end
end

describe "All ScoreObjects" do
  before(:all) do
    @object = note(60)
  end
  
  it "equals itself when reversed" do
    @object.reverse.should == @object
  end
  
  it "can be mapped" do
    @object.map { |n| n.transpose(7) }.should == note(67)
  end
end

shared_examples_for "all scores of reference duration" do
  it "will have a duration equal to the shortest tree under truncating parallel composition" do
    (@object / rest(@duration * 2)).duration.should == @duration
    (@object / rest(@duration / 2)).duration.should == @duration / 2
  end
end

describe "Seq of reference duration" do
  before(:all) do
    @duration = 4
    @object = (@left = rest(2) & @right = note(60, 2))
  end
  
  it_should_behave_like "all scores of reference duration"
end

describe "Par of reference duration" do
  before(:all) do
    @duration = 4
    @object = ((@left = note(64, 2) & note(64, 2)) | (@right = note(60, 4)))
  end
  
  it_should_behave_like "all scores of reference duration"
end

describe "Group of reference duration" do
  before(:all) do
    @duration = 4
    @object = group( note(64, 2) & note(64, 2) | note(60, 4), {} )
  end
  
  it_should_behave_like "all scores of reference duration"
end

describe "Rest of reference duration" do
  before(:all) do
    @duration = 4
    @object = rest(4)
  end
  
  it_should_behave_like "all scores of reference duration"
end

describe "helper functions" do
  it "should construct notes" do
    note(60).should    == Note.new(60, 1)
    note(60, 2).should == Note.new(60, 2)
  end
  
  it "should construct rests" do
    rest().should  == Rest.new(1)
    rest(2).should == Rest.new(2)
  end
  
  it "should construct groups" do
    group(note(67) & note(60), {}).should == Group.new(note(67) & note(60), {})
  end
  
  it "should construct the empty score" do
    none().should == rest(0)
  end
  
  it "should compose lists of scores sequentially" do
    s(note(60), note(64), note(67)).should == note(60) & note(64) & note(67)
    sn([60, 64, 67]).should == note(60) & note(64) & note(67)
  end
  
  it "should compose lists of scores in parallel" do
    p(note(60), note(64), note(67)).should == note(60) | note(64) | note(67)
    pn([60, 64, 67]).should == p(note(60), note(64), note(67))
  end
end
