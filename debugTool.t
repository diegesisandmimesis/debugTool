#charset "us-ascii"
#include <adv3.h>
#include <en_us.h>

//#include <reflect.t>

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

	//stackFrameWrapper0 = '=====New Stack Frame====='
	//stackFrameWrapper1 = nil

	// Line to print before any output produced in the breakpoint.
	// Can be nil.
	//breakpointWrapper = '=====Breakpoint Output====='

	// What to print when waiting for a keypress at a breakpoint.
	// Can be nil.
	//breakpointPrompt = '[Press any key to continue]'

	// When displaying file names, use only the base, not the full path.
	//shortPaths = true

	// Used by the path shortening logic.  This is the character used
	// to divide paths in a filename.
	//_pathSeparator = '/'

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

	_debug(svc, msg?, ind?) {}
	_error(svc, msg?) { "\n<<_format(svc, msg, nil)>>\n "; }

/*
	// Set a "breakpoint"
	// Args are:
	//	cb	a callback function
	//	ctx	optional context for the callback
	// If no context is specified, the callback will be invoked as
	// if it's a method on the __debugTools object, unless it's an
	// anonymous function.
	//
	// Ex:
	//	// Set a breakpoint that will call __debugTools.localVariables()
	//	__debugTools.breakpoint(&localVariables);
	//
	//	// Set a breakpoint that will call self.foozle(), where self
	//	// whoever the caller is.
	//	__debugTools.breakpoint(&foozle, self);
	//
	//	// Set a breakpoint with no callback
	//	__debugTools.breakpoint();
	breakpoint(cb?, ctx?) {
		if(breakpointWrapper) _debug(breakpointWrapper);
		_breakpointCallback(cb, ctx, 2);
		if(breakpointWrapper) _debug(breakpointWrapper);
		if(breakpointPrompt) _debug(breakpointPrompt);
		for(;;) {
			inputManager.getKey(nil, nil);
			return;
		}
	}
	_breakpointCallback(cb, ctx, depth) {
		switch(dataTypeXlat(cb)) {
			case TypeList:
				cb.forEach(function(o) {
					_breakpointCallback(o, ctx, depth + 3);
				});
				break;
			case TypeProp:
				if(ctx != nil)
					ctx.(cb)();
				else
					self.(cb)(depth + 1);
				break;
			case TypeFuncPtr:
				cb();
				break;
		}
	}
*/

	// Convenience wrapper for the library's method.
	valToSymbol(v) { return(reflectionServices.valToSymbol(v)); }

/*
	// Lifted more or less directly from reflect.t
	formatStackFrame(fr, includeSourcePos) {
		local ar, fn, i, len, ret;

		ret = new StringBuffer();
        
		if(fr.func_ != nil) {
			ret.append(valToSymbol(fr.func_));
		} else if(fr.obj_ != nil) {
			if(fr.obj_.ofKind(AnonFuncPtr)) {
				ret.append('{anonFunc}');
			} else {
				ret.append(valToSymbol(fr.self_));
				ret.append('.');
				ret.append(valToSymbol(fr.prop_));
			}
		} else {
			ret.append('(System)');
		}
		if(fr.argList_ != nil) {
			ret.append('(');
			len = fr.argList_.length();
			for(i = 1; i <= len; ++i) {
				if(i != 1) ret.append(', ');
				ret.append(valToSymbol(fr.argList_[i])
					.htmlify());
			}
			if(fr.namedArgs_ != nil) {
				fr.namedArgs_.forEachAssoc(function(key, val) {
					if(i++ != 1) ret.append(', ');

					ret.append(key);
					ret.append(':');
					ret.append(valToSymbol(val));
				});
			}
			ret.append(')');
			if(includeSourcePos && fr.srcInfo_ != nil) {
				ret.append(' ');

				// This is our addition to the method;
				// a way to shorten path names.
				fn = fr.srcInfo_[1];
				if(shortPaths) {
					// Kludgily split the full filename
					// at the separator(s)...
					ar = fn.split(_pathSeparator);

					// ...and then paste the last two
					// bits together.  Since filenames
					// have to be unique in a compilation,
					// this should be more than enough.
					// If we don't have two elements
					// (because the source was in the
					// "current" direction at compile-time)
					// we don't do anything (fn already
					// contains the bare filename).
					if(ar.length >= 2) {
						fn = ar[ar.length - 1]
							+ _pathSeparator
							+ ar[ar.length];
					}
				}
				ret.append(fn);

				ret.append(', line ');
				ret.append(fr.srcInfo_[2]);
			}
		}
		return(toString(ret));
	}

	_stackTrace(depth, flags) {
		local st;

		if(depth == nil) depth = 1;
		depth += 1;

		st = t3GetStackTrace(depth, flags);
		if(st == nil)
			return(nil);

		if(stackFrameWrapper0) _debug(stackFrameWrapper0);

		_stackTraceSrc(st);
		_stackTraceNamedArgs(st);
		_stackTraceArgs(st);
		_stackTraceLocals(st);

		if(stackFrameWrapper1) _debug(stackFrameWrapper1);

		return(true);
	}

	_stackTraceSrc(obj) {
		_debug(formatStackFrame(obj, true), nil, 1);
	}

	_stackTraceArgs(obj) {
		if((obj.argList_ == nil) || (obj.argList_.length == 0))
			return;
		_debug('arguments:', nil, 2);
		obj.argList_.forEach(function(v) {
			_debug('<<valToSymbol(v)>>', nil, 3);
		});
	}

	_stackTraceNamedArgs(obj) {
		if(obj.namedArgs_ == nil)
			return;
		_debug('named arguments:', nil, 2);
		obj.namedArgs_.forEachAssoc(function(k, v) {
			_debug('<<k>> = <<valToSymbol(v)>>', nil, 3);
		});
	}

	_stackTraceLocals(obj) {
		if((obj.locals_ == nil)
			|| (obj.locals_.keysToList.length() == 0))
			return;
		_debug('local variables:', nil, 2);
		obj.locals_.forEachAssoc(function(k, v) {
			_debug('<<k>> = <<valToSymbol(v)>>', nil, 3);
		});
	}


	stackTrace(start?, depth?, flags?) {
		local i;

		if(start == nil)
			start = 1;
		start += 1;
		if(depth == nil)
			depth = 3;

		if(flags == nil)
			flags = T3GetStackLocals;

		for(i = start; i < start + depth; i++) {
			_stackTrace(i, flags);
		}
	}
*/
;

#ifdef __DEBUG_TOOL
modify __debugTool
	_debug(svc, msg?, ind?) { "\n<<_format(svc, msg, ind)>>\n "; }
;

#endif // __DEBUG_TOOL
