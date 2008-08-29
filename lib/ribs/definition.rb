module Ribs
  module ClassMethods
    attr_reader :ribs_metadata

    def new(attrs = {})
      obj = super()
      attrs.each do |k,v|
        obj.send :"#{k}=", v
      end
      obj
    end
    
    def create(attrs = {})
      val = new(attrs)
      val.save
      val
    end
    
    def find(id_or_sym)
      Ribs.with_session do |s|
        s.find(self.ribs_metadata.persistent_class.entity_name, id_or_sym)
      end
    end
  end
  
  module InstanceMethods
    def __ribs_meat
      @__ribs_meat ||= Ribs::Meat.new(self)
    end
        
    def inspect
      "#<#{self.class.name}: #{self.__ribs_meat.properties.inspect}>"
    end
    
    def save
      Ribs.with_session do |s|
        s.save(self)
      end
    end
  end
  
  class MetaData
    attr_accessor :table
    attr_accessor :persistent_class
    attr_accessor :rib
    
    def [](name)
#      $stderr.puts self.persistent_class.property_iterator.to_a.inspect
      self.persistent_class.get_property(name.to_s) rescue nil
    end

    def properties
      self.persistent_class.property_iterator.to_a.inject({}) do |h, value|
        h[value.name] = value
        h
      end
    end
  end

  class Rib
    attr_accessor :table
    attr_reader :columns
    attr_reader :primary_keys
    attr_reader :to_avoid

    def initialize
      @columns = { }
      @primary_keys = { }
      @to_avoid = []
    end
    
    def col(column, property = column, options = {})
      @columns[column.to_s.downcase] = [property.to_s, options]
    end
    
    def primary_key(column, property = column, options = {})
      @primary_keys[column.to_s.downcase] = property.to_s
      @columns[column.to_s.downcase] = [property.to_s, options]
    end
    
    def avoid(*columns)
      @to_avoid += columns.map{|s| s.to_s.downcase}
    end
  end
  
  Table = org.hibernate.mapping.Table
  Column = org.hibernate.mapping.Column
  Property = org.hibernate.mapping.Property
  SimpleValue = org.hibernate.mapping.SimpleValue

  class RubyRootClass < org.hibernate.mapping.RootClass
    include org.jruby.ribs.WithRubyClass

    attr_accessor :ruby_class
    
    def initialize(*args)
      super
    end
    
    def getRubyClass
      @ruby_class
    end
  end
  
  class << self
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
    
    def table_name_for(str, metadata)
      if metadata.stores_lower_case_identifiers
        str.downcase
      elsif metadata.stores_upper_case_identifiers
        str.upcase!
      else
        str
      end
    end
    
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
