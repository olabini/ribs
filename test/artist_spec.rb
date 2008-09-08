require File.join(File.dirname(__FILE__), 'test_helper')

class Artist
  Ribs!
end

describe Artist do 
  it "should be able to find all artists" do 
    Artist.all.length.should == 3
  end

  it "should return correct value and type for id property" do 
    Artist.all.map { |a| a.id }.sort.should == [1,2,3]
  end
  
  it "should return correct value and type for name property" do 
    Artist.all.map { |a| a.name }.sort.should == ["David Bowie","New Model Army","Public Image Ltd"]
  end
  
  it "should only have the appropriate methods defined" do 
    methods = (Artist.instance_methods - Object.instance_methods).sort
    methods.should == ['__ribs_meat', 'destroy!', 'id=', 'name', 'name=', 'save']
  end
  
  it "should be possible to create a new instance by setting properties" do 
    begin
      artist = Artist.new
      artist.id = 4
      artist.name = "Assemblage 23"
      artist.save
      artist2 = Artist.get(4)
      artist2.should_not be_nil
      artist2.id.should == 4
      artist2.name.should == "Assemblage 23"
    ensure
      reset_database!
    end    
  end

  it "should be possible to create a new instance by giving properties to new" do 
    begin
      artist = Artist.new :id => 4, :name => "Assemblage 23"
      artist.save
      artist2 = Artist.get(4)
      artist2.should_not be_nil
      artist2.id.should == 4
      artist2.name.should == "Assemblage 23"
    ensure
      reset_database!
    end    
  end

  it "should be possible to create a new instance by using create" do 
    begin
      Artist.create :id => 4, :name => "Assemblage 23"
      artist = Artist.get(4)
      artist.should_not be_nil
      artist.id.should == 4
      artist.name.should == "Assemblage 23"
    ensure
      reset_database!
    end    
  end
  
  it "should be possible to update name property on existing bean" do 
    begin
      artist = Artist.get(2)
      artist.name = "U2"
      Artist.get(2).name.should == "New Model Army"
      artist.save
      Artist.get(2).name.should == "U2"
    ensure
      reset_database!
    end
  end

  it "should be possible to delete existing bean" do 
    begin
      Artist.get(2).destroy!
      Artist.get(2).should be_nil
    ensure
      reset_database!
    end
  end

  it "should be possible to delete existing bean by id" do 
    begin
      Artist.destroy(2)
      Artist.get(2).should be_nil
    ensure
      reset_database!
    end
  end
end
