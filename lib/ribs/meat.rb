module Ribs
  # The Meat is what actually includes data. This is the holder object
  # for all data that comes from a database. This allows Ribs to avoid
  # polluting model objects with loads of instance variables. Instead
  # everything is kept in one instance of Meat. The Meat also keeps
  # track of whether the object is persistent or if it's been
  # destroyed. Note that Meat is very implementation dependent, and
  # should not be relied upon.
  class Meat
    # All the data for this instance
    attr_reader :properties
    # Is this instance persistent yet, or not?
    attr_accessor :persistent
    # Has this instance been destroyed?
    attr_accessor :destroyed
    
    # +inside+ is the instance this Meat belongs to.
    def initialize(inside)
      @inside = inside
      @properties = {}
    end
    
    # Gets the current value of a property
    def [](ix)
      @properties[ix]
    end

    # Sets the current value of a property
    def []=(ix, value)
      @properties[ix] = value
    end
  end
end
