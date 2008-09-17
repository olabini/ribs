require File.join(File.dirname(__FILE__), 'test_helper')

Ribs::define_model :Address do |rib|
  rib.zip_code :column => :zip
end

describe "define_model" do 
  it "should create a class" do 
    Address.class.should == Class
  end
  
  it "should create all the needed properties" do 
    Address.instance_methods.should include("id")
    Address.instance_methods.should include("id=")
    Address.instance_methods.should include("street")
    Address.instance_methods.should include("street=")
    Address.instance_methods.should include("postal")
    Address.instance_methods.should include("postal=")
    Address.instance_methods.should include("zip_code")
    Address.instance_methods.should include("zip_code=")
    Address.instance_methods.should_not include("zip")
    Address.instance_methods.should_not include("zip=")
    Address.instance_methods.should include("country")
    Address.instance_methods.should include("country=")
  end
  
  it "should be a working Ribs class" do 
    R(Address).create :id => 1, :street => "foobar 42"
    all = R(Address).all
    all.length.should == 1
    all[0].id.should == 1
    all[0].street.should == "foobar 42"
    all[0].zip_code.should be_nil
    R(Address).get(1).street.should == all[0].street
    all[0].street = "foobar 43"
    R(all[0]).save
    R(Address).get(1).street.should == "foobar 43"
    R(Address).destroy(1)
    R(Address).all.should be_empty
  end
end
