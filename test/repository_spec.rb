require File.join(File.dirname(__FILE__), 'test_helper')

class FakeModel;end
class FakeModel::FakeSecondModel;end

describe Ribs::Repository do 
  before :all do 
    R(FakeModel)
    R(FakeModel::FakeSecondModel)

    R(FakeModel, :flarg)
    R(FakeModel::FakeSecondModel, :flurg)
  end
  
  it 'should create a Repository class for a model with default db' do 
    Ribs::Repository::DB_default.constants.should include("FakeModel")
    Ribs::Repository::DB_default::FakeModel.class.should == Class
    Ribs::Repository::DB_default::FakeModel.ancestors.should include(Ribs::Repository)
    Ribs::Repository::DB_default::FakeModel.ancestors.should include(Ribs::Repository::InstanceMethods)
    Ribs::Repository::DB_default::FakeModel.ancestors.should include(Ribs::Repository::FakeModel)
    (class << Ribs::Repository::DB_default::FakeModel; self; end).ancestors.should include(Ribs::Repository)
    (class << Ribs::Repository::DB_default::FakeModel; self; end).ancestors.should include(Ribs::Repository::ClassMethods)
    (class << Ribs::Repository::DB_default::FakeModel; self; end).ancestors.should include(Ribs::Repository::FakeModel::ClassMethods)
  end

  it 'should create a Repository class for a model with another db' do 
    Ribs::Repository::DB_flarg.constants.should include("FakeModel")
    Ribs::Repository::DB_flarg::FakeModel.class.should == Class
    Ribs::Repository::DB_flarg::FakeModel.ancestors.should include(Ribs::Repository)
    Ribs::Repository::DB_flarg::FakeModel.ancestors.should include(Ribs::Repository::InstanceMethods)
    Ribs::Repository::DB_flarg::FakeModel.ancestors.should include(Ribs::Repository::FakeModel)
    (class << Ribs::Repository::DB_flarg::FakeModel; self; end).ancestors.should include(Ribs::Repository)
    (class << Ribs::Repository::DB_flarg::FakeModel; self; end).ancestors.should include(Ribs::Repository::ClassMethods)
    (class << Ribs::Repository::DB_flarg::FakeModel; self; end).ancestors.should include(Ribs::Repository::FakeModel::ClassMethods)
  end
  
  it 'should create a DB place the first time asked for it' do 
    Ribs::Repository::DB_flux
    Ribs::Repository::DB_flux.class.should == Module
  end

  it 'should only create a db if prefix with the DB_' do 
    proc do 
      Ribs::Repository::Noxic
    end.should raise_error(NameError)
  end

  it 'should return a Repository class for a model' do 
    R(FakeModel).should == Ribs::Repository::DB_default::FakeModel
    R(FakeModel).model.should == ::FakeModel
    R(FakeModel).database.should == :default
  end
  
  it 'should return an instance of the Repository class for a model instance' do 
    ff = FakeModel.new
    R(ff).should be_kind_of(Ribs::Repository::DB_default::FakeModel)
    R(ff).model.should == ff
    R(ff).database.should == :default
  end

  it 'should return a Repository class for a model with another db' do 
    R(FakeModel, :flarg).should == Ribs::Repository::DB_flarg::FakeModel
    R(FakeModel, :flarg).model.should == ::FakeModel
    R(FakeModel, :flarg).database.should == :flarg
  end
  
  it 'should return an instance of the Repository class for a model instance with another db' do 
    ff = FakeModel.new
    R(ff, :flarg).should be_kind_of(Ribs::Repository::DB_flarg::FakeModel)
    R(ff, :flarg).model.should == ff
    R(ff, :flarg).database.should == :flarg
  end
  
  it 'should handle submodules correctly' do 
    R(FakeModel::FakeSecondModel).should == Ribs::Repository::DB_default::FakeModel_FakeSecondModel
    R(FakeModel::FakeSecondModel).model.should == ::FakeModel::FakeSecondModel
    R(FakeModel::FakeSecondModel).database.should == :default
  end
end
