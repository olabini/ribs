module Ribs
  class Meat
    attr_reader :properties
    
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
