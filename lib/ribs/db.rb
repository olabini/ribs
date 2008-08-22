module Ribs
  class DB
    Properties = java.util.Properties
    Environment = org.hibernate.cfg.Environment
    Configuration = org.hibernate.cfg.Configuration
    
    class << self
      attr_accessor :databases
      
      def define(name = :main)
        db = DB.new(name)

        yield db
        register db

        db.create

        db
      end
      
      def register(db)
        if self.databases.empty?
          db.default = true
        elsif db.default?
          self.databases.each do |name, db|
            db.default = false
          end
        end
        self.databases[db.name] = db
      end
      
      def get(name = nil)
        if name
          self.databases[name]
        else
          self.databases.find do |name, db|
            db.default?
          end[1]
        end
      end
    end

    self.databases = {}

    attr_accessor :name
    attr_accessor :uri
    attr_accessor :driver
    attr_accessor :dialect
    attr_accessor :username
    attr_accessor :password
    attr_accessor :properties
    attr_accessor :default
    attr_reader :mappings
    
    def initialize(name = :main)
      self.name = name
      self.properties = {}
    end
    
    def default?
      self.default
    end

    def create
      properties = Properties.new
      properties.set_property(Environment::DIALECT, "org.hibernate.dialect.#{self.dialect}Dialect") if self.dialect
      properties.set_property(Environment::USER, self.username) if self.username
      properties.set_property(Environment::PASS, self.password) if self.password
      properties.set_property(Environment::URL, self.uri) if self.uri
      properties.set_property(Environment::DRIVER, self.driver) if self.driver
      self.properties.each do |key, value|
        properties.set_property(key, value)
      end
      @configuration = Configuration.new.add_properties(properties)
      @mappings = @configuration.create_mappings
      reset_session_factory!
    end

    def reset_session_factory!
      @session_factory = @configuration.build_session_factory
    end
    
    def session
      sessions = (Thread.current[:ribs_db_sessions] ||= {})
      if curr = sessions[self.object_id]
        curr[1] += 1 #reference count
        Session.new(self, curr[0])
      else
        sess = @session_factory.open_session
        sessions[self.object_id] = [sess,1]
        Session.new(self, sess)
      end
    end
    
    def release(session)
      res = Thread.current[:ribs_db_sessions][self.object_id]
      if res[0] == session.hibernate_session
        res[1] -= 1
        if res[1] == 0
          res[0].close
          Thread.current[:ribs_db_sessions].delete(self.object_id)
        end
      end
    end
  end
end
