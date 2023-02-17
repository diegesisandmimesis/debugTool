#charset "us-ascii"
#include <adv3.h>
#include <en_us.h>

#include "debugTool.h"

// Module ID for the library
debugToolModuleID: ModuleID {
        name = 'Debug Tool Library'
        byline = 'Diegesis & Mimesis'
        version = '1.0'
        listingOrder = 99
}

// Mixin class for widgets that want to use __debugTool for debugging
// output
class DebugTool: object
	debugToolPrefix = 'DebugTool'
	_debug(msg) { __debugTool._debug(debugToolPrefix, msg); }
	_error(msg) { __debugTool._error(debugToolPrefix, msg); }
;

__debugTool: object
	// Default prefix for debugging output
	prefix = 'debugTool'

	// Character to use to indent.
	_indentChr = '\t'

	// Output munger.
	// By default we expect to use __debugTool._debug('message to log')
	// to produce:
	//
	//	debugTool:  message to log
	//
	// Individual widgets using this module can do something like:
	//
	// class MyWidget: Thing, DebugTool
	//	debugPrefix = 'myWidget'
	//
	// Then MyWidget._debug('this is some logging output') will produce
	//
	//	myWidget:  this is some logging output
	//	
	_format(svc, msg, ind) {
		local i, r;

		r = new StringBuffer();

		if((svc == nil) && (msg == nil)) return(nil);
		if(msg == nil) {
			msg = svc;
			svc = prefix;
		}
		if(svc) {
			r.append(svc);
			r.append(': ');
		}
		if(ind) {
			for(i = 0; i < ind; i++)
				r.append(_indentChr);
		}
		r.append(msg);

		return(r);
	}

	_indent(n?) {
		local i, r;

		if(n == nil) n = 1;
		r = new StringBuffer(n * 2);
		for(i = 0; i < n; i++)
			r.append(_indentChr);

		return(toString(r));
	}

	_debug(svc, msg?, ind?) {}
	_error(svc, msg?) { "\n<<_format(svc, msg, nil)>>\n "; }

	// Convenience wrapper for the library's method.
	valToSymbol(v) { return(reflectionServices.valToSymbol(v)); }
;

#ifdef __DEBUG_TOOL
modify __debugTool
	_debug(svc, msg?, ind?) { "\n<<_format(svc, msg, ind)>>\n "; }
;

#endif // __DEBUG_TOOL
