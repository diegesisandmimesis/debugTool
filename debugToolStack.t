#charset "us-ascii"
#include <adv3.h>
#include <en_us.h>

modify __debugTool
	stackFrameWrapper0 = '=====New Stack Frame====='
	stackFrameWrapper1 = nil

	// When displaying file names, use only the base, not the full path.
	shortPaths = true

	// Used by the path shortening logic.  This is the character used
	// to divide paths in a filename.
	_pathSeparator = '/'

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
;
