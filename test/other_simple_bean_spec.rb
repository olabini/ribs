require File.join(File.dirname(__FILE__), 'test_helper')

#   TRACK_ID INT NOT NULL,
#   title VARCHAR(255) NOT NULL,
#   filePath VARCHAR(255) NOT NULL,
#   playTime TIME,
#   added DATE,
#   volume INT NOT NULL,

class Track
  Ribs! do |rib|
    rib.table = :DB_TRACK
    
    rib.primary_key :TRACK_ID

    rib.col :title, :track_title
    rib.col :playTime, :time
    rib.col :added, :date_added
    
    rib.avoid :filePath
  end
end

describe Track do 
  it "should be able to find things based on mapped primary key" do
    track = Track.find(2)
    track.track_id.should == 2
    track.track_title.should == "flux"
    track.time.should == Time.time_at(16,23,0)
    track.date_added.should == Time.local(1983, 12, 13, 0,0,0)
    track.volume.should == 13
  end
    
  it "should have property that wasn't named" do 
    prop = Track.ribs_metadata['VOLUME']
    prop.name.should == 'VOLUME'
    colarr = prop.column_iterator.to_a
    colarr.length.should == 1
    colarr[0].name.should == 'VOLUME'
  end

  it "shouldn't have property that's avoided" do 
    Track.ribs_metadata['filePath'].should be_nil
  end

  it "should have correct names for defined properties" do 
    props = Track.ribs_metadata.properties
    # the primary keys aren't actually part of the properties
    props.keys.sort.should == ['VOLUME', 'track_title', 'time', 'date_added'].sort
    props.values.map { |p| p.column_iterator.to_a[0].name }.sort.should == 
      ['VOLUME', 'TITLE', 'PLAYTIME', 'ADDED'].sort
  end
end
