require File.join(File.dirname(__FILE__), 'test_helper')

describe "Simple select" do 
  it "should return correct data for ints" do 
    Ribs.with_session do |s|
      s.select("SELECT TRACK_ID, volume FROM DB_TRACK").should == [[1, 13], [2, 13]]
    end
  end

  it "should return correct data for strings" do 
    Ribs.with_session do |s|
      s.select("SELECT title, filePath FROM DB_TRACK").should == [["foobar", "c:/abc/cde/foo.mp3"], ["flux", "d:/abc/cde/flax.mp3"]]
    end
  end

  it "should return correct data for times" do 
    Ribs.with_session do |s|
      s.select("SELECT playTime FROM DB_TRACK").should == [[Time.time_at(14,50,0)], [Time.time_at(16,23,0)]]
    end
  end

  it "should return correct data for dates" do 
    Ribs.with_session do |s|
      s.select("SELECT added FROM DB_TRACK").should == [[Time.local(1984, 12, 13, 0, 0, 0)], [Time.local(1983, 12, 13, 0, 0, 0)]]
    end
  end

  it "should return correct data for timestamp" do 
    Ribs.with_session do |s|
      s.select("SELECT lastPlayed FROM DB_TRACK").should == [[Time.local(1984, 12, 14, 12,3,11)], [Time.local(1982, 5, 3, 13,3,7)]]
    end
  end
  
  it "should return correct data for floats" do 
    result = Ribs.with_session do |s|
      s.select("SELECT fraction FROM DB_TRACK")
    end
    result[0].length.should == 1
    result[0][0].should be_close(3.4, 0.00001)
    result[1].length.should == 1
    result[1][0].should be_close(3.5, 0.00001)
    
  end

  it "should return correct data for doubles" do 
    result = Ribs.with_session do |s|
      s.select("SELECT otherFraction FROM DB_TRACK")
    end
    result[0].length.should == 1
    result[0][0].should be_close(5.7, 0.00001)
    result[1].length.should == 1
    result[1][0].should be_close(35435.4522234, 0.01)
  end

  it "should return correct data for blobs" do 
    Ribs.with_session do |s|
      s.select("SELECT data FROM DB_TRACK").should == [["abc"], ["mumsi"]]
    end
  end
  
  it "should return correct data for clobs" do 
    Ribs.with_session do |s|
      s.select("SELECT description FROM DB_TRACK").should == [["foobar"], ["maxi"]]
    end
  end
  
  it "should return correct data for booleans" do 
    Ribs.with_session do |s|
      # Not strictly correct - an artifact of a lack in Derby
      s.select("SELECT good FROM DB_TRACK").should == [[1], [0]]
    end
  end

  it "should return correct data for decimal" do 
    Ribs.with_session do |s|
      s.select("SELECT price FROM DB_TRACK").should == [[BigDecimal.new("13134.11")], [BigDecimal.new("55454.33")]]
    end
  end
end
