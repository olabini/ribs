require 'java'

lm = java.util.logging.LogManager.log_manager
lm.logger_names.each do |ln|
  lm.get_logger(ln).set_level(java.util.logging.Level::WARNING)
end

require 'rubygems'
require 'spec'
require 'ribs'

Ribs::DB.define do |db|
  # It's also possible to configure through JNDI here
  
  db.dialect = 'Derby'
  db.uri = 'jdbc:derby:test_database;create=true'
  db.driver = 'org.apache.derby.jdbc.EmbeddedDriver'
end

Ribs.with_session do |s|
  s.ddl "DROP TABLE DB_TRACK" rescue nil
  # GENERATED ALWAYS AS IDENTITY
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
           [1, "foobar", "c:/abc/cde/foo.mp3", Time.utc(0,1,1,14,50,0), Time.utc(1984, 12, 13, 12, 24, 12), 13], 
           [2, "flux", "d:/abc/cde/flax.mp3", Time.utc(0,1,1,16,23,0), Time.utc(1983, 12, 13, 12, 24, 12), 13])
end

at_exit do 
  # Clean up derby files
  require 'fileutils'
  FileUtils.rm_rf('test_database')
  FileUtils.rm_rf('derby.log')
end
