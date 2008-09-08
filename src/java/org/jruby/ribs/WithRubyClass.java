package org.jruby.ribs;

import org.jruby.RubyClass;
import org.jruby.runtime.builtin.IRubyObject;

public interface WithRubyClass {
    public RubyClass getRubyClass();
    public IRubyObject getRubyData(String name);
}
