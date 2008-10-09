require File.join(File.dirname(__FILE__), 'test_helper')

describe Ribs::Rib do 
  it "should not have any methods defined except for method_missing" do 
    Ribs::Rib.instance_methods.sort.should == 
      %w(Ribs! __send__ __id__ rspec_reset has_one
         rspec_verify should_receive belongs_to
         should_not_receive R received_message? 
         stub! __column_data__ method_missing).sort
  end
  
  it "should be possible to define a primary key with a method call" do 
    r = Ribs::Rib.new
    r.track_id.primary_key!
    r.__column_data__.primary_keys.should == %w(track_id)
  end

  it "should be possible to define a primary key with a hash" do 
    r = Ribs::Rib.new
    r.track_id :primary_key => true
    r.__column_data__.primary_keys.should == %w(track_id)
  end

  it "should be possible to define a primary key with a simple symbol" do 
    r = Ribs::Rib.new
    r.track_id :primary_key
    r.__column_data__.primary_keys.should == %w(track_id)
  end

  it "should be possible to define more than one primary key" do 
    r = Ribs::Rib.new
    r.track_id.primary_key!
    r.fox_id.primary_key!
    r.__column_data__.primary_keys.should == %w(track_id fox_id)
  end

  it "should handle methods with capital letters" do 
    r = Ribs::Rib.new
    r.TRACK_ID.primary_key!
    r.__column_data__.primary_keys.should == %w(TRACK_ID)
  end

  it "should be possible to define a simple columns mapping with a hash" do 
    r = Ribs::Rib.new
    r.track_id :column => :TRUCK_ID
    r.__column_data__.columns.should == { 'track_id' => ['TRUCK_ID', {:column => :TRUCK_ID}]}
  end
  
  it "should be possible to define a simple columns mapping with a method call" do 
    r = Ribs::Rib.new
    r.track_id.column = :TRUCK_ID
    r.__column_data__.columns.should == { 'track_id' => ['TRUCK_ID', {}]}
  end
  
  it "should be possible to define something to avoid with a method call" do 
    r = Ribs::Rib.new
    r.track_id.avoid!
    r.TRUCK_ID.avoid!
    r.__column_data__.to_avoid.should == %w(track_id truck_id)
  end

  it "should be possible to define something to avoid with a hash" do 
    r = Ribs::Rib.new
    r.track_id :avoid => true
    r.__column_data__.to_avoid.should == %w(track_id)
  end
  
  it "should be possible to define something to avoid with a simple symbol" do 
    r = Ribs::Rib.new
    r.track_id :avoid
    r.__column_data__.to_avoid.should == %w(track_id)
  end
end
