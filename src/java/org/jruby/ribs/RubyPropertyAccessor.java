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
import org.hibernate.mapping.Property;
import org.hibernate.property.Getter;
import org.hibernate.property.PropertyAccessor;
import org.hibernate.property.Setter;
import org.hibernate.type.Type;
import org.jruby.Ruby;
import org.jruby.RubyBigDecimal;
import org.jruby.RubyNumeric;
import org.jruby.RubyFixnum;
import org.jruby.RubyTime;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.Block;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.util.ByteList;

public class RubyPropertyAccessor implements PropertyAccessor {
    private Type type;
    private Object defaultValue;

    public RubyPropertyAccessor(Property property) {
        this.type = property.getType();
        if(property instanceof WithRubyValue) {
            defaultValue = JavaUtil.convertRubyToJava(((WithRubyValue)property).getRubyValue());
        }
    }

	private boolean isRubyProxy(Object o) {
		if(o instanceof IRubyObject) {
			return ((IRubyObject)o).getType().getName().equals("ActiveHibernate::RubyProxy");
		} else {
			return false;
		}
	}
	
	public Getter getGetter(final Class theClass, final String propertyName) throws PropertyNotFoundException {
		return new Getter() {
			public Object get(Object owner) throws HibernateException {
                if(defaultValue != null) {
                    return defaultValue;
                }

				Ruby runtime = ((IRubyObject)owner).getRuntime();
                String name = propertyName.toLowerCase();
                IRubyObject rubyValue;
                if(((IRubyObject)owner).respondsTo(name)) {
                    rubyValue = ((IRubyObject)owner).callMethod(runtime.getCurrentContext(),name);
                } else {
                    rubyValue = ((IRubyObject)owner).getInstanceVariables().getInstanceVariable("@" + name);
                }

				if(rubyValue instanceof RubyTime) {
					return ((RubyTime)rubyValue).getJavaDate();
                } else if(rubyValue instanceof RubyFixnum) {
                    return RubyNumeric.fix2int(rubyValue);
                } else if(rubyValue instanceof RubyBigDecimal) {
                    return ((RubyBigDecimal)rubyValue).getValue();
				} else if(isRubyProxy(rubyValue)) {
					return rubyValue;
                } else if(type.getReturnedClass() == java.sql.Blob.class) {
                    return new org.hibernate.lob.BlobImpl(rubyValue.convertToString().getBytes());
                } else if(type.getReturnedClass() == java.sql.Clob.class) {
                    return new org.hibernate.lob.ClobImpl(rubyValue.convertToString().toString());
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
                if(defaultValue != null) {
                    return;
                }
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
                    
                    String name = propertyName.toLowerCase();

                    if(((IRubyObject)target).respondsTo(name + "=")) {
                        ((IRubyObject)target).callMethod(runtime.getCurrentContext(),name + "=", rubyObject);
                    } else {
                        ((IRubyObject)target).getInstanceVariables().setInstanceVariable("@" + name, rubyObject);
                    }
                } catch(SQLException e) {
                    throw new HibernateException(e);
                }
			}
		};
	}
}
