module Ribs
  # A DB instance represents a specific database configuration,
  # including properties for the Hibernate connection.
  class DB
    Properties = java.util.Properties
    Environment = org.hibernate.cfg.Environment
    Configuration = org.hibernate.cfg.Configuration
    
    class << self
      # All the defined databases
      attr_accessor :databases
      
      # Defines a new database. Takes the name of the database as
      # parameter. There can only be one database with a specific name
      # at any time. The default name is <tt>:main</tt>. After
      # creating the DB instance, this will be yielded to the
      # block. This block needs to be provided. The db is not
      # registered until after the block has executed.
      #
      def define(name = :main)
        db = DB.new(name)

        yield db
        register db

        db.create

        db
      end
      
      # Will register a new database, making sure that one and only
      # one database is always the default. The rules are simple for
      # this: If the argument is the only database in the system, it
      # is the default. If there are more databases in the system, and
      # the argument has the default flag set, then all other
      # databases are reset to not be default.
      #
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
      
      # Gets the named database instance, or the default one if +name+
      # is nil.
      def get(name = nil)
        if name && name != :default
          self.databases[name]
        else
          self.databases.find do |name, db|
            db.default?
          end[1]
        end
      end
    end

    self.databases = {}

    # Name of the database. Default is <tt>:main</tt>
    attr_accessor :name
    # The JDBC uri of the database. This follows the same rules as
    # Hibernate JDBC URLs. It's necessary to provide this.
    attr_accessor :uri
    # Driver for the database connection. Necessary to provide.
    attr_accessor :driver
    # The database Hibernate dialect to use. This is currently
    # necessary. The available choices are:
    #
    # * Cache71
    # * DataDirectOracle9
    # * DB2390
    # * DB2400
    # * DB2
    # * Derby
    # * Firebird
    # * FrontBase
    # * H2
    # * HSQL
    # * Informix
    # * Ingres
    # * Interbase
    # * JDataStore
    # * Mckoi
    # * MimerSQL
    # * MySQL5
    # * MySQL5InnoDB
    # * MySQL
    # * MySQLInnoDB
    # * MySQLMyISAM
    # * Oracle9
    # * Oracle
    # * Pointbase
    # * PostgreSQL
    # * Progress
    # * RDBMSOS2200
    # * SAPDB
    # * SQLServer
    # * Sybase11
    # * SybaseAnywhere
    # * Sybase
    # * TimesTen
    # 
    # See the package org.hibernate.dialect at
    # http://www.hibernate.org/hib_docs/v3/api/ for an explanation of
    # the different dialects.
    attr_accessor :dialect
    # The username to connect with. Can be nil
    attr_accessor :username
    # The password to connect with. Can be nil
    attr_accessor :password
    # A hash of properties to pass on to hibernate. Can be any string
    # to string value.
    attr_accessor :properties
    # Is this database the default one? true or false.
    attr_accessor :default
    # All the mappings that have been defined for this database
    attr_reader :mappings
    
    # Creates the database with the specific name, or <tt>:main</tt>
    # if none is provided.
    def initialize(name = :main)
      self.name = name
      self.properties = {}
      class << self
        alias session_factory session_factory_create
      end
    end
    
    # Is this database the default?
    def default?
      self.default
    end

    # Creates the Hibernate Configuration object and the session
    # factory that provides connections to this database.
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
      @configuration.set_interceptor org.jruby.ribs.RubyInterceptor.new(self, (self.default? ? :default : self.name).to_s)
      @mappings = @configuration.create_mappings
      @simple_configuration = Configuration.new.add_properties(properties)
      @simple_session_factory = @simple_configuration.build_session_factory
      reset_session_factory!
    end

    # Resets the session factory. This is necessary after some
    # configuration changes have happened.
    def reset_session_factory!
      if @session_factory
        @session_factory = nil
        class << self
          alias session_factory session_factory_create
        end
      end
    end
    
    def session_factory_create
      @session_factory = @configuration.build_session_factory
      class << self
        alias session_factory session_factory_return
      end
      @session_factory
    end

    def session_factory_return
      @session_factory
    end
    
    # Fetch a new Ribs handle connected to the this database. Returns
    # a Ribs::Handle object.
    def handle
      sessions = (Thread.current[:ribs_db_sessions] ||= {})
      if curr = sessions[self.object_id]
        curr[1] += 1 #reference count
        Handle.new(self, curr[0])
      else
        sess = self.session_factory.open_session
        sessions[self.object_id] = [sess,1]
        Handle.new(self, sess)
      end
    end

    # Fetch a new simple Ribs handle connected to the this database. Returns
    # a Ribs::Handle object.
    def simple_handle
      sessions = (Thread.current[:ribs_db_simple_sessions] ||= {})
      if curr = sessions[self.object_id]
        curr[1] += 1 #reference count
        Handle.new(self, curr[0])
      else
        sess = @simple_session_factory.open_session
        sessions[self.object_id] = [sess,1]
        Handle.new(self, sess)
      end
    end
    
    # Release a Ribs::Handle object that is connected to this
    # database. That Handle object should not be used after this
    # method has been invoked.
    def release(handle)
      res = Thread.current[:ribs_db_sessions][self.object_id]
      if res[0] == handle.hibernate_session
        res[1] -= 1
        if res[1] == 0
          res[0].close
          Thread.current[:ribs_db_sessions].delete(self.object_id)
        end
      end
    end

    # Release a simple Ribs::Handle object that is connected to this
    # database. That Handle object should not be used after this
    # method has been invoked.
    def simple_release(handle)
      res = Thread.current[:ribs_db_simple_sessions][self.object_id]
      if res[0] == handle.hibernate_session
        res[1] -= 1
        if res[1] == 0
          res[0].close
          Thread.current[:ribs_db_simple_sessions].delete(self.object_id)
        end
      end
    end
  end
end
