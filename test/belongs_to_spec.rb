require File.join(File.dirname(__FILE__), 'test_helper')

class Owner
  attr_accessor :id, :name, :blog_id
end

class Blog
  attr_accessor :owner, :name

  Ribs! do |blog|
    blog.belongs_to Owner
  end
end

describe Blog do 
  describe "belongs_to" do 
    it "should include owner field when getting" do 
      blog = R(Blog).get(1)
      blog.name.should == "One"
      blog.owner.class.should == Owner
      blog.owner.id.should == 1
      blog.owner.name.should == "Foo" 
      blog.owner.blog_id.should == 2

      blog = R(Blog).get(2)
      blog.name.should == "Two"
      blog.owner.class.should == Owner
      blog.owner.id.should == 2
      blog.owner.name.should == "Bar" 
      blog.owner.blog_id.should == 1
    end

    it "should include owner field when using all" do 
      blogs = R(Blog).all
      blogs[0].name.should == "One"
      blogs[0].owner.class.should == Owner
      blogs[0].owner.id.should == 1
      blogs[0].owner.name.should == "Foo" 
      blogs[0].owner.blog_id.should == 2

      blogs[1].name.should == "Two"
      blogs[1].owner.class.should == Owner
      blogs[1].owner.id.should == 2
      blogs[1].owner.name.should == "Bar" 
      blogs[1].owner.blog_id.should == 1
    end
  end
end
