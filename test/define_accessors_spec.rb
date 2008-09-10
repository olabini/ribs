require File.join(File.dirname(__FILE__), 'test_helper')

class Person;end

R(Person).define_accessors

describe "define_accessors" do 
  it "should define id accessors" do 
    Person.instance_methods.should include("id")
    Person.instance_methods.should include("id=")
  end

  it "should define given_name accessors" do 
    Person.instance_methods.should include("given_name")
    Person.instance_methods.should include("given_name=")
  end
  
  it "should define sur_name accessors" do 
    Person.instance_methods.should include("sur_name")
    Person.instance_methods.should include("sur_name=")
  end

  it "should define age accessors" do 
    Person.instance_methods.should include("age")
    Person.instance_methods.should include("age=")
  end
end
