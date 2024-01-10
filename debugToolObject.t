#charset "us-ascii"
//
// debugToolObject.t
//
//
#include <adv3.h>
#include <en_us.h>

#include "debugTool.h"

#ifdef __DEBUG_TOOL

modify Object
	v2s(v) { return(reflectionServices.valToSymbol(v)); }

	_debugToolObj() {
		local l, r;

		r = new Vector();

		l = getPropList();
		l = l.sort(nil, { a, b: toString(a).compareTo(toString(b)) });
		l.forEach(function(o) {
			if(!propDefined(o, PropDefDirectly))
				return;
			r.append(v2s(o) + ' = ' + _debugProp(self, o));
		});


		return(r);
	}

	_debugProp(obj, prop, skip?) {
		switch(obj.propType(prop)) {
			case TypeDString:
				if(skip == true) return(nil);
				return('[double-quoted string]');
			case TypeCode:
				if(skip == true) return(nil);
				return('[executable code]');
			case TypeFuncPtr:
				if(skip == true) return(nil);
				return('[function pointer]');
			case TypeNativeCode:
				if(skip == true) return(nil);
				return('[native code]');
			case TypeBifPtr:
				if(skip == true) return(nil);
				return('[built-in function]');
			default:
				return(v2s(obj.(prop)));
		}
	}
;

#endif // __DEBUG_TOOL
