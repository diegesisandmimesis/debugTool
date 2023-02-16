#charset "us-ascii"
#include <adv3.h>
#include <en_us.h>

#include <dynfunc.h>

modify __debugTool
	// Line to print before any output produced in the breakpoint.
	// Can be nil.
	breakpointWrapper = '=====Breakpoint Output====='

	// What to print when waiting for a keypress at a breakpoint.
	// Can be nil.
	//breakpointPrompt = '[Press any key to continue]'
	breakpointPrompt = '&gt;&gt;&gt; '

	commandOptions = static [
		'exit' -> &breakpointExit
	]

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
		local st;

		//if(breakpointWrapper) _debug(breakpointWrapper);
		//if(breakpointWrapper) "\n \n<<breakpointWrapper>>\n ";
		st = t3GetStackTrace(2, 0);
		"\n \n[breakpoint in <<formatStackFrame(st, true)>>]\n ";
/*
		_breakpointCallback(cb, ctx, 2);
		if(breakpointWrapper) _debug(breakpointWrapper);
		if(breakpointPrompt) _debug(breakpointPrompt);
		for(;;) {
			inputManager.getKey(nil, nil);
			return;
		}
*/
		breakpointInteractive();
	}
	breakpointInteractive() {
		local cmd, r;

		for(;;) {
			"\n<<breakpointPrompt>>";
			cmd = inputManager.getInputLine(nil, nil);
			r = parseBreakpointCommand(cmd);
			if(r == true) return(true);
			breakpointCompile(cmd);
		}
	}
	parseBreakpointCommand(txt) {
		local kw, r;

		if(txt == nil) return(nil);
		if(rexMatch('^<space>*$', txt) != nil) return(nil);
		if(rexMatch('^<space>*(<alpha>+)<space>*$', txt) != nil) {
			kw = rexGroup(1)[3].toLower();
		} else {
			return(nil);
		}
		r = nil;
		commandOptions.forEachAssoc(function(k, v) {
			if(k.startsWith(kw)) r = handleBreakpointCommand(v);
		});
		return(r);
	}
	handleBreakpointCommand(v) {
		switch(dataTypeXlat(v)) {
			case TypeProp:
				return(self.(v)());
			case TypeFuncPtr:
				return(v());
		}
		return(nil);
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

	breakpointExit() { return(true); }

	breakpointCompile(buf) {
		try {
			setMethod(&breakpointUserCommand,
				Compiler.compile(buf));
		}
		catch(Exception e) {
			"\nERROR\n ";
			"\n\t";
			e.displayException();
			"\n ";
			return;
		}
		finally {
			breakpointUserCommand();
		}
	}

	breakpointUserCommand() {}
;
