require File.join(File.dirname(__FILE__), 'test_helper')

class Owner2
  attr_accessor :id, :name, :blog
  
  Ribs! :table => 'owner' do |owner|
    # owner_id shouldn't really need to be specified here... Hmm.
    # default for this kind of thing should probably be table + id
    owner.has_one Blog2, :name => :blog, :column => 'owner_id'
  end
end

class Blog2
  attr_accessor :id, :owner_id, :name

  Ribs! :table => 'blog'
end

describe Owner2 do 
  describe "has_one" do
    it "should include blog field when getting" do 
      owner = R(Owner2).get(1)
      owner.name.should == "Foo"
      owner.blog.class.should == Blog2
      owner.blog.id.should == 1
      owner.blog.name.should == "One"
      owner.blog.owner_id.should == 1

      owner = R(Owner2).get(2)
      owner.name.should == "Bar"
      owner.blog.class.should == Blog2
      owner.blog.id.should == 2
      owner.blog.name.should == "Two"
      owner.blog.owner_id.should == 2
    end

    it "should include blog field when using all" do 
      owners = R(Owner2).all
      owners[0].name.should == "Foo"
      owners[0].blog.class.should == Blog2
      owners[0].blog.id.should == 1
      owners[0].blog.name.should == "One"
      owners[0].blog.owner_id.should == 1

      owners[1].name.should == "Bar"
      owners[1].blog.class.should == Blog2
      owners[1].blog.id.should == 2
      owners[1].blog.name.should == "Two"
      owners[1].blog.owner_id.should == 2
    end
  end
end
