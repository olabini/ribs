module Ribs
  class Session
    class NotConnectedError < StandardError;end

    class << self
      def get(from = :default)
        db = case from
             when :default
               Ribs::DB::get
             when Ribs::DB
               from
             else
               Ribs::DB::get(from)
             end
        db.session
      end
    end
    
    def initialize(db, hibernate_session)
      @db = db
      @connected = true
      @hibernate_session = hibernate_session
    end
    
    def release
      chk_conn
      @connected = false
      @db.release(self)
    end
    
    # LOW LEVEL - shouldn't be used
    def ddl(string)
      chk_conn
      execute(string)
    end
    
    # LOW LEVEL - shouldn't be used
    def insert(template, *data)
      chk_conn
      conn = @hibernate_session.connection
      stmt = conn.prepare_statement(template)
      data.each do |d|
        d.each_with_index do |item, index|
          set_prepared_statement(stmt, item, index+1)
        end
        stmt.execute_update
      end
    ensure
      stmt.close rescue nil
    end

    # LOW LEVEL - shouldn't be used
    def select(string)
      chk_conn
      conn = @hibernate_session.connection
      stmt = conn.create_statement
      rs = stmt.execute_query(string)
      result = []
      cols = rs.meta_data.column_count
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
    def chk_conn
      raise NotConnectedError unless @connected
    end
    
    def from_database_type(obj)
      case obj
      when String, Integer, NilClass
        obj
      when java.sql.Date, java.sql.Time, java.sql.Timestamp
        Time.at(obj.time/1000)
      end
    end
    
    def set_prepared_statement(stmt, item, index)
      case item
      when NilClass
        stmt.set_object index, nil
      when String
        stmt.set_string index, item
      when Symbol
        stmt.set_string index, item.to_s
      when Integer
        stmt.set_int index, item
      when Float
        stmt.set_float index, item
      when Time
        begin
          stmt.set_date index, item.to_java_sql_date
        rescue
          begin
            stmt.set_time_stamp index, item.to_java_sql_time_stamp
          rescue
            stmt.set_time index, item.to_java_sql_time
          end
        end
      when TrueClass, FalseClass
        stmt.set_boolean index, item
      else
        raise "Can't find correct type to set prepared statement for #{item.inspect}"
      end
    end
    
    def execute(string)
      conn = @hibernate_session.connection
      stmt = conn.create_statement
      stmt.execute_update(string)
    ensure
      stmt.close rescue nil
    end
  end
end
