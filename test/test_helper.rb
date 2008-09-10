require 'java'
require 'rubygems'
require 'spec'
require 'bigdecimal'
require 'ribs'

class Time
  def self.time_at(hrs, min, sec)
    Time.local(1970, 1, 1, hrs, min, sec)
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
  db.default = true
#   db.properties['hibernate.show_sql'] = 'true'
end

Ribs::DB.define(:flarg) do |db|
  db.dialect = 'Derby'
  db.uri = 'jdbc:derby:test_database_flarg;create=true'
  db.driver = 'org.apache.derby.jdbc.EmbeddedDriver'
end

Ribs::DB.define(:flurg) do |db|
  db.dialect = 'Derby'
  db.uri = 'jdbc:derby:test_database_flurg;create=true'
  db.driver = 'org.apache.derby.jdbc.EmbeddedDriver'
end

def reset_database!
  Ribs.with_handle(:flarg) do |h|
    h.ddl "DROP TABLE FAKEMODEL" rescue nil
    h.ddl "DROP TABLE FAKEMODEL_FAKESECONDMODEL" rescue nil
    h.ddl <<SQL
CREATE TABLE FAKEMODEL (
  ID INT NOT NULL
)
SQL
    h.ddl <<SQL
CREATE TABLE FAKEMODEL_FAKESECONDMODEL (
  ID INT NOT NULL
)
SQL
  end

  Ribs.with_handle(:flurg) do |h|
    h.ddl "DROP TABLE FAKEMODEL" rescue nil
    h.ddl "DROP TABLE FAKEMODEL_FAKESECONDMODEL" rescue nil
    h.ddl <<SQL
CREATE TABLE FAKEMODEL (
  ID INT NOT NULL
)
SQL
    h.ddl <<SQL
CREATE TABLE FAKEMODEL_FAKESECONDMODEL (
  ID INT NOT NULL
)
SQL
  end

  Ribs.with_handle do |h|
    h.ddl "DROP TABLE DB_TRACK" rescue nil
    h.ddl "DROP TABLE ARTIST" rescue nil
    h.ddl "DROP TABLE FAKEMODEL" rescue nil
    h.ddl "DROP TABLE FAKEMODEL_FAKESECONDMODEL" rescue nil

    # GENERATED ALWAYS AS IDENTITY
    # Add new columns for TIMESTAMP, BINARY, DECIMAL, FLOAT, BOOLEAN
    h.ddl <<SQL
CREATE TABLE DB_TRACK (
  TRACK_ID INT NOT NULL,
  title VARCHAR(255) NOT NULL,
  filePath VARCHAR(255) NOT NULL,
  playTime TIME,
  added DATE,
  volume INT NOT NULL,
  lastPlayed TIMESTAMP,
  data BLOB,
  description CLOB,
  fraction FLOAT,
  otherFraction DOUBLE,
  good SMALLINT,
  price DECIMAL(10,2),
  PRIMARY KEY (TRACK_ID)
)
SQL

    h.ddl <<SQL
CREATE TABLE ARTIST (
  ID INT NOT NULL,
  name VARCHAR(255) NOT NULL,
  PRIMARY KEY (ID)
)
SQL

    h.ddl <<SQL
CREATE TABLE FAKEMODEL (
  ID INT NOT NULL
)
SQL
    h.ddl <<SQL
CREATE TABLE FAKEMODEL_FAKESECONDMODEL (
  ID INT NOT NULL
)
SQL
    
    template = <<SQL
INSERT INTO DB_TRACK(TRACK_ID, title, filePath, playTime, added, volume, lastPlayed, data, description, fraction, otherFraction, good, price) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
SQL
    
    h.insert(template, 
             [1, "foobar", "c:/abc/cde/foo.mp3", [Time.time_at(14,50,0), :time], [Time.local(1984, 12, 13, 0,0,0), :date], 13, 
              [Time.local(1984, 12, 14, 12,3,11), :timestamp], ["abc", :binary], ["foobar", :text], 3.4, 5.7, true, BigDecimal.new("13134.11")], 
             [2, "flux", "d:/abc/cde/flax.mp3", [Time.time_at(16,23,0), :time], [Time.local(1983, 12, 13, 0,0,0), :date], 13,
              [Time.local(1982, 5, 3, 13,3,7), :timestamp], ["mumsi", :binary], ["maxi", :text], 3.5, 35435.4522234, false, BigDecimal.new("55454.33")])

    h.insert("INSERT INTO ARTIST(ID, name) VALUES(?, ?)", 
             [1, "Public Image Ltd"],
             [2, "New Model Army"],
             [3, "David Bowie"])
  end
end

reset_database!

at_exit do 
  require 'fileutils'
  FileUtils.rm_rf('test_database')
  FileUtils.rm_rf('test_database_flarg')
  FileUtils.rm_rf('test_database_flurg')
  FileUtils.rm_rf('derby.log')
end
