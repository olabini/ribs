require 'java'

# Force logging to a lower level
lm = java.util.logging.LogManager.log_manager
lm.logger_names.each do |ln|
  lm.get_logger(ln).set_level(java.util.logging.Level::SEVERE)
end

# Everything needed for Hibernate
require 'antlr-2.7.6.jar'
require 'commons-collections-3.1.jar'
require 'dom4j-1.6.1.jar'
require 'javassist-3.4.GA.jar'
require 'jta-1.1.jar'
require 'slf4j-api-1.5.2.jar'
require 'slf4j-jdk14-1.5.2.jar'
require 'hibernate3.jar'

# Java parts of Ribs
require 'ribs.jar'

require 'bigdecimal'

require 'ribs/db'
require 'ribs/definition'
require 'ribs/session'
require 'ribs/meat'
require 'ribs/core_ext/time'

# The Ribs module includes most functionality needed for Ribs. The
# module is strictly a namespace and isn't generally supposed to be
# mixed in.
#
module Ribs
  class << self

    # The with_session method provides an easy way of working with a
    # low level Ribs session. It will get a session for the database
    # in question, yield that session to the block and then release
    # the session when finished. This should generally not be needed,
    # but wrapping a block if code with this method is a good way of
    # opening a session and make sure it doesn't get fully closed
    # until after the block.
    # 
    # +from+ decides which database definition to get a session for.
    #
    def with_session(from = :default)
      s = Ribs::Session.get(from)
      yield s
    ensure
      s.release
    end
  end
end

module Kernel

  # The main method for defining a Ribs model object can be used
  # either from inside the class to define it on, or outside by
  # providing a parameter for the class to act on. This gives some
  # flexibility about where definitions should go. The implementation
  # also keeps it open whether the model class is a real class or a
  # singleton class. The end result of calling the Ribs! method will
  # be to generate a definition for a database mapping, based on the
  # information provided inside the optional block. The block will
  # yield an object of type Ribs::Rib.
  #
  # +user_options+ currently takes these parameters:
  # * <tt>:on</tt> - The class to define this mapping on. Default will be the receiver of the method call.
  # * <tt>:db</tt> - The database to define this mapping for. <tt>:default</tt> is the default value.
  # * <tt>:from</tt> - The hibernate XML file to fetch mapping information from. By default nil, and currently doesn't do anything.
  #
  def Ribs!(user_options = {}, &block)
    default_options = {:on => self, :db => :default, :from => nil}
    options = default_options.merge user_options
    Ribs::define_ribs(options[:on], options, &block)
  end
end
