require File.join(File.dirname(__FILE__), 'test_helper')

Ribs::define_model :Address do |rib|
  rib.col :zip, :zip_code
end

describe "define_model" do 
  it "should create a class"
  it "should create a mapping"
  it "should create all the needed properties"
end
