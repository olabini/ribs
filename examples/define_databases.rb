require 'rubygems'
require 'ribs'

Ribs::DB.define do |db|
  db.dialect = 'Derby'
  db.uri = 'jdbc:derby:blog;create=true'
  db.driver = 'org.apache.derby.jdbc.EmbeddedDriver'
end

Ribs::with_handle do |h|
  h.ddl "DROP TABLE blog" rescue nil
  h.ddl "DROP TABLE post" rescue nil

  h.ddl <<SQL
CREATE TABLE blog (
  id INT NOT NULL,
  title VARCHAR(255) NOT NULL,
  PRIMARY KEY (id)
)
SQL

  h.ddl <<SQL
CREATE TABLE post (
  id INT NOT NULL,
  title VARCHAR(255) NOT NULL,
  blog_id INT NOT NULL,
  PRIMARY KEY (id)
)
SQL
  
  template = <<SQL
INSERT INTO blog(id, title) VALUES(?, ?)
SQL
  
  h.insert("INSERT INTO blog(id, title) VALUES(?, ?)", 
           [1, "foobar"], 
           [2, "flux"])
  h.insert("INSERT INTO post(id, title, blog_id) VALUES(?, ?, ?)", 
           [1, "one", 1], 
           [2, "two", 1],
           [3, "three", 2])
end

