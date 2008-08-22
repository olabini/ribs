require 'java'

require 'antlr-2.7.6.jar'
require 'commons-collections-3.1.jar'
require 'dom4j-1.6.1.jar'
require 'javassist-3.4.GA.jar'
require 'jta-1.1.jar'
require 'slf4j-api-1.5.2.jar'
require 'slf4j-jdk14-1.5.2.jar'
require 'hibernate3.jar'
require 'ribs.jar'

require 'ribs/db'
require 'ribs/definition'
require 'ribs/session'
require 'ribs/meat'
require 'ribs/core_ext/time'

module Ribs
  class << self
    def with_session(from = :default)
      s = Ribs::Session.get(from)
      yield s
    ensure
      s.release
    end
  end
end

module Kernel
  def Ribs!(options = {}, &block)
    options.merge!({:on => self, :db => :default, :from => nil})
    Ribs::define_ribs(options[:on], options, &block)
  end
end
