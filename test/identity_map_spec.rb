require File.join(File.dirname(__FILE__), 'test_helper')

class IdentityMapAddress
  Ribs! :table => :address 
end

R(IdentityMapAddress).define_accessors

class IdentityMapPerson
  Ribs! :identity_map => false, :table => :person
end

R(IdentityMapPerson).define_accessors

describe "Identity map" do 
  describe "(disabled)" do 
    before :all do
      R(IdentityMapPerson).create :id => 1, :sur_name => "DeWhite", :age => 23
    end
    
    after :all do 
      R(IdentityMapPerson).destroy 1
    end

    it "should return different objects with get" do 
      R(IdentityMapPerson).get(1).should_not == R(IdentityMapPerson).get(1)
    end
    it "should return different objects with all" do 
      R(IdentityMapPerson).all[0].should_not == R(IdentityMapPerson).all[0]
    end
    it "should return different objects with a combination of get and all" do 
      R(IdentityMapPerson).all[0].should_not == R(IdentityMapPerson).get(1)
    end
  end
  
  describe "(enabled)" do 
    before :each do
      @@id ||= 0
      @@id += 1
      R(IdentityMapAddress).create :id => @@id
    end
    
    after :each do
      R(IdentityMapAddress).destroy @@id
    end
    
    it "should return same objects with get" do 
      p [:BLARG, @@id]
      R(IdentityMapAddress).get(@@id).should == R(IdentityMapAddress).get(@@id)
    end
    it "should return same objects with all" do 
      R(IdentityMapAddress).all[0].should == R(IdentityMapAddress).all[0]
    end
    it "should return same objects with a combination of get -> all" do 
      obj = R(IdentityMapAddress).all[0]
      obj.should == R(IdentityMapAddress).get(@@id)
    end
    it "should return same objects with a combination of all -> get" do 
      obj = R(IdentityMapAddress).get(@@id)
      R(IdentityMapAddress).all[0].should == obj
    end
  end
end
