require 'ribs'

Ribs::DB.define do |db|
  db.dialect = 'Derby'
  db.uri = 'jdbc:derby:blog'
  db.driver = 'org.apache.derby.jdbc.EmbeddedDriver'
end

class Blog
  Ribs!
end

class Post; end

Ribs! :on => Post

blogs = Blog.find :all
p blogs[0].title
