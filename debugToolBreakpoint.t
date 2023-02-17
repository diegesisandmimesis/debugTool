#charset "us-ascii"
#include <adv3.h>
#include <en_us.h>

#include <dynfunc.h>

#include "debugTool.h"

enum BreakpointCmdExit, BreakpointCmdHelp, BreakpointCmdPrint,
	BreakpointCmdStack, BreakpointCmdDown, BreakpointCmdUp;

modify T3StackInfo
	__debugToolBreakpoint = nil
;

modify __debugTool
	// What to print when waiting for a keypress at a breakpoint.
	// Can be nil.
	breakpointPrompt = '&gt;&gt;&gt; '

	// LookupTable of the debugger commands and the methods to invoke for
	// each.
	breakpointCommands = static [
		'?' -> &breakpointHelp,
		'help' -> &breakpointHelp,
		'exit' -> &breakpointExit,
		'print' -> &breakpointPrint,
		'stack' -> &breakpointStack,
		'up' -> &breakpointUp,
		'down' -> &breakpointDown
	]

	// Current offset relative to our original caller.
	_breakpointOffset = 0

	// Flag we set when we start, so if we do something that would
	// trigger ourselves (like if we call a method containing a
	// breakpoint from inside the debugger) we don't get stuck
	// in a loop.
	_breakpointLock = nil

	// Set a "breakpoint".
	breakpoint() {
		local cmd, r, st;

		if(_breakpointLock == true) return;

		_breakpointLock = true;

		// Get the stack frame that called us.  The two is a magic
		// number;  one is the current frame (this method) so
		// two is our direct caller.
		st = t3GetStackTrace(2, 0);

		// Display our breakpoint banner, including the location
		// of the frame that called us.
		"\n \n===breakpoint in <<formatStackFrame(st, true)>>=== ";
		"\n===type HELP or ? for information on the interactive
			debugger===\n ";

		// Debugger loop.
		// We display our prompt and then get a line of input.
		// We check each line for a debugger command, evaluating
		// any matches.  If we don't match any commands, then we
		// treat the input as a snippet of TADS3 source which
		// we then try to compile and execute.
		for(;;) {
			// Display prompt.
			"\n<<breakpointPrompt>>";

			// Get a line of input.
			cmd = inputManager.getInputLine(nil, nil);

			// See if the input matches a debugger command.
			r = parseBreakpointCommand(cmd, st);
			if(r != nil) {
				// If r is non-nil, then that means we matched
				// a debugger command.  We check to see if the
				// specific command is EXIT, and if so we
				// return, exiting the breakpoint.  If the
				// command is something else we take no
				// action, which will send us through the
				// input loop again.
				if(r == BreakpointCmdExit) {
					_breakpointLock = nil;
					return;
				}
			} else {
				// The input wasn't a command, so we try to
				// compile and execute it as if it's T3 source.
				// After doing this, we'll go through the input
				// loop again.
				breakpointCompile(cmd);
			}
		}
	}

	// See if the given string contains any debugger commands.
	parseBreakpointCommand(txt, st) {
		local kw, r;

		// Null string, bail.
		if(txt == nil)
			return(nil);

		// Empty string, bail.
		if(rexMatch('^$', txt) != nil)
			return(nil);

		// Nothing but space, bail.
		if(rexMatch('^<space>*$', txt) != nil)
			return(nil);

		// Special case:  command was a question mark, display
		// the help message.
		if(rexMatch('^<space>*<question><space>*$', txt) != nil)
			return(breakpointHelp());

		// Generic command case:  a single alphabetic keyword.
		if(rexMatch('^<space>*(<alpha>+)<space>*$', txt) != nil) {
			// Remember the alphabetic portion of the match.
			kw = rexGroup(1)[3].toLower();
		} else {
			// Didn't match anything, bail.
			return(nil);
		}

		// Now we go through our list of commands to see if
		// the alphabetic string matches any of them.
		r = nil;
		breakpointCommands.forEachAssoc(function(k, v) {
			if(k.startsWith(kw))
				// All our commands are defined as
				// methods on ourselves.
				if(dataTypeXlat(v) == TypeProp)
					r = self.(v)(st);
		});

		return(r);
	}

	// Exit the breakpoint.
	breakpointExit(st?) { return(BreakpointCmdExit); }

	// Print the debugger commands.
	breakpointHelp(st?) {
		"
		\n<b>down</b>\tmove to the next lower stack frame
		\n<b>exit</b>\texit interactive debugger, resuming execution
		\n<b>help</b>\tdisplay this message
		\n<b>print</b>\tprint the details of the current stack frame
		\n<b>stack</b>\tprint the location of the current stack frame
		\n<b>up</b>\t\tmove to the next higher stack frame
		\n ";
		return(BreakpointCmdHelp);
	}

	// Print the details of the current stack frame.
	breakpointPrint(st?) {
		local i, fr, r;

		i = _breakpointDepth(st) + _breakpointOffset;
		fr = t3GetStackTrace(i, T3GetStackLocals);
		if(fr == nil) {
			"\tno stack frame found\n ";
			return(BreakpointCmdStack);
		}

		r = _stackTrace(i, T3GetStackLocals);
		r.toList().forEach(function(o) {
			"\n<<o>>\n ";
		});

		return(BreakpointCmdPrint);
	}

	// Compare the two stack frames, returning boolean true if they
	// match, nil otherwise.
	_breakpointStackFrameCmp(f0, f1) {
		if((f0 == nil) || (f1 == nil))
			return(nil);
		if(!f0.ofKind(T3StackInfo) || !f1.ofKind(T3StackInfo))
			return(nil);
		return((f0.func_ == f1.func_) && (f0.obj_ == f1.obj_)
			&& (f0.prop_ == f1.prop_) && (f0.self_ == f1.self_));
	}

	// Try to figure out the location of the given stack frame in the
	// stack.
	_breakpointDepth(st) {
		local fr, i;

		i = 1;
		fr = t3GetStackTrace(i, T3GetStackLocals);

		while((_breakpointStackFrameCmp(st, fr) == nil)
			&& (fr != nil)) {
			i += 1;
			fr = t3GetStackTrace(i, T3GetStackLocals);
		}

		if(fr == nil) 
			return(1);

		return(i);
	}

	// Print the "name" of the stack frame.  This will be something
	// like "widget.methodName() src/widget.t, line 100".
	breakpointStack(st) {
		local fr, i, r;

		i = _breakpointDepth(st) + _breakpointOffset - 1;
		fr = t3GetStackTrace(i, T3GetStackLocals);
		if(fr == nil) {
			"\tno stack frame found\n ";
			return(BreakpointCmdStack);
		}

		r = _stackTraceSrc(fr);
		"\n<<r>>\n ";

		return(BreakpointCmdStack);
	}

	// Move one step up in the stack.
	breakpointUp(st) {
		// Twiddle the offset.
		_breakpointOffset -= 1;

		// We can't go above our entry point, because then we'd
		// just be looking our our debugging code (instead of the
		// code we're trying to debug).
		// This is kinda a limitation on our approach here--in principle
		// our debugging harness might be causing problems itself.
		if(_breakpointOffset < 0) {
			_breakpointOffset = 0;
			"\nalready at top of stack\n ";
			return(BreakpointCmdUp);
		}

		// Display the new frame location.
		breakpointStack(st);

		return(BreakpointCmdUp);
	}

	// Move one step down in the stack.
	breakpointDown(st) {
		local fr, i;

		// Twiddle the offset.
		_breakpointOffset += 1;

		// Check to see if we have a frame at the new offset.
		i = _breakpointDepth(st) + _breakpointOffset;
		fr = t3GetStackTrace(i, T3GetStackLocals);
		if(fr == nil) {
			// No frame here, go back to the old offset.
			_breakpointOffset -= 1;
			"\nalready at bottom of stack\n ";

			return(BreakpointCmdDown);
		}

		// Output the new frame location.
		breakpointStack(st);

		return(BreakpointCmdDown);
	}

	// Compile the passed string as a T3 command, setting the result
	// as the breakpointUserCommand() method if compilation succeeds.
	breakpointCompile(buf) {
		local r;

		r = nil;

		// Do everything in a try/catch block to handle errors.
		try {
			setMethod(&breakpointUserCommand,
				Compiler.compile(buf));
		}
		// Compiler chucked a wobbly;  print the exception and bail.
		catch(Exception e) {
			"\n\t";
			e.displayException();
			"\n ";
			return;
		}

		// Compile succeeded, so we evaluate the new method and
		// print the results (to the limit of valToSymbol()).
		r = breakpointUserCommand();
		"\n<<valToSymbol(r)>>\n ";
	}

	// Stub method.  It gets overwritten by the compiler, above.
	breakpointUserCommand() {}
;
