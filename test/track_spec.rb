require File.join(File.dirname(__FILE__), 'test_helper')

class Track
  attr_accessor :track_id
  attr_accessor :track_title
  attr_accessor :time
  attr_accessor :date_added
  attr_accessor :last_played_at
  attr_accessor :file_data
  attr_accessor :desc
  attr_accessor :some_fraction
  attr_accessor :is_good
  attr_accessor :full_price
  attr_accessor :volume

  Ribs! do |rib|
    rib.table :DB_TRACK
    
    rib.primary_key :TRACK_ID

    rib.col :title, :track_title
    rib.col :playTime, :time
    rib.col :added, :date_added
    rib.col :lastPlayed, :last_played_at
    rib.col :data, :file_data
    rib.col :description, :desc
    rib.col :fraction, :some_fraction
    rib.col :good, :is_good
    rib.col :price, :full_price
    
    rib.avoid :filePath, :default => "fluxie"
  end
end

# R(Track).define_accessors

describe Track do 
  it "should be able to find things based on mapped primary key" do
    track = R(Track).get(2)
    track.track_id.should == 2
    track.track_title.should == "flux"
    track.time.should == Time.time_at(16,23,0)
    track.date_added.should == Time.local(1983, 12, 13, 0,0,0)
    track.volume.should == 13
  end
    
  it "should have property that wasn't named" do 
    prop = R(Track).metadata['VOLUME']
    prop.name.should == 'VOLUME'
    colarr = prop.column_iterator.to_a
    colarr.length.should == 1
    colarr[0].name.should == 'VOLUME'
  end

  it "shouldn't have property that's avoided" do 
    R(Track).metadata['filePath'].should be_nil
  end

  it "should have correct names for defined properties" do 
    props = R(Track).metadata.properties
    # the primary keys aren't actually part of the properties
    props.keys.sort.should == ['OTHERFRACTION', 'VOLUME', 'track_title', 'time', 'date_added', 'file_data', 'desc', 'some_fraction', 'is_good', 'full_price', 'last_played_at'].sort
    props.values.map { |p| p.column_iterator.to_a[0].name }.sort.should == 
      ['VOLUME', 'TITLE', 'PLAYTIME', 'ADDED', 'OTHERFRACTION', 'LASTPLAYED', 'DATA', 'DESCRIPTION', 'FRACTION', 'GOOD', 'PRICE'].sort
  end
  
  it "should have correct value and type for OTHERFRACTION property from instance variable" do 
    res = R(Track).all.map { |a| a.instance_variable_get :@otherfraction }.sort
    res[0].should be_close(5.7, 0.00001)
    res[1].should be_close(35435.4522234, 0.01)
  end

  it "should have correct value and type for VOLUME property" do 
    R(Track).all.map { |a| a.volume }.sort.should == [13, 13]
  end
  
  it "should have correct value and type for track_title property" do 
    R(Track).all.map { |a| a.track_title }.sort.should == ["flux", "foobar"]
  end

  it "should have correct value and type for time property" do 
    R(Track).all.map { |a| a.time }.sort.should == [Time.time_at(14,50,0), Time.time_at(16,23,0)]
  end

  it "should have correct value and type for date_added property" do 
    R(Track).all.map { |a| a.date_added }.sort.should == [Time.local(1983, 12, 13, 0, 0, 0),Time.local(1984, 12, 13, 0, 0, 0)]
  end
  
  it "should have correct value and type for file_data property" do 
    R(Track).all.map { |a| a.file_data }.sort.should == ["abc", "mumsi"]
  end

  it "should have correct value and type for desc property" do 
    R(Track).all.map { |a| a.desc }.sort.should == ["foobar", "maxi"]
  end
  
  it "should have correct value and type for some_fraction property" do 
    res = R(Track).all.map { |a| a.some_fraction }.sort
    res[0].should be_close(3.4, 0.00001)
    res[1].should be_close(3.5, 0.00001)
  end
  
  it "should have correct value and type for is_good property" do 
    R(Track).all.map { |a| a.is_good }.sort_by{|v| v ? 0 : 1}.should == [true, false]
  end
  
  it "should have correct value and type for full_price property" do 
    R(Track).all.map { |a| a.full_price }.sort.should == [BigDecimal.new("13134.11"), BigDecimal.new("55454.33")]
  end

  it "should have correct value and type for last_played_at property" do 
    R(Track).all.map { |a| a.last_played_at }.sort.should == [Time.local(1982, 5, 3, 13,3,7), Time.local(1984, 12, 14, 12,3,11)]
  end
  
  it "should be possible to create a new instance by setting properties" do 
    begin 
      track = Track.new
      track.track_id = 3
      track.track_title = "Born to raise hell"
      track.time = Time.time_at(0,3,25)
      track.date_added = Time.local(2003, 8, 31, 0, 0, 0)
      track.last_played_at = Time.local(2008, 8, 31, 21, 41, 30)
      track.file_data = "abc def"
      track.desc = "This track I really don't know anything about, in fact"
      track.some_fraction = 3.1415
      track.is_good = false
      track.full_price = BigDecimal.new("14.49")
      track.volume = 5

      R(Track).get(3).should be_nil
      
      R(track).save

      R(Track).get(3).should_not be_nil
    ensure
      reset_database!
    end
  end

  it "should be possible to create a new instance by giving properties to new" do 
    begin 
      track = R(Track).new(
                        :track_id => 3,
                        :track_title => "Born to raise hell",
                        :time => Time.time_at(0,3,25),
                        :date_added => Time.local(2003, 8, 31, 0, 0, 0),
                        :last_played_at => Time.local(2008, 8, 31, 21, 41, 30),
                        :file_data => "abc def",
                        :desc => "This track I really don't know anything about, in fact",
                        :some_fraction => 3.1415,
                        :is_good => false,
                        :full_price => BigDecimal.new("14.49"),
                        :volume => 5)

      R(Track).get(3).should be_nil

      R(track).save

      R(Track).get(3).should_not be_nil
    ensure
      reset_database!
    end
  end

  it "should be possible to create a new instance by using create" do 
    begin 
      R(Track).get(3).should be_nil
      track = R(Track).create(
                        :track_id => 3,
                        :track_title => "Born to raise hell",
                        :time => Time.time_at(0,3,25),
                        :date_added => Time.local(2003, 8, 31, 0, 0, 0),
                        :last_played_at => Time.local(2008, 8, 31, 21, 41, 30),
                        :file_data => "abc def",
                        :desc => "This track I really don't know anything about, in fact",
                        :some_fraction => 3.1415,
                        :is_good => false,
                        :full_price => BigDecimal.new("14.49"),
                        :volume => 5)

      R(Track).get(3).should_not be_nil
    ensure
      reset_database!
    end
  end

  def create_simple
    R(Track).create(
                 :track_id => 3,
                 :track_title => "Born to raise hell",
                 :time => Time.time_at(0,3,25),
                 :date_added => Time.local(2003, 8, 31, 0, 0, 0),
                 :last_played_at => Time.local(2008, 8, 31, 21, 41, 30),
                 :file_data => "abc def",
                 :desc => "This track I really don't know anything about, in fact",
                 :some_fraction => 3.1415,
                 :is_good => false,
                 :full_price => BigDecimal.new("14.49"),
                 :volume => 5)
    
    R(Track).get(3)
  end
  
  it "should have correct value and type for TRACK_ID property on newly created bean" do 
    begin
      create_simple.track_id.should == 3
    ensure
      reset_database!
    end
  end

  it "should have correct value and type for track_title property on newly created bean" do 
    begin
      create_simple.track_title.should == "Born to raise hell"
    ensure
      reset_database!
    end
  end
  
  it "should have correct value and type for time property on newly created bean" do 
    begin
      create_simple.time.should == Time.time_at(0,3,25)
    ensure
      reset_database!
    end
  end
  
  it "should have correct value and type for date_added property on newly created bean" do 
    begin
      create_simple.date_added.should == Time.local(2003, 8, 31, 0, 0, 0)
    ensure
      reset_database!
    end
  end
  
  it "should have correct value and type for last_played_at property on newly created bean" do 
    begin
      create_simple.last_played_at.should == Time.local(2008, 8, 31, 21, 41, 30)
    ensure
      reset_database!
    end
  end
  
  it "should have correct value and type for file_data property on newly created bean" do 
    begin
      create_simple.file_data.should == "abc def"
    ensure
      reset_database!
    end
  end
  
  it "should have correct value and type for desc property on newly created bean" do 
    begin
      create_simple.desc.should == "This track I really don't know anything about, in fact"
    ensure
      reset_database!
    end
  end
  
  it "should have correct value and type for some_fraction property on newly created bean" do 
    begin
      create_simple.some_fraction.should be_close(3.1415, 0.00001)
    ensure
      reset_database!
    end
  end
  
  it "should have correct value and type for is_good property on newly created bean" do 
    begin
      create_simple.is_good.should be_false
    ensure
      reset_database!
    end
  end
  
  it "should have correct value and type for full_price property on newly created bean" do 
    begin
      create_simple.full_price.should == BigDecimal.new("14.49")
    ensure
      reset_database!
    end
  end
  
  it "should have correct value and type for volume property on newly created bean" do 
    begin
      create_simple.volume.should == 5
    ensure
      reset_database!
    end
  end

  it "should be possible to update track_title property on existing bean" do 
    begin
      v = R(Track).get(1)
      v.track_title = "new value here"
      R(v).save
      
      R(Track).get(1).track_title.should == "new value here"
    ensure
      reset_database!
    end
  end

  it "should be possible to update time property on existing bean" do 
    begin
      v = R(Track).get(1)
      v.time = Time.time_at(23,32,33)
      R(v).save
      
      R(Track).get(1).time.should == Time.time_at(23,32,33)
    ensure
      reset_database!
    end
  end

  it "should be possible to update date_added property on existing bean" do 
    begin
      v = R(Track).get(1)
      v.date_added = Time.local(2004,10,9,0,0,0)
      R(v).save
      
      R(Track).get(1).date_added.should == Time.local(2004,10,9,0,0,0)
    ensure
      reset_database!
    end
  end

  it "should be possible to update last_played_at property on existing bean" do 
    begin
      v = R(Track).get(1)
      v.last_played_at = Time.local(2005,8,8,10,24,12)
      R(v).save
      
      R(Track).get(1).last_played_at.should == Time.local(2005,8,8,10,24,12)
    ensure
      reset_database!
    end
  end

  it "should be possible to update file_data property on existing bean" do 
    begin
      v = R(Track).get(1)
      v.file_data = "Some data"
      R(v).save
      
      R(Track).get(1).file_data.should == "Some data"
    ensure
      reset_database!
    end
  end

  it "should be possible to update desc property on existing bean" do 
    begin
      v = R(Track).get(1)
      v.desc = "Some description"
      R(v).save
      
      R(Track).get(1).desc.should == "Some description"
    ensure
      reset_database!
    end
  end

  it "should be possible to update some_fraction property on existing bean" do 
    begin
      v = R(Track).get(1)
      v.some_fraction = 3.1416 #Anal test
      R(v).save
      
      R(Track).get(1).some_fraction.should be_close(3.1416, 0.00001)
    ensure
      reset_database!
    end
  end

  it "should be possible to update is_good property on existing bean" do 
    begin
      v = R(Track).get(1)
      v.is_good = false
      R(v).save
      
      R(Track).get(1).is_good.should be_false
    ensure
      reset_database!
    end
  end

  it "should be possible to update full_price property on existing bean" do 
    begin
      v = R(Track).get(1)
      v.full_price = BigDecimal.new("142.12")
      R(v).save
      
      R(Track).get(1).full_price.should == BigDecimal.new("142.12")
    ensure
      reset_database!
    end
  end

  it "should be possible to update volume property on existing bean" do 
    begin
      v = R(Track).get(1)
      v.volume = 42
      R(v).save
      
      R(Track).get(1).volume.should == 42
    ensure
      reset_database!
    end
  end
  
  it "should be possible to delete existing bean" do 
    begin
      R(R(Track).get(1)).destroy!
      R(Track).get(1).should be_nil
    ensure
      reset_database!
    end
  end
  
  it "should be possible to delete existing bean by id" do 
    begin
      R(Track).destroy(2)
      R(Track).get(2).should be_nil
    ensure
      reset_database!
    end
  end
end
