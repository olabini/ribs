require File.join(File.dirname(__FILE__), 'test_helper')

class Person;end

R(Person).define_accessors

describe "define_accessors" do 
  it "should define id accessors"
  it "should define given name accessors"
  it "should define sur name accessors"
end
