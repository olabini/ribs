package org.jruby.ribs.persisters;

import org.jruby.ribs.WithRubyClass;

import java.io.Serializable;

import java.util.Comparator;
import java.util.Map;

import org.hibernate.EntityMode;
import org.hibernate.HibernateException;
import org.hibernate.LockMode;
import org.hibernate.cache.CacheConcurrencyStrategy;
import org.hibernate.cache.CacheConcurrencyStrategy;
import org.hibernate.cache.entry.CacheEntryStructure;
import org.hibernate.cache.access.EntityRegionAccessStrategy;
import org.hibernate.engine.CascadeStyle;
import org.hibernate.engine.Mapping;
import org.hibernate.engine.SessionFactoryImplementor;
import org.hibernate.engine.SessionImplementor;
import org.hibernate.engine.ValueInclusion;
import org.hibernate.id.IdentifierGenerator;
import org.hibernate.mapping.PersistentClass;
import org.hibernate.metadata.ClassMetadata;
import org.hibernate.persister.entity.EntityPersister;
import org.hibernate.tuple.entity.EntityMetamodel;
import org.hibernate.type.Type;
import org.hibernate.type.VersionType;

import org.jruby.RubyClass;

public class RubyObjectEntityPersister implements EntityPersister {
    private PersistentClass persistentClass;
    private EntityRegionAccessStrategy strategy;
    private SessionFactoryImplementor factory;
    private Mapping mapping;
    private RubyClass rclass;
    private EntityMetamodel entityMetamodel;

    public RubyObjectEntityPersister(PersistentClass persistentClass, EntityRegionAccessStrategy strategy, SessionFactoryImplementor factory, Mapping mapping) {
        this.persistentClass = persistentClass;
        this.strategy = strategy;
        this.factory = factory;
        this.mapping = mapping;
		this.entityMetamodel = new EntityMetamodel( persistentClass, factory );
        this.rclass = ((WithRubyClass)persistentClass).getRubyClass();
        System.err.println("getting a RubyObject with persistentClass: " + persistentClass + " factory: " + factory + " mapping: " + mapping + " rclass: " + rclass);
    }    

	public Comparator getVersionComparator() {
        System.err.println(" called getVersionComparator()");
        return null;
    }

    public void	afterInitialize(final Object entity, final boolean lazyPropertiesAreUnfetched, final SessionImplementor session) {
        System.err.println(" called afterInitialize()");
    }

    public void afterReassociate(final Object entity, final SessionImplementor session) {
        System.err.println(" called afterReassociate()");
    }
    
    public Object createProxy(final Serializable id, final SessionImplementor session) {
        System.err.println(" called createProxy()");
        return null;
    }

    public void delete(final Serializable id, final Object version, final Object object, final SessionImplementor session) {
        System.err.println(" called delete()");
    }

    public int[] findDirty(final Object[] x, final Object[] y, final Object owner, final SessionImplementor session) {
        System.err.println(" called findDiry()");
        return null;
    }

    public int[] findModified(final Object[] old, final Object[] current, final Object object, final SessionImplementor session) {
        System.err.println(" called findModified()");
        return null;
    }

    public Object forceVersionIncrement(Serializable id, Object currentVersion, SessionImplementor session) {
        System.err.println(" called forceVersionIncrement()");
        return null;
    }

    public CacheConcurrencyStrategy getCache() {
        System.err.println(" called getCache()");
        return null;
    }

	public EntityRegionAccessStrategy getCacheAccessStrategy() {
        System.err.println(" called getCacheAccessStrategy()");
        return null;
    }

    public CacheEntryStructure getCacheEntryStructure() {
        System.err.println(" called getCacheEntryStructure()");
        return null;
    }

    public ClassMetadata getClassMetadata() {
        System.err.println(" called getClassMetadata()");
        return null;
    }

    public Class getConcreteProxyClass(final EntityMode entityMode) {
        System.err.println(" called getConcreteProxyClass()");
        return null;
    }

    public Object getCurrentVersion(final Serializable id, final SessionImplementor session) {
        System.err.println(" called getCurrentVersion()");
        return null;
    }

    public Object[] getDatabaseSnapshot(final Serializable id, final SessionImplementor session) {
        System.err.println(" called getDatabaseSnapshot()");
        return null;
    }

    public String getEntityName() {
        System.err.println(" called getEntityName()");
        return persistentClass.getEntityName();
    }

    public SessionFactoryImplementor getFactory() {
        System.err.println(" called getFactory()");
        return factory;
    }

    public Serializable getIdentifier(final Object object, final EntityMode entityMode) {
        System.err.println(" called getIdentifier()");
        return null;
    }

    public IdentifierGenerator getIdentifierGenerator() {
        System.err.println(" called getIdentifiedGenerator()");
        return null;
    }

    public String getIdentifierPropertyName() {
        System.err.println(" called getIdentifierPropertyName()");
        return null;
    }

    public Type getIdentifierType() {
        System.err.println(" called getIdentifierType()");
		return entityMetamodel.getIdentifierProperty().getType();
    }

    public Class getMappedClass(final EntityMode entityMode) {
        System.err.println(" called getMappedClass()");
        return null;
    }

    public int[] getNaturalIdentifierProperties() {
        System.err.println(" called getNaturalIdentifiedProperties()");
        return new int[0];
    }

	public Object[] getNaturalIdentifierSnapshot(Serializable id, SessionImplementor session) {
        System.err.println(" called getNaturalIdentifierSnapshot()");
        return null;
    }

	public boolean canExtractIdOutOfEntity() {
        System.err.println(" called canExtractIdOutOfEntity()");
        return false;
    }

	public EntityMetamodel getEntityMetamodel() {
        System.err.println(" called getEntityMetamodel()");
        return null;
    }

    public CascadeStyle[] getPropertyCascadeStyles() {
        System.err.println(" called getPropertyCascadeStyles()");
        return new CascadeStyle[0];
    }

    public boolean[] getPropertyCheckability() {
        System.err.println(" called getPropertyCheckability()");
        return new boolean[0];
    }

    public boolean[] getPropertyInsertability() {
        System.err.println(" called getPropertyInsertability()");
        return new boolean[0];
    }

    public boolean[] getPropertyInsertGeneration() {
        System.err.println(" called getPropertyInsertGeneration()");
        return new boolean[0];
    }

	public ValueInclusion[] getPropertyUpdateGenerationInclusions() {
        System.err.println(" called getPropertyUpdateGenerationInclusions()");
        return null;
    }

	public ValueInclusion[] getPropertyInsertGenerationInclusions() {
        System.err.println(" called getPropertyInsertGenerationInclusions()");
        return null;
    }

    public boolean[] getPropertyLaziness() {
        System.err.println(" called getPropertyLaziness()");
        return new boolean[0];
    }

    public String[] getPropertyNames() {
        System.err.println(" called getPropertyNames()");
        return new String[0];
    }

    public boolean[] getPropertyNullability() {
        System.err.println(" called getPropertyNullability()");
        return new boolean[0];
    }

    public Serializable[] getPropertySpaces() {
        System.err.println(" called getPropertySpaces()");
        return new Serializable[0];
    }

    public Type getPropertyType(final String propertyName) {
        System.err.println(" called getPropertyType()");
        return null;
    }

    public Type[] getPropertyTypes() {
        System.err.println(" called getPropertyTypes()");
        return new Type[0];
    }

    public boolean[] getPropertyUpdateability() {
        System.err.println(" called getPropertyUpdateability()");
        return new boolean[0];
    }

    public boolean[] getPropertyUpdateGeneration() {
        System.err.println(" called getPropertyUpdateGeneration()");
        return new boolean[0];
    }

    public Object getPropertyValue(final Object object, final int i, final EntityMode entityMode) {
        System.err.println(" called getPropertyValue()");
        return null;
    }

    public Object getPropertyValue(final Object object, final String propertyName, final EntityMode entityMode) {
        System.err.println(" called getPropertyValue()");
        return null;
    }

    public Object[] getPropertyValues(final Object object, final EntityMode entityMode) {
        System.err.println(" called getPropertyValues()");
        return null;
    }

    public Object[] getPropertyValuesToInsert(final Object object, final Map mergeMap, final SessionImplementor session) {
        System.err.println(" called getPropertyValuesToInsert()");
        return null;
    }

    public boolean[] getPropertyVersionability() {
        System.err.println(" called getPropertyVersionability()");
        return new boolean[0];
    }

    public Serializable[] getQuerySpaces() {
        System.err.println(" called getQuerySpaces()");
        return new Serializable[0];
    }

    public String getRootEntityName() {
        System.err.println(" called getRootEntityName()");
		return getEntityName();
    }

    public EntityPersister getSubclassEntityPersister(final Object instance, final SessionFactoryImplementor factory, final EntityMode entityMode) {
        System.err.println(" called getSubclassEntityPersister()");
        return this;
    }

    public Object getVersion(final Object object, final EntityMode entityMode) {
        System.err.println(" called getVersion()");
        return null;
    }

    public int getVersionProperty() {
        System.err.println(" called getVersionProperty()");
        return -1;
    }

    public VersionType getVersionType() {
        System.err.println(" called getVersionType()");
        return null;
    }

    public EntityMode guessEntityMode(final Object object) {
        System.err.println(" called guessEntityMode()");
        return null;
    }

    public boolean hasCache() {
        System.err.println(" called hasCache()");
        return false;
    }

    public boolean hasCascades() {
        System.err.println(" called hasCascades()");
        return false;
    }

    public boolean hasCollections() {
        System.err.println(" called hasCollections()");
        return false;
    }
    
    public boolean hasIdentifierProperty() {
        System.err.println(" called hasIdentifierProperty()");
        return false;
    }
    
    public boolean hasIdentifierPropertyOrEmbeddedCompositeIdentifier() {
        System.err.println(" called hasIdentifierPropertyOrEmbeddedCompositeIdentifier()");
        return false;
    }
    
    public boolean hasInsertGeneratedProperties() {
        System.err.println(" called hasInsertGeneratedProperties()");
        return false;
    }
    
    public boolean hasLazyProperties() {
        System.err.println(" called hasLazyProperties()");
        return false;
    }
    
    public boolean hasMutableProperties() {
        System.err.println(" called hasMutableProperties()");
        return false;
    }
    
    public boolean hasNaturalIdentifier() {
        System.err.println(" called hasNaturalIdentifier()");
        return false;
    }
    
    public boolean hasProxy() {
        System.err.println(" called hasProxy()");
        return false;
    }
    
    public boolean hasSubselectLoadableCollections() {
        System.err.println(" called hasSubselectLoadableCollections()");
        return false;
    }
    
    public boolean hasUninitializedLazyProperties(final Object object, final EntityMode entityMode) {
        System.err.println(" called hasUninitializedLazyProperties()");
        return false;
    }
    
    public boolean hasUpdateGeneratedProperties() {
        System.err.println(" called hasUpdateGeneratedProperties()");
        return false;
    }
    
    public boolean implementsLifecycle(EntityMode entityMode) {
        System.err.println(" called implementsLifecycle()");
        return false;
    }
    
    public boolean implementsValidatable(EntityMode entityMode) {
        System.err.println(" called implementsValidatable()");
        return false;
    }

    public Serializable insert(final Object[] fields, final Object object, final SessionImplementor session) {
        System.err.println(" called insert()");
        return null;
    }

    public void insert(final Serializable id, final Object[] fields, final Object object, final SessionImplementor session) {
        System.err.println(" called insert()");
    }

    public Object instantiate(final Serializable id, final EntityMode entityMode) {
        System.err.println(" called instantiate()");
        return null;
    }

    public boolean isBatchLoadable() {
        System.err.println(" called isBatchLoadable()");
        return false;
    }

    public boolean isCacheInvalidationRequired() {
        System.err.println(" called isCacheInvalidationRequired()");
        return false;
    }

    public boolean isIdentifierAssignedByInsert() {
        System.err.println(" called isIdentifierAssignedByInsert()");
        return false;
    }

    public boolean isInherited() {
        System.err.println(" called isInherited()");
        return false;
    }

    public boolean isInstance(Object object, EntityMode entityMode) {
        System.err.println(" called isInstance()");
        return false;
    }

    public boolean isInstrumented(final EntityMode entityMode) {
        System.err.println(" called isInstrumented()");
        return false;
    }

    public boolean isLazyPropertiesCacheable() {
        System.err.println(" called isLazyPropertiesCacheable()");
        return false;
    }

    public boolean isMutable() {
        System.err.println(" called isMutable()");
        return false;
    }

    public boolean isSelectBeforeUpdateRequired() {
        System.err.println(" called isSelectBeforeUpdateRequired()");
        return false;
    }

    public boolean isSubclassEntityName(final String entityName) {
        System.err.println(" called isSubclassEntityName()");
        return false;
    }

    public Boolean isTransient(final Object object, final SessionImplementor session) {
        System.err.println(" called isTransient()");
        return Boolean.FALSE;
    }
    
    public boolean isVersioned() {
        System.err.println(" called isVersioned()");
        return false;
    }
    
    public boolean isVersionPropertyGenerated() {
        System.err.println(" called isVersionPropertyGenerated()");
        return false;
    }

    public Object load(final Serializable id, final Object optionalObject, final LockMode lockMode, final SessionImplementor session) throws HibernateException {
        System.err.println(" called load()");
        return null;
    }

    public void lock(final Serializable id, final Object version, final Object object, final LockMode lockMode, final SessionImplementor session) {
        System.err.println(" called lock()");
    }

    public void postInstantiate() {
        System.err.println(" called postInstantiate()");
    }

    public void processInsertGeneratedProperties(final Serializable id, final Object entity, final Object[] state, final SessionImplementor session) {
        System.err.println(" called processInsertGeneratedProperties()");
    }

    public void processUpdateGeneratedProperties(final Serializable id, final Object entity, final Object[] state, final SessionImplementor session) {
        System.err.println(" called processUpdateGeneratedProperties()");
    }

    public void resetIdentifier(final Object entity, final Serializable currentId, final Object currentVersion, final EntityMode entityMode) {
        System.err.println(" called resetIdentifier()");
    }

    public void setIdentifier(final Object object, final Serializable id, final EntityMode entityMode) {
        System.err.println(" called setIdentifier()");
    }

    public void setPropertyValue(final Object object, final int i, final Object value, final EntityMode entityMode) {
        System.err.println(" called setPropertyValue()");
    }

    public void setPropertyValues(final Object object, final Object[] values, final EntityMode entityMode) {
        System.err.println(" called setPropertyValues()");
    }

    public void update(final Serializable id, final Object[] fields, final int[] dirtyFields, final boolean hasDirtyCollection, final Object[] oldFields, final Object oldVersion, final Object object, final Object rowId, final SessionImplementor session) {
        System.err.println(" called update()");
    }
}
