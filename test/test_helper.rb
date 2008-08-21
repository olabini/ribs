require 'java'

lm = java.util.logging.LogManager.log_manager
lm.logger_names.each do |ln|
  lm.get_logger(ln).set_level(java.util.logging.Level::WARNING)
end

require 'rubygems'
require 'spec'
require 'ribs'

class Time
  def self.time_at(hrs, min, sec)
    Time.at(hrs*3600 + min*60 + sec)
  end

  def self.date_at(year, month, day)
    Time.local(year, month, day, 0, 0, 0)
  end
end

Ribs::DB.define do |db|
  # It's also possible to configure through JNDI here
  
  db.dialect = 'Derby'
  db.uri = 'jdbc:derby:test_database;create=true'
  db.driver = 'org.apache.derby.jdbc.EmbeddedDriver'
end

Ribs.with_session do |s|
  s.ddl "DROP TABLE DB_TRACK" rescue nil
  # GENERATED ALWAYS AS IDENTITY
  # Add new columns for TIMESTAMP, BINARY, DECIMAL, FLOAT, BOOLEAN
  s.ddl <<SQL
CREATE TABLE DB_TRACK (
  TRACK_ID INT NOT NULL,
  title VARCHAR(255) NOT NULL,
  filePath VARCHAR(255) NOT NULL,
  playTime TIME,
  added DATE,
  volume INT NOT NULL,
  PRIMARY KEY (TRACK_ID)
)
SQL

  
  template = <<SQL
INSERT INTO DB_TRACK(TRACK_ID, title, filePath, playTime, added, volume) VALUES(?, ?, ?, ?, ?, ?)
SQL
  
  
  s.insert(template, 
           [1, "foobar", "c:/abc/cde/foo.mp3", Time.time_at(14,50,0), Time.local(1984, 12, 13, 0,0,0), 13], 
           [2, "flux", "d:/abc/cde/flax.mp3", Time.time_at(16,23,0), Time.local(1983, 12, 13, 0,0,0), 13])
end

at_exit do 
  # Clean up derby files
  require 'fileutils'
  FileUtils.rm_rf('test_database')
  FileUtils.rm_rf('derby.log')
end
