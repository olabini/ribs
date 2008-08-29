package org.jruby.ribs;

import org.hibernate.EntityMode;
import org.hibernate.HibernateException;
import org.hibernate.mapping.PersistentClass;
import org.hibernate.mapping.Property;
import org.hibernate.property.Getter;
import org.hibernate.property.PropertyAccessor;
import org.hibernate.property.Setter;
import org.hibernate.proxy.ProxyFactory;
import org.hibernate.tuple.Instantiator;
import org.hibernate.tuple.entity.EntityMetamodel;
import org.hibernate.tuple.entity.AbstractEntityTuplizer;
import org.jruby.runtime.builtin.IRubyObject;

public class RubyTuplizer extends AbstractEntityTuplizer {
	public RubyTuplizer(EntityMetamodel entityMetamodel, PersistentClass mappedEntity) {
		super(entityMetamodel, mappedEntity);
	}

	protected Instantiator buildInstantiator(PersistentClass mappingInfo) {
		return new RubyInstantiator(mappingInfo);
	}

	private PropertyAccessor buildPropertyAccessor(Property mappedProperty) {
		if ( mappedProperty.isBackRef() ) {
			return mappedProperty.getPropertyAccessor(null);
		}
		else {
			return new RubyPropertyAccessor(mappedProperty.getType());
		}
	}
	
	protected Getter buildPropertyGetter(Property mappedProperty, PersistentClass mappedEntity) {
		return buildPropertyAccessor(mappedProperty).getGetter( null, mappedProperty.getName() );
	}

	protected Setter buildPropertySetter(Property mappedProperty, PersistentClass mappedEntity) {
		return buildPropertyAccessor(mappedProperty).getSetter( null, mappedProperty.getName() );
	}

	protected ProxyFactory buildProxyFactory(PersistentClass mappingInfo, Getter idGetter, Setter idSetter) {
        return null;
	}

	protected EntityMode getEntityMode() {
		return EntityMode.MAP;
	}

	public Class getConcreteProxyClass() {
		return IRubyObject.class;
	}

	public boolean isInstrumented() {
		return false;
	}

	public Class getMappedClass() {
		return IRubyObject.class;
	}
}
