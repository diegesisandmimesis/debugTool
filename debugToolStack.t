#charset "us-ascii"
//
// debugToolStack.t
//
// Logic for displaying information about stack frames.
//
#include <adv3.h>
#include <en_us.h>

#include "debugTool.h"

#ifdef __DEBUG_TOOL

modify __debugTool
	// Text header/footer used in stackTrace().
	stackFrameWrapper0 = '=====New Stack Frame====='
	stackFrameWrapper1 = nil

	// When displaying file names, use only the base, not the full path.
	shortPaths = true

	// Used by the path shortening logic.  This is the character used
	// to divide paths in a filename.
	_pathSeparator = '/'

	_stack = nil

	setStack(v?) {
		if(v == nil) {
			v = t3GetStackTrace(nil, T3GetStackLocals).sublist(3);
		}
		if((v == nil) || (v.length < 1)) return(nil);
		_stack = v;

		return(_stack);
	}

	getStack() { return(_stack); }
	getStackFrame(depth?) {
		if(_stack == nil) return(nil);
		if(depth == nil) depth = 1;
		if((depth < 1) || (depth > _stack.length)) return(nil);
		return(_stack[depth]);
	}

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
				if(fr.self_ != nil) {
					ret.append(valToSymbol(fr.self_));
				} else {
					ret.append('???');
				}
				ret.append('.');
				if(fr.prop_ != nil)
					ret.append(valToSymbol(fr.prop_));
				else
					ret.append('???');
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

	_getFrameSourceFile(fr) {
		if((fr == nil) || (fr.srcInfo_ == nil))
			return(nil);

		return(fr.srcInfo_[1]);
	}

	_getFrameSourceLine(fr) {
		if((fr == nil) || (fr.srcInfo_ == nil))
			return(nil);

		return(fr.srcInfo_[2]);
	}

	_printStackFrameInfoVector(v, err?) {
		if(v == nil) {
			if(err != nil)
				"\n<<err>>\n ";
			else
				"\nno stack frame found\n ";
		} else {
			v.toList().forEach(function(o) {
				"\n<<o>>\n ";
			});
		}
	}

	_stackFrameInfo(st) {
		local r, v;

		if(st == nil) return(nil);

		v = new Vector();

		// Add the various bits of information if they're
		// available.
		if((r = _stackTraceSrc(st)) != nil)
			v.append(r);
		if((r = _stackTraceNamedArgs(st)) != nil)
			v.appendAll(r);
		if((r = _stackTraceArgs(st)) != nil)
			v.appendAll(r);
		if((r = _stackTraceSelf(st)) != nil)
			v.appendAll(r);
		if((r = _stackTraceLocals(st)) != nil)
			v.appendAll(r);

		return(v);
	}

	// Returns a vector of strings describing the stack frame at the
	// given depth.
	_stackTrace(depth, flags) {
		local r, st, v;

		// One is us, so we always start at at least 2.
		if(depth == nil)
			depth = 1;
		//depth += 1;

		st = getStack();
		if(st == nil)
			return(nil);
/*
		st = t3GetStackTrace(depth, flags);
		if(st == nil)
			return(nil);
*/

		v = new Vector();

		// Add the various bits of information if they're
		// available.
		if((r = _stackTraceSrc(st)) != nil)
			v.append(r);
		if((r = _stackTraceNamedArgs(st)) != nil)
			v.appendAll(r);
		if((r = _stackTraceArgs(st)) != nil)
			v.appendAll(r);
		if((r = _stackTraceSelf(st)) != nil)
			v.appendAll(r);
		if((r = _stackTraceLocals(st)) != nil)
			v.appendAll(r);

		return(v);
	}

	// The "name" of the frame location:  usually the file name and
	// line number.
	_stackTraceSrc(obj) {
		return(formatStackFrame(obj, true));
	}

	// The arguments to the frame.
	_stackTraceArgs(obj) {
		local r;

		if((obj.argList_ == nil) || (obj.argList_.length == 0))
			return(nil);

		r = new Vector();
		r.append(_indent(1) + 'arguments:');
		obj.argList_.forEach(function(v) {
			r.append(_indent(2) + '<<valToSymbol(v)>>');
		});

		return(r);
	}

	// Named arguments passed to the frame.
	_stackTraceNamedArgs(obj) {
		local r;

		if(obj.namedArgs_ == nil)
			return(nil);

		r = new Vector();
		r.append(_indent(1) + 'named arguments:');
		obj.namedArgs_.forEachAssoc(function(k, v) {
			r.append(_indent(2) + '<<k>> = <<valToSymbol(v)>>');
		});

		return(r);
	}

	// The frame's self, but not its properties.
	_stackTraceSelf(obj) {
		local r;

		if(obj.self_ == nil) return(nil);
		r = new Vector();
		r.append(_indent(1) + 'self:');
		r.append(_indent(2) + valToSymbol(obj.self_));

		return(r);
	}

	// The frame's self, including all properties.
	_stackTraceSelfFull(obj, skipUnprintable?) {
		local l, r, v;

		if(obj.self_ == nil) return(nil);

		r = new Vector();

		// First the self object itself.
		r.append(_indent(1) + 'self:');
		r.append(_indent(2) + valToSymbol(obj.self_));

		// Now all the properties.
		// We sort the property list alphabetically before outputting
		// them.
		l = obj.self_.getPropList();
		l = l.sort(nil, { a, b: toString(a).compareTo(toString(b)) });
		l.forEach(function(o) {
			if(!obj.self_.propDefined(o, PropDefDirectly))
				return;

			v = _stackTraceSelfFullProp(obj.self_, o,
				skipUnprintable);
			if(v == nil)
				return;
			r.append(_indent(3) + valToSymbol(o) + ' = ' + v);
		});

		return(r);
	}
	_stackTraceSelfFullProp(obj, prop, skip?) {
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
				return(valToSymbol(obj.(prop)));
		}
	}

	// Local variables in the frame.
	_stackTraceLocals(obj) {
		local l, r;

		if((obj.locals_ == nil)
			|| (obj.locals_.keysToList.length() == 0))
			return(nil);

		r = new Vector();

		r.append(_indent(1) + 'local variables:');

		// Local variables are in a LookupTable in obj.locals_
		// We sort the keys alphabetically so we can output them
		// in some sort of useful order.
		l = obj.locals_.keysToList();
		l = l.sort(nil, { a, b: toString(a).compareTo(toString(b)) });
		l.forEach(function(k) {
			r.append(_indent(2)
				+ '<<k>> = <<valToSymbol(obj.locals_[k])>>');
		});

		return(r);
	}

	// External method for displaying a stack trace.
	stackTrace(start?, depth?, flags?) {
/*
		local i, v;

		// This isn't how we print stack traces in the debugger,
		// so if we've been called during a breakpoint then we
		// must've been called by something in the game, which will
		// not work as intended, so we bail.
		if(_debuggerLock == true) return;

		if(start == nil)
			start = 1;
		start += 1;
		if(depth == nil)
			depth = 3;

		if(flags == nil)
			flags = T3GetStackLocals;

		for(i = start; i < start + depth; i++) {
			if(stackFrameWrapper0) _debug(stackFrameWrapper0);
			v = _stackTrace(i, flags);
			if(v) {
				v.toList.forEach(function(o) {
					_debug(o);
				});
			}
			if(stackFrameWrapper1) _debug(stackFrameWrapper1);
		}
*/
	}
;

#endif // __DEBUG_TOOL
