package org.jruby.ribs;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.runtime.builtin.IRubyObject;

import java.io.Serializable;

import org.hibernate.mapping.PersistentClass;
import org.hibernate.tuple.Instantiator;
import org.hibernate.mapping.Component;


public class RubyInstantiator implements Instantiator {
    private RubyClass rc;

	public RubyInstantiator(Component component) {
	}
	
	public RubyInstantiator(PersistentClass mappingInfo) {
        rc = ((WithRubyClass)mappingInfo).getRubyClass();
	}
	
	public Object instantiate(Serializable id) {
		Ruby runtime = rc.getRuntime();
		RubyClass rubyClass = rc;
		IRubyObject ro = rubyClass.newInstance(runtime.getCurrentContext(), new IRubyObject[0], null);
        ro.callMethod(runtime.getCurrentContext(), "__ribs_meat").callMethod(runtime.getCurrentContext(), "persistent=", runtime.getTrue());
		return ro;
	}

	public Object instantiate() {
		return this.instantiate(null);
	}

	public boolean isInstance(Object object) {
		return object instanceof IRubyObject;
	}
}
