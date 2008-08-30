module Ribs
  # Ribs::ClassMethods contains all the methods that gets mixed in to
  # a model class.
  module ClassMethods
    # Get the metadata for the current model
    attr_reader :ribs_metadata

    # Create a new instance of this model object, optionally setting
    # properties based on +attrs+.
    def new(attrs = {})
      obj = super()
      attrs.each do |k,v|
        obj.send("#{k}=", v)
      end
      obj
    end

    # First creates a model object based on the values in +attrs+ and
    # then saves this to the database directly.
    def create(attrs = {})
      val = new(attrs)
      val.save
      val
    end
    
    # Depending on the value of +id_or_sym+, tries to find the model
    # with a specified id, or if +id_or_sym+ is <tt>:all</tt> returns
    # all instances of this model.
    def find(id_or_sym)
      Ribs.with_session do |s|
        s.find(self.ribs_metadata.persistent_class.entity_name, id_or_sym)
      end
    end

    # Destroys the model with the id +id+.
    def destroy(id)
      Ribs.with_session do |s|
        s.delete(find(id))
      end
    end
    
    
    # TODO: add inspect here
  end
  
  # Ribs::InstanceMethods provides the methods that gets mixed in to
  # all instances of a model object.
  module InstanceMethods
    # Returns the Meat instance for this instance.
    def __ribs_meat
      @__ribs_meat ||= Ribs::Meat.new(self)
    end
        
    # Returns an inspection based on current values of the data in the
    # database.
    def inspect
      "#<#{self.class.name}: #{self.__ribs_meat.properties.inspect}>"
    end
    
    # Saves this instance to the database. If the instance already
    # exists, it will update the database, otherwise it will create
    # it.
    def save
      Ribs.with_session do |s|
        s.save(self)
      end
    end
    
    # Removes this instance from the database.
    def destroy!
      __ribs_meat.destroyed = true
      Ribs.with_session do |s|
        s.delete(self)
      end
    end
  end
  
  # Collects all the meta data about a specific Ribs model
  class MetaData
    # The table to connect to
    attr_accessor :table
    # The persistent class that Hibernate uses as a definition for
    # this model.
    attr_accessor :persistent_class
    # The Rib that defines all the mapping data
    attr_accessor :rib
    
    # Return the property instance for the given +name+.
    def [](name)
      self.persistent_class.get_property(name.to_s) rescue nil
    end

    # Return all the properties for this model.
    def properties
      self.persistent_class.property_iterator.to_a.inject({}) do |h, value|
        h[value.name] = value
        h
      end
    end
  end

  # Contains the mapping data that gets created when calling the
  # {Ribs!} method.
  class Rib
    # List of all the columns defined
    attr_reader :columns
    # List of all primary keys defined
    attr_reader :primary_keys
    # List of all columns to avoid
    attr_reader :to_avoid

    # Initializes object
    def initialize
      @columns = { }
      @primary_keys = { }
      @to_avoid = []
    end
    
    # Gets or sets the table name to work with. If +name+ is nil,
    # returns the table name, if not sets the table name to +name+.
    def table(name = nil)
      if name
        @table = name
      else
        @table
      end
    end
    
    # Adds a new column mapping for a specific column.
    def col(column, property = column, options = {})
      @columns[column.to_s.downcase] = [property.to_s, options]
    end

    # Adds a new primary key mapping for a column.
    def primary_key(column, property = column, options = {})
      @primary_keys[column.to_s.downcase] = property.to_s
      @columns[column.to_s.downcase] = [property.to_s, options]
    end
    
    # Avoids all the provided columns
    def avoid(*columns)
      @to_avoid += columns.map{|s| s.to_s.downcase}
    end
  end
  
  Table = org.hibernate.mapping.Table
  Column = org.hibernate.mapping.Column
  Property = org.hibernate.mapping.Property
  SimpleValue = org.hibernate.mapping.SimpleValue

  # A simple helper class that allows the Java parts of the system to
  # get the Ruby class from the PersistentClass instance.
  class RubyRootClass < org.hibernate.mapping.RootClass
    include org.jruby.ribs.WithRubyClass

    # The Ruby class
    attr_accessor :ruby_class
    
    def initialize(*args)
      super
    end
    
    # Get the Ruby class. Implementation of the WithRubyClass
    # interface.
    def getRubyClass
      @ruby_class
    end
  end
  
  class << self
    # Define a rib for the class +on+. If a block is given, will first
    # yield an instance of Rib to it and then base the mapping
    # definition on that.
    #
    # +options+ have several possible values:
    # * <tt>:db</tt> - the database to connect this model to
    #
    def define_ribs(on, options = {})
      rib = Rib.new
      yield rib if block_given?
       
      define_metadata_on_class on
      rm = on.ribs_metadata
      rm.rib = rib

      db = nil
      with_session(options[:db] || :default) do |s|
        db = s.db
        m = s.meta_data
        name = rib.table || table_name_for(on.name, m)

        tables = m.get_tables nil, nil, name.to_s, %w(TABLE VIEW ALIAS SYNONYM).to_java(:String)
        if tables.next
          table = Table.new(tables.get_string(3))
          rm.table = table
          c = tables.get_string(1)
          table.catalog = c if c && c.length > 0
          c = tables.get_string(2)
          table.schema = c if c && c.length > 0
          
          columns_rs = m.get_columns table.catalog, table.schema, table.name, nil

          while columns_rs.next
            c = Column.new(columns_rs.get_string(4))
            c.default_value = columns_rs.get_string(13)
            c.length = columns_rs.get_int(7)
            c.nullable = columns_rs.get_string(18) == 'YES'
            c.precision = columns_rs.get_int(10)
            c.scale = columns_rs.get_int(9)
            c.sql_type = columns_rs.get_string(6)
            c.sql_type_code = java.lang.Integer.new(columns_rs.get_int(5))

            table.add_column(c)
          end
          columns_rs.close rescue nil
          tables.close rescue nil
          
          pc = RubyRootClass.new
          pc.ruby_class = on
          pc.entity_name = on.name
          pc.table = table
          pc.add_tuplizer(org.hibernate.EntityMode::MAP, "org.jruby.ribs.RubyTuplizer")
          
          rm.persistent_class = pc
          
          table.column_iterator.each do |c|
            unless rib.to_avoid.include?(c.name.downcase)
              prop = Property.new
              prop.persistent_class = pc
              prop.name = ((v=rib.columns[c.name.downcase]) && v[0]) || c.name
              val = SimpleValue.new(table)
              val.add_column(c)
              val.type_name = get_type_for_sql(c.sql_type, c.sql_type_code)
              prop.value = val
              
              if (!rib.primary_keys.empty? && rib.primary_keys[c.name.downcase]) || c.name.downcase == 'id'
                pc.identifier_property = prop
                pc.identifier = val
              else
                pc.add_property(prop)
              end
              
              define_meat_accessor(on, prop.name)
            end
          end
          pc.create_primary_key
          db.mappings.add_class(pc)
        else
          tables.close rescue nil
          raise "No table found for: #{name}"
        end
      end
      
      db.reset_session_factory!
    end

    JTypes = java.sql.Types
    
    private
    # Defines the actual accessor for a specific property on a
    # class. This will define methods that use the Meat to get data.
    def define_meat_accessor(clazz, name)
      downcased = name.downcase
      clazz.class_eval <<CODE
  def #{downcased}
    self.__ribs_meat[:"#{name}"]
  end

  def #{downcased}=(value)
    self.__ribs_meat[:"#{name}"] = value
  end
CODE
    end

    # Returns the Java type for a specific combination of a type name
    # and an SQL type code
    def get_type_for_sql(name, code)
      case code
      when JTypes::VARCHAR
        "string"
      when JTypes::INTEGER
        "int"
      when JTypes::TIME
        "java.sql.Time"
      when JTypes::DATE
        "java.sql.Date"
      when JTypes::TIMESTAMP
        "java.sql.Timestamp"
      when JTypes::BLOB
        "java.sql.Blob"
      when JTypes::CLOB
        "java.sql.Clob"
      when JTypes::DOUBLE
        "double"
      when JTypes::SMALLINT
        "boolean"
      when JTypes::DECIMAL
        "java.math.BigDecimal"
      else
        $stderr.puts [name, code].inspect
        nil
      end
    end
    
    # Tries to figure out if a table name should be in lower case or
    # upper case, and returns the table name based on that.
    def table_name_for(str, metadata)
      if metadata.stores_lower_case_identifiers
        str.downcase
      elsif metadata.stores_upper_case_identifiers
        str.upcase!
      else
        str
      end
    end
    
    # Defines the meta data information on a class, and mixes in
    # ClassMethods and InstanceMethods to it.
    def define_metadata_on_class(clazz)
      clazz.instance_variable_set :@ribs_metadata, Ribs::MetaData.new
      class << clazz
        include ClassMethods
      end
      clazz.class_eval do 
        include InstanceMethods
      end
    end
  end
end
