module Ribs
  # Contains the mapping data that gets created when calling the
  # {Ribs!} method.
  class Rib
    # The proxy object returned when a property name is used in a call
    # to Rib without any parameters.
    class RibColumn
      # Sets the name and all the reference values
      def initialize(name, columns, primary_keys, to_avoid, default_values)
        @name, @columns, @primary_keys, @to_avoid, @default_values = 
          name.to_s, columns, primary_keys, to_avoid, default_values
      end
      
      # This name is a primary key
      def primary_key!
        @primary_keys << @name
      end
      
      # This name should be avoided in the database
      def avoid!
        @to_avoid << @name.downcase
      end
      
      # This name is mapped to a specific column
      def column=(col)
        @columns[@name] = [col.to_s, {}]
      end
    end

    # Value object that contains references to the Rib data
    class ColumnData
      # List of all the columns defined
      attr_reader :columns
      # List of all primary keys defined
      attr_reader :primary_keys
      # List of all columns to avoid
      attr_reader :to_avoid
      # List of default values for columns
      attr_reader :default_values

      attr_reader :associations

      # Sets all values
      def initialize(columns, primary_keys, to_avoid, default_values, associations)
        @columns, @primary_keys, @to_avoid, @default_values, @associations = 
          columns, primary_keys, to_avoid, default_values, associations
      end
    end

    # These are the only methods left alone - this becomes a blank
    # slate, mostly.
    METHODS_TO_LEAVE_ALONE = ['__id__', '__send__']
    undef_method *(instance_methods - METHODS_TO_LEAVE_ALONE)
    
    # Create all value parts
    def initialize
      @columns = { }
      @primary_keys = []
      @to_avoid = []
      @default_values = { }
      @associations = 
        {
        :belongs_to => { },
        :has_one    => { },
        :has_n      => { }
        }
    end
    
    # Returns a reference object that allow access to the resulting
    # data objects
    def __column_data__
      ColumnData.new(@columns, @primary_keys, @to_avoid, @default_values, @associations)
    end

    def belongs_to(*args)
      if args==[] || args.first.is_a?(Hash) || [:primary_key, :avoid, :default].include?(args.first)
        method_missing(:belongs_to, *args)
      else
        opts = args.grep(Hash).first || {}
        simple_name = args.first.to_s
        name = simple_name.gsub(/([[:lower:]][0-9]*)([[:upper:]]+)/, '\1_\2').downcase

        opts = {:column => "#{name}_id",
                :name => name}.merge(opts)

        @columns[name] = [opts[:column].to_s, opts, :belongs_to]
        @associations[:belongs_to][opts[:column]] = [opts[:name].to_s, simple_name, opts[:column], opts]
      end
    end

    def has_one(*args)
      if args==[] || args.first.is_a?(Hash) || [:primary_key, :avoid, :default].include?(args.first)
        method_missing(:has_one, *args)
      else
        opts = args.grep(Hash).first || {}
        simple_name = args.first.to_s
        name = simple_name.gsub(/([[:lower:]][0-9]*)([[:upper:]]+)/, '\1_\2').downcase

        opts = {:column => "#{name}_id",
                :name => name}.merge(opts)

        @columns[name] = [opts[:column].to_s, opts, :has_one]
        @associations[:has_one][opts[:column]] = [opts[:name].to_s, simple_name, opts[:column], opts]
      end
    end
    
    # Handles property names. The only ones that aren't possibly to
    # use is "initialize", "__column_data__", "__id__",
    # "method_missing" and "__send__". Everything else is
    # kosher. ... Maybe there should be a way of getting those last
    # ones too...
    #
    # If no arguments are supplied, will return a RibColumn
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
  end
end
