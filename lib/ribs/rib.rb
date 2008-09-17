module Ribs
  # Contains the mapping data that gets created when calling the
  # {Ribs!} method.
  class Rib
    class RibColumn
      def initialize(name, columns, primary_keys, to_avoid, default_values)
        @name, @columns, @primary_keys, @to_avoid, @default_values = 
          name.to_s, columns, primary_keys, to_avoid, default_values
      end
      
      def primary_key!
        @primary_keys << @name
      end
      
      def avoid!
        @to_avoid << @name.downcase
      end
      
      def column=(col)
        @columns[@name] = [col.to_s, {}]
      end
    end

    class ColumnData
      # List of all the columns defined
      attr_reader :columns
      # List of all primary keys defined
      attr_reader :primary_keys
      # List of all columns to avoid
      attr_reader :to_avoid
      # List of default values for columns
      attr_reader :default_values

      def initialize(columns, primary_keys, to_avoid, default_values)
        @columns, @primary_keys, @to_avoid, @default_values = columns, primary_keys, to_avoid, default_values
      end
    end

    METHODS_TO_LEAVE_ALONE = ['__id__', '__send__']
    undef_method *(instance_methods - METHODS_TO_LEAVE_ALONE)
    
    def initialize
      @columns = { }
      @primary_keys = []
      @to_avoid = []
      @default_values = { }
    end
    
    def __column_data__
      ColumnData.new(@columns, @primary_keys, @to_avoid, @default_values)
    end

    def method_missing(name, *args, &block)
      if args.empty?
        RibColumn.new(name, @columns, @primary_keys, @to_avoid, @default_values)
      else
        hsh = args.grep(Hash).first || {}
        args.grep(Symbol).each do |ss|
          hsh[ss] = true
        end
        
        hsh = {:column => name}.merge(hsh)
        
        if hsh[:primary_key]
          @primary_keys << name.to_s
        end

        if hsh[:avoid]
          @to_avoid << name.to_s.downcase
          if hsh[:default]
            @default_values[name.to_s.downcase] = hsh[:default]
          end
        end
        
        @columns[name.to_s] = [hsh[:column].to_s, hsh]
        nil
      end
    end
    
=begin
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
      options = {}
      if columns.last.kind_of?(Hash)
        columns, options = columns[0..-2], columns.last
      end
      names = columns.map{|s| s.to_s.downcase}
      @to_avoid += names
      if options[:default]
        names.each do |n|
          @default_values[n] = options[:default]
        end
      end
    end
=end
  end
end
