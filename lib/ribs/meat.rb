module Ribs
  class Meat
    attr_reader :properties
    attr_accessor :persistent
    attr_accessor :destroyed
    
    def initialize(inside)
      @inside = inside
      @properties = {}
    end
    
    def [](ix)
      @properties[ix]
    end

    def []=(ix, value)
      @properties[ix] = value
    end
  end
end
