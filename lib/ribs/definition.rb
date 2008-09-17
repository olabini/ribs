module Ribs
  @ribs = {}

  class << self
    def metadata(db, model)
      @ribs[[db, model]] || @ribs[model]
    end

    def add_metadata_for(db, model, metadata)
      if db
        @ribs[[db, model]] = metadata
      else
        @ribs[model] = metadata
      end
    end
    
    def metadata_for(db, model, from)
      if (v = metadata(db, model))
        return v
      end

      metadata = Ribs::MetaData.new
      define_ribs(model, :db => db, :metadata => metadata, :from => from)
      metadata
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
    # Should this object be saved in an identity map?
    attr_accessor :identity_map
    
    def identity_map?
      self.identity_map
    end

    # Return the property instance for the given +name+.
    def [](name)
      self.persistent_class.get_property(name.to_s) rescue nil
    end

    # Return all the properties for this model.
    def properties
      self.persistent_class.property_iterator.to_a.inject({}) do |h, value|
        if !value.respond_to?(:getRubyValue)
          h[value.name] = value
        end
        h
      end
    end

    # Return all the properties for this model.
    def properties_and_identity
      (self.persistent_class.property_iterator.to_a + [self.persistent_class.identifier_property]).inject({}) do |h, value|
        if !value.respond_to?(:getRubyValue)
          h[value.name] = value
        end
        h
      end
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
      @data = {}
    end
    
    def []=(key, value)
      @data[key] = value
    end
    
    # Get the Ruby class. Implementation of the WithRubyClass
    # interface.
    def getRubyClass
      @ruby_class
    end
    
    def getRubyData(key)
      @data[key]
    end
  end

  class RubyValuedProperty < org.hibernate.mapping.Property
    include org.jruby.ribs.WithRubyValue

    # The Ruby class
    attr_accessor :ruby_value
    
    def initialize(*args)
      super
    end
    
    def getRubyValue
      @ruby_value
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
       
      unless options[:metadata]
        options[:metadata] = Ribs::MetaData.new      
      end

      rm = options[:metadata]
      Ribs::add_metadata_for(options[:db], on, rm)
      rm.identity_map = options.key?(:identity_map) ? options[:identity_map] : true

      unless options[:from]
        options[:from] = R(on, options[:db] || :default)
      end

      rm.rib = rib
      
      db = nil
      with_handle(options[:db] || :default) do |h|
        db = h.db
        m = h.meta_data

        name = table_name_for((rib.table || on.name), m)

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
          rm.persistent_class["meatspace"] = options[:from] if options[:from]
          
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
            else
              if !c.nullable
                prop = RubyValuedProperty.new
                prop.ruby_value = rib.default_values[c.name.downcase]
                prop.persistent_class = pc
                prop.name = ((v=rib.columns[c.name.downcase]) && v[0]) || c.name
                val = SimpleValue.new(table)
                val.add_column(c)
                val.type_name = get_type_for_sql(c.sql_type, c.sql_type_code)
                prop.value = val
                pc.add_property(prop)
              end
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
      str = str.to_s.gsub(/::/, '_')
      if metadata.stores_lower_case_identifiers
        str.downcase
      elsif metadata.stores_upper_case_identifiers
        str.upcase
      else
        str
      end
    end
  end
end
