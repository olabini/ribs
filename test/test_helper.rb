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

def delete_or_create(h, name, sql)
  begin
    h.delete_sql("DELETE FROM #{name}")
  rescue
    h.ddl <<SQL
CREATE TABLE #{name} (
#{sql}
)
SQL
  end
end

def fakemodels(h)
  delete_or_create(h, "FAKEMODEL",<<SQL)
  ID INT NOT NULL
SQL

  delete_or_create(h, "FAKEMODEL_FAKESECONDMODEL",<<SQL)
  ID INT NOT NULL
SQL
end

def reset_database!
  Ribs.with_handle(:flarg) do |h|
    fakemodels(h)
  end

  Ribs.with_handle(:flurg) do |h|
    fakemodels(h)
  end

  Ribs.with_handle do |h|
    fakemodels(h)
    
    # GENERATED ALWAYS AS IDENTITY
    delete_or_create(h, "DB_TRACK",<<SQL)
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
SQL

    delete_or_create(h, "ARTIST",<<SQL)
  ID INT NOT NULL,
  name VARCHAR(255) NOT NULL,
  PRIMARY KEY (ID)
SQL

    delete_or_create(h, "person",<<SQL)
  ID INT NOT NULL,
  given_name VARCHAR(255),
  sur_name VARCHAR(255) NOT NULL,
  age INT NOT NULL,
  PRIMARY KEY (ID)
SQL

    delete_or_create(h, "address",<<SQL)
  ID INT NOT NULL,
  street VARCHAR(255),
  postal VARCHAR(255),
  zip VARCHAR(255),
  country VARCHAR(255),
  PRIMARY KEY (ID)
SQL

    delete_or_create(h, "blog",<<SQL)
  ID INT NOT NULL,
  name VARCHAR(255),
  owner_id INT NOT NULL,
  PRIMARY KEY (ID)
SQL

    delete_or_create(h, "owner",<<SQL)
  ID INT NOT NULL,
  name VARCHAR(255),
  blog_id INT NOT NULL,
  PRIMARY KEY (ID)
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

    h.insert("INSERT INTO blog(ID, name, owner_id) VALUES(?, ?, ?)", 
             [1, "One", 1],
             [2, "Two", 2])

    h.insert("INSERT INTO owner(ID, name, blog_id) VALUES(?, ?, ?)", 
             [1, "Foo", 2],
             [2, "Bar", 1])
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
