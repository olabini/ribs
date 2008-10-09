module Ribs
  # Keeps track of defined Ribs
  @ribs = {}

  class << self
    # Returns the specific metadata for a combination of model class
    # and database identifier. If there is no such entry, tries to
    # find the default entry for the model class.
    def metadata(db, model)
      @ribs[[db, model]] || @ribs[model]
    end

    # Adds metadata for a specific model and an optional database. If
    # the database is nil, it will add the model as a default metadata
    def add_metadata_for(db, model, metadata)
      if db
        @ribs[[db, model]] = metadata
      else
        @ribs[model] = metadata
      end
    end
    
    # Tries to find metadata for the model in question and defines new
    # metadata with define_ribs if no existing metadata exists. This
    # means that you should do your database definitions before using
    # the method R for that model.
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
    
    # Should this object be saved in an identity map?
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
  ManyToOne = org.hibernate.mapping.ManyToOne
  OneToOne = org.hibernate.mapping.OneToOne

  # A simple helper class that allows the Java parts of the system to
  # get the Ruby class from the PersistentClass instance.
  class RubyRootClass < org.hibernate.mapping.RootClass
    include org.jruby.ribs.WithRubyClass

    # The Ruby class
    attr_accessor :ruby_class
    
    # Initialize data for this RootClass
    def initialize(*args)
      super
      @data = {}
    end
    
    # Sets a specific data element
    def []=(key, value)
      @data[key] = value
    end
    
    # Get the Ruby class. Implementation of the WithRubyClass
    # interface.
    def getRubyClass
      @ruby_class
    end
    
    # Gets a specific data element
    def getRubyData(key)
      @data[key]
    end
  end

  # A Hibernate Property that can contain a Ruby value too.
  class RubyValuedProperty < org.hibernate.mapping.Property
    include org.jruby.ribs.WithRubyValue

    # The Ruby class
    attr_accessor :ruby_value
    
    # Creation
    def initialize(*args)
      super
    end
    
    # Implement the interface - return the actual Ruby value
    def getRubyValue
      @ruby_value
    end
  end
  
  class << self
    def ensure_valid_entity_name(db, name)
      R(eval(name), db || :default)
    end

    def define_delayed_ribs(on, options = {}, &block)
      unless options[:metadata]
        options[:metadata] = Ribs::MetaData.new      
      end

      rm = options[:metadata]
      Ribs::add_metadata_for(options[:db], on, rm)
      rm.identity_map = options.key?(:identity_map) ? options[:identity_map] : true

      with_simple_handle(options[:db] || :default) do |h|
        db = h.db
        m = h.meta_data

        name = table_name_for((options[:table] || on.name), m)

        tables = m.get_tables nil, nil, name.to_s, %w(TABLE VIEW ALIAS SYNONYM).to_java(:String)
        if tables.next
          rm.table = Table.new(tables.get_string(3))
        end
      end
      
      (@delayed ||= []) << [on, options, block]
    end

    def execute_delayed_ribs!
      delayed, @delayed = @delayed, []
      (delayed && delayed.each do |v|
        define_ribs(v[0], v[1], &v[2])
      end)
    end
    
    # Define a rib for the class +on+. If a block is given, will first
    # yield an instance of Rib to it and then base the mapping
    # definition on that.
    #
    # +options+ have several possible values:
    # * <tt>:db</tt> - the database to connect this model to
    #
    # This method is in urgent need of refactoring.
    #
    def define_ribs(on, options = {})
      rib = Rib.new
      yield rib if block_given?
      
      rm = options[:metadata]

      unless options[:from]
        options[:from] = R(on, options[:db] || :default)
      end

      rm.rib = rib
      rib_data = rib.__column_data__
      
      db = nil
      with_simple_handle(options[:db] || :default) do |h|
        db = h.db
        m = h.meta_data

        name = table_name_for((options[:table] || on.name), m)

        tables = m.get_tables nil, nil, name.to_s, %w(TABLE VIEW ALIAS SYNONYM).to_java(:String)
        if tables.next
          table = Table.new(tables.get_string(3))
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
            unless rib_data.to_avoid.include?(c.name.downcase)
              col_data = rib_data.columns.find{ |key, val| val[0].to_s.downcase == c.name.downcase} || [c.name, {}]
              unless col_data[1].length == 3 # It's an association
                prop = Property.new
                prop.persistent_class = pc
                prop.name = col_data[0]
                val = SimpleValue.new(table)
                val.add_column(c)
                val.type_name = get_type_for_sql(c.sql_type, c.sql_type_code)
                prop.value = val
                if (!rib_data.primary_keys.empty? && rib_data.primary_keys.include?(prop.name)) || c.name.downcase == 'id'
                  pc.identifier_property = prop
                  pc.identifier = val
                else
                  pc.add_property(prop)
                end
              end
            else
              if !c.nullable
                prop = RubyValuedProperty.new
                prop.ruby_value = rib_data.default_values[c.name.downcase]
                prop.persistent_class = pc
                prop.name = ((v=rib_data.columns[c.name.downcase]) && v[0]) || c.name
                val = SimpleValue.new(table)
                val.add_column(c)
                val.type_name = get_type_for_sql(c.sql_type, c.sql_type_code)
                prop.value = val
                pc.add_property(prop)
              end
            end
          end

          rib_data.associations[:belongs_to].each do |col_name, definition|
            prop = Property.new
            prop.persistent_class = pc
            prop.name = definition[0]
            val = ManyToOne.new(table)
            val.add_column(table.get_column(Column.new(col_name)))
            ensure_valid_entity_name(options[:db], definition[1])
            val.referenced_entity_name = definition[1]
            prop.value = val
            pc.add_property(prop)
          end

          rib_data.associations[:has_one].each do |col_name, definition|
            prop = Property.new
            prop.persistent_class = pc
            prop.name = definition[0]

            val = OneToOne.new(table, pc)
#            val.add_column(table.get_column(Column.new(col_name)))

            ensure_valid_entity_name(options[:db], definition[1]).metadata
            val.referenced_entity_name = definition[1]
            prop.value = val
            pc.add_property(prop)
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
