require File.join(File.dirname(__FILE__), 'test_helper')

class Artist
  Ribs! :identity_map => false
  attr_accessor :id
  attr_accessor :name
end

describe Artist do 
  it "should be able to find all artists" do 
    R(Artist).all.length.should == 3
  end

  it "should return correct value and type for id property" do 
    R(Artist).all.map { |a| a.id }.sort.should == [1,2,3]
  end
  
  it "should return correct value and type for name property" do 
    R(Artist).all.map { |a| a.name }.sort.should == ["David Bowie","New Model Army","Public Image Ltd"]
  end
  
  it "should only have the appropriate methods defined" do 
    methods = (Artist.instance_methods - Object.instance_methods).sort
    methods.should == ['id=', 'name', 'name=']
  end
  
  it "should be possible to create a new instance by setting properties" do 
    begin
      artist = Artist.new
      artist.id = 4
      artist.name = "Assemblage 23"
      R(artist).save
      artist2 = R(Artist).get(4)
      artist2.should_not be_nil
      artist2.id.should == 4
      artist2.name.should == "Assemblage 23"
    ensure
      reset_database!
    end    
  end

  it "should be possible to create a new instance by giving properties to new" do 
    begin
      artist = R(Artist).new :id => 4, :name => "Assemblage 23"
      R(artist).save
      artist2 = R(Artist).get(4)
      artist2.should_not be_nil
      artist2.id.should == 4
      artist2.name.should == "Assemblage 23"
    ensure
      reset_database!
    end    
  end

  it "should be possible to create a new instance by using create" do 
    begin
      R(Artist).create :id => 4, :name => "Assemblage 23"
      artist = R(Artist).get(4)
      artist.should_not be_nil
      artist.id.should == 4
      artist.name.should == "Assemblage 23"
    ensure
      reset_database!
    end    
  end
  
  it "should be possible to update name property on existing bean" do 
    begin
      artist = R(Artist).get(2)
      artist.name = "U2"
      R(Artist).get(2).name.should == "New Model Army"
      R(artist).save
      R(Artist).get(2).name.should == "U2"
    ensure
      reset_database!
    end
  end

  it "should be possible to delete existing bean" do 
    begin
      R(R(Artist).get(2)).destroy!
      R(Artist).get(2).should be_nil
    ensure
      reset_database!
    end
  end

  it "should be possible to delete existing bean by id" do 
    begin
      R(Artist).destroy(2)
      R(Artist).get(2).should be_nil
    ensure
      reset_database!
    end
  end
end
