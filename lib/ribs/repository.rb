module Ribs
  # Gets a Repository object for the object in question. If the object
  # is a class, the repository returned will be a Repository::Class,
  # otherwise it will be a Repository::Instance. Specifically, what
  # you will get for the class FooBar will be the class
  # Ribs::Repository::DB_default::FooBar and you will get an instance
  # of that class if the object is an instance of FooBar. This allows
  # you to add specific functionality to these repositories.  The
  # class Ribs::Repository::DB_default::FooBar will also include
  # Ribs::Repository::FooBar and extend
  # Ribs::Repository::FooBar::ClassMethods so you can add behavior to
  # these that map over all databases.
  def self.Repository(obj, db = :default)
    db_name = "DB_#{db}"
    model_type = case obj
          when Class
            obj
          else
            obj.class
          end

    dbmod = Ribs::Repository::const_get(db_name)
    name = model_type.name.split(/::/).join("_")

    if !dbmod.constants.include?(name)
      Repository::create_repository(name, dbmod)
    end
    
    cls = dbmod::const_get(name.to_sym)
    Ribs::Repository.ensure_repository(name, cls, model_type, db)

    return cls if obj.kind_of?(Class)

    ret = cls.allocate
    ret.send :initialize
    ret.instance_variable_set :@database, db
    ret.instance_variable_set :@model, obj
    ret
  end
  
  # A Repository is the main gateway into all functionality in
  # Ribs. This is where you send your objects to live in the DB, etc.
  #
  # A Repository is a combination implementation of both Data Mapper and Repository.
  module Repository
    module ClassMethods
      include Repository

      def metadata
        @metadata
      end
      
      def persistent(obj)
        (@persistent ||= {})[obj.object_id] = true
      end
      
      def persistent?(obj)
        @persistent && @persistent[obj.object_id]
      end

      def destroyed(obj)
        (@destroyed ||= {})[obj.object_id] = true
      end
      
      def destroyed?(obj)
        @destroyed && @destroyed[obj.object_id]
      end

      # Create a new instance of this model object, optionally setting
      # properties based on +attrs+.
      def new(attrs = {})
        obj = self.model.new
        attrs.each do |k,v|
          obj.send("#{k}=", v)
        end
        obj
      end

      # First creates a model object based on the values in +attrs+ and
      # then saves this to the database directly.
      def create(attrs = {})
        val = new(attrs)
        R(val, self.database).save
        val
      end
      
      # Returns all instances for the current model
      def all
        Ribs.with_handle(self.database) do |h|
          h.all(self.metadata.persistent_class.entity_name)
        end
      end

      # Will get the instance with +id+ or return nil if no such entity
      # exists.
      def get(id)
        Ribs.with_handle(self.database) do |h|
          h.get(self.metadata.persistent_class.entity_name, id)
        end
      end

      # Destroys the model with the id +id+.
      def destroy(id)
        Ribs.with_handle(self.database) do |h|
          h.delete(get(id))
        end
      end
    end
    
    module InstanceMethods
      include Repository
      
      def metadata
        self.class.metadata
      end

      # Removes this instance from the database.
      def destroy!
        self.class.destroyed(self.model)
        Ribs.with_handle(self.database) do |h|
          h.delete(self.model)
        end
      end

      # Saves this instance to the database. If the instance already
      # exists, it will update the database, otherwise it will create
      # it.
      def save
        Ribs.with_handle(self.database) do |h|
          if self.class.persistent?(self.model)
            h.update_obj(self.model)
          else
            h.insert_obj(self.model)
            self.class.persistent(self.model)
          end
        end
        self.model
      end
    end
    
    attr_reader :database
    attr_reader :model
    
    class << self
      def ensure_repository(name, cls, real, db)
        unless cls.kind_of?(Repository)
          mod1 = if Repository.constants.include?(name)
                   Repository.const_get(name)
                 else
                   mod = Module.new
                   Repository.const_set(name, mod)
                   mod
                 end
          
          unless mod1.kind_of?(Repository)
            mod1.send :include, Repository::InstanceMethods
          end

          unless mod1.constants.include?("ClassMethods")
            mod1.const_set(:ClassMethods, Module.new)
          end
          
          cls.send :include, mod1
          cls.send :extend, mod1.const_get(:ClassMethods)
          cls.send :extend, Repository::ClassMethods
          cls.instance_variable_set :@database, db
          cls.instance_variable_set :@model, real
          cls.instance_variable_set :@metadata, Ribs::metadata_for(db, real, cls)
        end
      end

      def create_repository(name, dbmod)
        c = Class.new
        mod1 = if Repository.constants.include?(name)
                 Repository.const_get(name)
               else
                 mod = Module.new
                 Repository.const_set(name, mod)
                 mod
               end
        dbmod.const_set name, c
      end
      
      def const_missing(name)
        if /^DB_(.*?)$/ =~ name.to_s
          db_name = $1
          mod = Module.new
          mod.instance_variable_set :@database_name, db_name.to_sym
          const_set name, mod
          mod
        else
          super
        end
      end
    end
  end
end

module Kernel
  # Gets a Repository object for the object in question. If the object
  # is a class, the repository returned will be a Repository::Class,
  # otherwise it will be a Repository::Instance. Specifically, what
  # you will get for the class FooBar will be the class
  # Ribs::Repository::DB_default::FooBar and you will get an instance
  # of that class if the object is an instance of FooBar. This allows
  # you to add specific functionality to these repositories.  The
  # class Ribs::Repository::DB_default::FooBar will also include
  # Ribs::Repository::FooBar and extend
  # Ribs::Repository::FooBar::ClassMethods so you can add behavior to
  # these that map over all databases.
  def R(obj, db=:default)
    Ribs::Repository(obj, db)
  end
end
