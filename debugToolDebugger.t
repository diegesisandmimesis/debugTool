#charset "us-ascii"
#include <adv3.h>
#include <en_us.h>

#include "debugTool.h"

#ifdef __DEBUG_TOOL

enum DebugToolCmdExit, DebugToolCmdHelp, DebugToolCmdPrint,
	DebugToolCmdSelf, DebugToolCmdStack, DebugToolCmdDown,
	DebugToolCmdUp;

modify T3StackInfo
	__debugToolDebugger = nil
;

modify __debugTool
	debuggerPrompt = '&gt;&gt;&gt; '

	// LookupTable of the debugger commands and the methods to invoke for
	// each.
	debuggerCommands = static [
		'?' -> &debuggerHelp,
		'help' -> &debuggerHelp,
		'exit' -> &debuggerExit,
		'print' -> &debuggerPrint,
		'self' -> &debuggerSelf,
		'stack' -> &debuggerStack,
		'up' -> &debuggerUp,
		'down' -> &debuggerDown
	]

	// Current offset relative to our original caller.
	_debuggerFrameOffset = 0

	// Flag we set when we start, so if we do something that would
	// trigger ourselves (like if we call a method containing a
	// breakpoint from inside the debugger) we don't get stuck
	// in a loop.
	_debuggerLock = nil

	debugger(st?) {
		local cmd, r;

		if(_debuggerLock == true) return;

		_debuggerLock = true;

		// Get the stack frame that called us.  The two is a magic
		// number;  one is the current frame (this method) so
		// two is our direct caller.
		st = setStack(st);
		if(st == nil) {
			"\n===unable to get stack, exiting debugger===\n ";
			return;
		}

		// Display our debugger banner, including the location
		// of the frame that called us.
		"\n \n===breakpoint in <<formatStackFrame(st[1], true)>>=== ";
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
			"\n<<debuggerPrompt>>";

			// Get a line of input.
			cmd = inputManager.getInputLine(nil, nil);

			// See if the input matches a debugger command.
			r = parseDebuggerCommand(cmd);
			if(r != nil) {
				// If r is non-nil, then that means we matched
				// a debugger command.  We check to see if the
				// specific command is EXIT, and if so we
				// return, exiting the debugger.  If the
				// command is something else we take no
				// action, which will send us through the
				// input loop again.
				if(r == DebugToolCmdExit) {
					_debuggerLock = nil;
					return;
				}
			} else {
				// The input wasn't a command, so we try to
				// compile and execute it as if it's T3 source.
				// After doing this, we'll go through the input
				// loop again.
				debuggerCompile(cmd);
			}
		}
	}

	// See if the given string contains any debugger commands.
	parseDebuggerCommand(txt) {
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
			return(debuggerHelp());

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
		debuggerCommands.forEachAssoc(function(k, v) {
			if(k.startsWith(kw))
				// All our commands are defined as
				// methods on ourselves.
				if(dataTypeXlat(v) == TypeProp)
					r = self.(v)();
		});

		return(r);
	}

	// Exit the debugger.
	debuggerExit() { return(DebugToolCmdExit); }

	// Print the debugger commands.
	debuggerHelp() {
		"
		\n<b>down</b>\tmove to the next lower stack frame
		\n<b>exit</b>\texit interactive debugger, resuming execution
		\n<b>help</b>\tdisplay this message
		\n<b>print</b>\tprint the details of the current stack frame
		\n<b>self</b>\tprint the self object in the current stack frame
		\n<b>stack</b>\tprint the location of the current stack frame
		\n<b>up</b>\t\tmove to the next higher stack frame
		\n ";
		return(DebugToolCmdHelp);
	}

	// Print the details of the current stack frame.
	debuggerPrint() {
		local fr;

		fr = getStackFrame(_debuggerFrameOffset + 1);
		if(fr == nil) {
			"\tno stack frame found\n ";
			return(DebugToolCmdPrint);
		}

		_printStackFrameInfoVector(_stackFrameInfo(fr),
			'no stack frame found');

		return(DebugToolCmdPrint);
	}

	// Print the current stack frame's self object.
	debuggerSelf() {
		local fr;

		fr = getStackFrame(_debuggerFrameOffset + 1);
		if(fr == nil) {
			"\tno stack frame found\n ";
			return(DebugToolCmdSelf);
		}

		_printStackFrameInfoVector(_stackTraceSelfFull(fr, true),
			'no self object defined in current stack frame');

		return(DebugToolCmdSelf);
	}

	// Print the "name" of the stack frame.  This will be something
	// like "widget.methodName() src/widget.t, line 100".
	debuggerStack() {
		local fr;

		fr = getStackFrame(_debuggerFrameOffset + 1);
		if(fr == nil) {
			"\tno stack frame found\n ";
			return(DebugToolCmdStack);
		}

		"\n<<_stackTraceSrc(fr)>>\n ";

		return(DebugToolCmdStack);
	}

	// Move one step up in the stack.
	debuggerUp() {
		// Twiddle the offset.
		_debuggerFrameOffset -= 1;

		// We can't go above our entry point, because then we'd
		// just be looking our our debugging code (instead of the
		// code we're trying to debug).
		// This is kinda a limitation on our approach here--in principle
		// our debugging harness might be causing problems itself.
		if(_debuggerFrameOffset < 0) {
			_debuggerFrameOffset = 0;
			"\nalready at top of stack\n ";
			return(DebugToolCmdUp);
		}

		// Display the new frame location.
		debuggerStack();

		return(DebugToolCmdUp);
	}

	// Move one step down in the stack.
	debuggerDown() {
		local fr;

		// Twiddle the offset.
		_debuggerFrameOffset += 1;

		// Check to see if we have a frame at the new offset.
		fr = getStackFrame(_debuggerFrameOffset);
		if(fr == nil) {
			// No frame here, go back to the old offset.
			_debuggerFrameOffset -= 1;
			"\nalready at bottom of stack\n ";

			return(DebugToolCmdDown);
		}

		// Output the new frame location.
		debuggerStack();

		return(DebugToolCmdDown);
	}

	// Compile the passed string as a T3 command, execute it, and
	// print the return value.
	debuggerCompile(buf) {
		local fn, r;

		r = nil;

		// Kludge to get this working with emscripten-based
		// interpreters.
#ifdef DEBUG_TOOL_EMSCRIPTEN_FIX
		buf = 'function() { return(' + buf + '); }';
#endif // DEBUG_TOOL_EMSCRIPTEN_FIX

		// Do everything in a try/catch block to handle errors.
		try {
			fn = Compiler.compile(buf);
			r = fn();
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
		"\n<<valToSymbol(r)>>\n ";
	}
;

#endif // __DEBUG_TOOL
