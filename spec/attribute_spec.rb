require File.join( File.dirname(__FILE__), 'spec_helper')

shared_examples_for "all attributes implementations" do
  it "can update its attributes" do
    o1 = @object.update(:arbitrary, 42)
    o1.class.should == @object.class
    o1.attributes[:arbitrary].should == 42
  end
  
  it "has attribute accessors" do
    o1 = @object.update(:arbitrary, 42)
    o1.read(:arbitrary).should == 42
    o1.arbitrary.should == o1.read(:arbitrary)
  end
  
  it "has attribute mutators" do
    o1 = @object.update(:arbitrary, 42)
    o1.arbitrary.should == 42
  end
  
  it "allows a block to manipulate its values " do
    o1 = @object.update(:arbitrary, 21)
    o2 = o1.arbitrary { |a| a * 2 }
    o2.arbitrary.should == 42
  end
  
  it "delegates to its superclass for unsupported messages" do
    proc { @object.arbitrary(:a, :b, :c) }.should raise_error(NoMethodError)
  end
  
  it "makes no change when given a block for an undefined attribute" do
    silence_warnings do
      @object.arbitrary.should be_nil
      @object.arbitrary { |a| :arbitrary }.arbitrary.should be_nil
    end
  end
end

describe Rest do
  before(:all) do
    @object = Rest.new(1, :dynamic => :mf)
  end
  it_should_behave_like "all attributes implementations"
end

describe Note do
  before(:all) do
    @object = Note.new(60, 1, :dynamic => :mf)
  end
  it_should_behave_like "all attributes implementations"
end

describe Controller do
  before(:all) do
    @object = Controller.new(:cc1, :value => 64)
  end
  it_should_behave_like "all attributes implementations"
end
