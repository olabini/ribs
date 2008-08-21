
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

  it "should return correct data for times"
  it "should return correct data for dates"
end
