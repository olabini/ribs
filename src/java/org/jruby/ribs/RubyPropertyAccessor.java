package org.jruby.ribs;

import java.lang.reflect.Method;
import java.math.BigDecimal;
import java.sql.Blob;
import java.sql.Clob;
import java.sql.SQLException;
import java.util.Date;
import java.util.Map;
import org.hibernate.HibernateException;
import org.hibernate.PropertyNotFoundException;
import org.hibernate.engine.SessionFactoryImplementor;
import org.hibernate.engine.SessionImplementor;
import org.hibernate.property.Getter;
import org.hibernate.property.PropertyAccessor;
import org.hibernate.property.Setter;
import org.jruby.Ruby;
import org.jruby.RubyBigDecimal;
import org.jruby.RubyTime;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.Block;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.util.ByteList;

public class RubyPropertyAccessor implements PropertyAccessor {
	private boolean isRubyProxy(Object o) {
		if(o instanceof IRubyObject) {
			return ((IRubyObject)o).getType().getName().equals("ActiveHibernate::RubyProxy");
		} else {
			return false;
		}
	}
	
	public Getter getGetter(Class theClass, final String propertyName) throws PropertyNotFoundException {
		return new Getter() {
			public Object get(Object owner) throws HibernateException {
				Ruby runtime = ((IRubyObject)owner).getRuntime();
				IRubyObject rubyValue = ((IRubyObject)owner).callMethod(runtime.getCurrentContext(),propertyName.toLowerCase());
				if(rubyValue instanceof RubyTime) {
					return ((RubyTime)rubyValue).getJavaDate();
				} else if(isRubyProxy(rubyValue)) {
					return rubyValue;
				} else {
					return JavaUtil.convertRubyToJava(rubyValue); 
				}
			}

			public Object getForInsert(Object owner, Map mergeMap, SessionImplementor session) throws HibernateException {
				return this.get(owner);
			}

			public Method getMethod() {
				return null;
			}

			public String getMethodName() {
				return null;
			}

			public Class getReturnType() {
				return Object.class;
            } 
		};
	}

	public Setter getSetter(Class theClass, final String propertyName) throws PropertyNotFoundException {
		return new Setter() {
			public Method getMethod() {
				return null;
			}

			public String getMethodName() {
				return null;
			}

			public void set(Object target, Object value, SessionFactoryImplementor factory)
					throws HibernateException {
				Ruby runtime = ((IRubyObject)target).getRuntime();
				
                try {
                    IRubyObject rubyObject = null;
                    if(value instanceof Date) {
                        long milisecs = ((Date)value).getTime();
                        rubyObject = RubyTime.newTime(runtime, milisecs);
                    } else if(value instanceof Blob) {
                        byte[] bytes = ((Blob)value).getBytes(1, (int)((Blob)value).length());
                        rubyObject = runtime.newString(new ByteList(bytes, false));
                    } else if(value instanceof Clob) {
                        String str = ((Clob)value).getSubString(1, (int)((Clob)value).length());
                        rubyObject = runtime.newString(str);
                    } else if(value instanceof BigDecimal) {
                        rubyObject = new RubyBigDecimal(runtime, (BigDecimal)value);
                    } else {
                        rubyObject = JavaUtil.convertJavaToRuby(runtime, value);
                    }
                    
                    ((IRubyObject)target).callMethod(runtime.getCurrentContext(),propertyName.toLowerCase()+"=",
                                                     new IRubyObject[] {rubyObject});
                } catch(SQLException e) {
                    throw new HibernateException(e);
                }
			}
		};
	}
}
