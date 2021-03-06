module Ribs
  # A Ribs handle maps many-to-one with a Hibernate session. When
  # there are no more Ribs handles left, the Hibernate session will
  # be released too.
  #
  # The methods in Handle is not to be used outside the framework in
  # most cases, since they are internal, brittle, not based on
  # Hibernate in all cases, and very much subject to change. Currently
  # they provide capabilities that aren't part of the framework yet,
  # such as migrations and setting up test data.
  #
  class Handle
    # This error is thrown when an operation on a handle is
    # attempted but the internal Hibernate session has already
    # been closed.
    #
    class NotConnectedError < StandardError;end

    class << self
      # Returns a handle object from the database +from+. The
      # available values for from is either one of the existing
      # defined database names, or <tt>:default</tt>, which will give
      # a handle to the default database.
      #
      def get(from = :default)
        db = case from
             when :default
               Ribs::DB::get
             when Ribs::DB
               from
             else
               Ribs::DB::get(from)
             end
        db.handle
      end

      def get_simple(from = :default)
        db = case from
             when :default
               Ribs::DB::get
             when Ribs::DB
               from
             else
               Ribs::DB::get(from)
             end
        db.simple_handle
      end
    end
    
    # The current database for this handle
    attr_reader :db
    
    # Creates a new handle that points to the provided +db+ and
    # +hibernate_session+
    #
    def initialize(db, hibernate_session)
      @db = db
      @connected = true
      @hibernate_session = hibernate_session
    end
    
    # Releases this handle from the database.  This will possibly
    # result in closing the internal Hibernate session, if this is the
    # last Ribs session pointing to that Hibernate session.
    def release
      chk_conn
      @connected = false
      @db.release(self)
    end

    def simple_release
      chk_conn
      @connected = false
      @db.simple_release(self)
    end
    
    # LOW LEVEL - shouldn't be used except by Ribs
    def hibernate_session # :nodoc:
      @hibernate_session
    end
    
    # LOW LEVEL - shouldn't be used except by Ribs
    def get(entity_name, id) # :nodoc:
      chk_conn
      @hibernate_session.get(entity_name, java.lang.Integer.new(id))
    end

    # LOW LEVEL - shouldn't be used except by Ribs
    def all(entity_name) # :nodoc:
      chk_conn
      @hibernate_session.create_criteria(entity_name).list.to_a
    end
    
    # LOW LEVEL - shouldn't be used except by Ribs
    def update_obj(obj) # :nodoc:
      chk_conn
      tx = @hibernate_session.begin_transaction
      @hibernate_session.update(obj)
      tx.commit
      obj
    end

    # LOW LEVEL - shouldn't be used except by Ribs
    def insert_obj(obj) # :nodoc:
      chk_conn
      tx = @hibernate_session.begin_transaction
      @hibernate_session.save(obj)
      tx.commit
      obj
    end
    
    # LOW LEVEL - shouldn't be used except by Ribs
    def delete(obj) # :nodoc:
      chk_conn
      tx = @hibernate_session.begin_transaction
      @hibernate_session.delete(obj)
      tx.commit
      obj
    end
    
    # LOW LEVEL - shouldn't be used except by Ribs
    def meta_data # :nodoc:
      chk_conn
      @hibernate_session.connection.meta_data
    end
    
    # LOW LEVEL - shouldn't be used except by Ribs
    def ddl(string) # :nodoc:
      chk_conn
      execute(string)
    end

    # LOW LEVEL - shouldn't be used except by Ribs
    def delete_sql(string) # :nodoc:
      chk_conn
      execute(string)
    end
    
    # LOW LEVEL - shouldn't be used except by Ribs
    def insert(template, *data) # :nodoc:
      chk_conn
      conn = @hibernate_session.connection
      stmt = conn.prepare_statement(template)
      data.each do |d|
        d.each_with_index do |item, index|
          if item.kind_of?(Array)
            set_prepared_statement(stmt, item[0], index+1, item[1])
          else
            set_prepared_statement(stmt, item, index+1, nil)
          end
        end
        stmt.execute_update
      end
      conn.commit
    ensure
      stmt.close rescue nil
    end

    # LOW LEVEL - shouldn't be used except by Ribs
    def select(string) # :nodoc:
      chk_conn
      conn = @hibernate_session.connection
      stmt = conn.create_statement
      rs = stmt.execute_query(string)
      result = []
      meta = rs.meta_data
      cols = meta.column_count
      while rs.next
        row = []
        (1..cols).each do |n|
          row << from_database_type(rs.get_object(n))
        end
        result << row
      end
      result
    ensure
      rs.close rescue nil
      stmt.close rescue nil
    end
    
    private
    # Raise a NotConnectedError if not connected
    def chk_conn
      raise NotConnectedError unless @connected
    end
    
    # Tries to turn a Java object from the database into an equivalent
    # Ruby object. Currently supports:
    #
    # * Strings
    # * Floats
    # * Integers
    # * nil
    # * booleans
    # * Dates
    # * Times
    # * Timestamps
    # * Blobs
    # * Clobs
    # * BigDecimals
    def from_database_type(obj)
      case obj
      when String, Float, Integer, NilClass, TrueClass, FalseClass
        obj
      when java.sql.Date, java.sql.Time, java.sql.Timestamp
        Time.at(obj.time/1000)
      when java.sql.Blob
        String.from_java_bytes(obj.get_bytes(1,obj.length))
      when java.sql.Clob
        obj.get_sub_string(1, obj.length)
      when java.math.BigDecimal
        BigDecimal.new(obj.to_s)
      else
        raise "Can't find correct type to convert #{obj.inspect} into"
      end
    end

    # Tries to set an entry on a prepared statement, based on type
    def set_prepared_statement(stmt, item, index, type)
      case item
      when NilClass
        stmt.set_object index, nil
      when String
        case type
        when :binary
          stmt.set_bytes index, item.to_java_bytes
        when :text
          stmt.set_string index, item
        else
          stmt.set_string index, item
        end
      when Symbol
        stmt.set_string index, item.to_s
      when Integer
        stmt.set_int index, item
      when Float
        stmt.set_float index, item
      when Time
        case type
        when :date
          stmt.set_date index, item.to_java_sql_date
        when :time
            stmt.set_time index, item.to_java_sql_time
        when :timestamp
          stmt.set_timestamp index, item.to_java_sql_time_stamp
        end
      when BigDecimal
        stmt.set_big_decimal index, java.math.BigDecimal.new(item.to_s('F'))
      when TrueClass, FalseClass
        stmt.set_boolean index, item
      else
        raise "Can't find correct type to set prepared statement for #{item.inspect}"
      end
    end

    # Executes a SQL string against the current hibernate
    # session. This should be an updating SQL string, not a query.
    def execute(string)
      conn = @hibernate_session.connection
      stmt = conn.create_statement
      stmt.execute_update(string)
      conn.commit
    ensure
      stmt.close rescue nil
    end
  end
end
