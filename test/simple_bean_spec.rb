require File.join(File.dirname(__FILE__), 'test_helper')

class Artist
  Ribs!
end

describe Artist do 
  it "should be able to find all artists" do 
    Artist.find(:all).length.should == 3
  end

  it "should return correct value and type for id property" do 
    Artist.find(:all).map { |a| a.id }.sort.should == [1,2,3]
  end
  
  it "should return correct value and type for name property" do 
    Artist.find(:all).map { |a| a.name }.sort.should == ["David Bowie","New Model Army","Public Image Ltd"]
  end
end
