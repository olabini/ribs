/**
 * Copyright (c) 2008, Ola Bini <ola.bini@gmail.com>
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 * 
 * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the distribution.
 * 
 * Neither the name of the IT-Centrum, Karolinska Institutet, Sweden nor the names of its contributors may be used to endorse or
 * promote products derived from this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
package org.jruby.ribs;


import java.io.Serializable;
import java.lang.ref.WeakReference;
import java.util.HashMap;
import java.util.Map;
import org.hibernate.EmptyInterceptor;
import org.hibernate.EntityMode;
import org.hibernate.type.Type;
import org.jruby.Ruby;
import org.jruby.RubyModule;
import org.jruby.runtime.builtin.IRubyObject;

public class RubyInterceptor extends EmptyInterceptor {
    private Ruby runtime;
    private String dbname;
    private IRubyObject repositories;
    private IRubyObject dbrep = null;

    private Map<String, WeakReference<Object>> identityMap = new HashMap<String, WeakReference<Object>>();

    public RubyInterceptor(IRubyObject db, String dbname) {
        this.runtime = db.getRuntime();
        this.dbname = "DB_" + dbname;
        this.repositories = runtime.getModule("Ribs").getConstant("Repository");
    }

	public String getEntityName(Object object) {
		return ((IRubyObject)object).getType().getName().replace("::","_");
	}

	public Object getEntity(String entityName, Serializable id) {
        if(shouldCache(entityName)) {
            WeakReference<Object> ref = identityMap.get(entityName + "-" + id);
            if(ref != null) {
                return ref.get();
            }
        }
		return null;
	}

	public void onDelete(
			Object entity, 
			Serializable id, 
			Object[] state, 
			String[] propertyNames, 
			Type[] types) {
        String name = getEntityName(entity);
        if(shouldCache(name)) {
            identityMap.remove(name + "-" + id);
        }
    }

	public boolean onLoad(
			Object entity, 
			Serializable id, 
			Object[] state, 
			String[] propertyNames, 
			Type[] types) {
        String name = getEntityName(entity);
        if(shouldCache(name)) {
            identityMap.put(name + "-" + id, new WeakReference(entity));
        }
		return false;
	}

    private boolean shouldCache(String entityName) {
        if(dbrep == null) {
            dbrep = ((RubyModule)this.repositories).getConstant(dbname);
        }
        return ((RubyModule)dbrep)
            .getConstant(entityName)
            .callMethod(runtime.getCurrentContext(), "metadata")
            .callMethod(runtime.getCurrentContext(), "identity_map?")
            .isTrue();
    }
}
