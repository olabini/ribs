
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
end
