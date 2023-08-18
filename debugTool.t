#charset "us-ascii"
//
// debugTool.t
//
// A debugging library for TADS3 including a simple (semi-)interactive debugger.
//
//
// BASIC USAGE:
//
// The interactive debugger be called three(-ish) ways:
//
//	-Calling __debugTool.breakpoint() explicitly in source code.  An
//		example of this is in ./demo/src/sample.t
//	-Typing >BREAKPOINT in the game
//	-Compiling with the -D DEBUG_TOOL_CATCH_ALL flag, in which case
//		the interpreter will drop into the debugger on "bad"
//		exceptions (see below for details)
//
//
// THE DEBUGGER
//
// When the debugger is called, a short banner will be displayed, something
// like:
//
//	===breakpoint in pebble.actionDobjTake() src/catch.t, line 65===
//	===type HELP or ? for information on the interactive debugger===
//	>>>
//
// You can then start entering debugging commands at the >>> prompt.  The
// builtin debugger commands are:
//
//	STACK NAVIGATION
//
//		down	move to the stack frame "below" the current one
//		up	move to the stack frame "above" the current one
//
//	STACK INFORMATION
//
//		print	display the details of the current stack frame.  this
//			this includes the function/method name, source
//			file and line number if available, the self object,
//			and the frame's local variables
//		self	display details of the current self object.  this
//			will list all properties (names and values) on
//			the instance and it's immediate parent class
//		stack	display the current stack location, which is
//			the function/method name and the source file/line
//			number if available
//
//	SOURCE VIEWER
//
//		list	display the source code for the current stack
//			frame.  the line corresponding to the line number
//			given in the stack frame will be displayed
//			along with a few lines of context above and below
//			it (controlled by debuggerContextLines, by
//			default 5).
//			in order for this to work you will need to lower
//			the safety settings of the interpreter (by
//			default the interpreter can't look at files outside
//			of the directory the story file was loaded from).
//			you may also have to tweak the DEBUG_TOOL_PATH
//			value if the debugger can't figure out relative
//			paths by itself.  see the comments for DEBUG_TOOL_PATH
//			in debugTool.h for more details
//
//	DEBUGGER STUFF
//
//		help	display the help message, which lists the available
//			commands
//		exit	exit the debugger, which will resume execution of
//			the game after the breakpoint
//
//	EXPRESSION EVALUATOR
//
//	You can also enter arbitrary TADS3 expressions.  They will
//	be evaluated, changing the game state, and their return
//	value displayed.
//
//	Using the game in ./demo/sample.t as an example:
//
//	(make and run the game)
//
//		# t3make -d -a -f makefile.t3m
//		# frob -s 0 ./games/game.t3
//
//	(game transcript)
//
//		Void
//		This is a featureless void.
//
//		You see a pebble here.
//
//	(examine the pebble, it displays the current value of pebble.foozle)
//
//		>x pebble
//		A small, round pebble, marked "foozle = 0".
//
//	(drop into the debugger)
//
//		>breakpoint
//		===breakpoint in {obj:predicate(DebugToolBreakpoint)}.
//		execSystemAction() ../debugToolActions.t, line 23===
//		===type HELP or ? for information on the interactive debugger===
//
//	(change the value of pebble.foozle, which returns the value just set)
//
//		>>> pebble.foozle=69105
//		69105
//
//	(exit the debugger)
//
//		>>> exit
//		Exiting debugger.
//
//	(examine the pebble again, seeing the change)
//
//		>x pebble
//		A small, round pebble, marked "foozle = 69105".
//
//
// "BAD" EXCEPTIONS
//
// When compiled with the DEBUG_TOOL_CATCH_ALL flag, the debugger will be
// called whenever the interpreter throws a "bad" exception.  Here "bad"
// exceptions are runtime errors and general exceptions that are caught
// by the catch-all default exception handler.  This excludes exceptions
// that are thrown by the parser as part of normal operation--verify()
// methods that call "exit", for example, result in an exception being
// thrown to halt further command processing.
//
// If you DO want these exceptions handled by the debugger you can tweak
// the catch() block(s) in debugToolEvents.t.
//
//
// NOTE:  If you're using a wasm/emscripten-based interpreter you'll have
//	to compile with the -D DEBUG_TOOL_EMSCRIPTEN_FIX flag
//
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
	valToSymbol(v) { return(toString(v)); }
;

#ifdef __DEBUG_TOOL

modify DebugTool
	valToSymbol(v) { return(reflectionServices.valToSymbol(v)); }
;

#endif // __DEBUG_TOOL

#ifdef DEBUG_TOOL_LOGGING

modify __debugTool
	_debug(svc, msg?, ind?) { "\n<<_format(svc, msg, ind)>>\n "; }
;

#endif // DEBUG_TOOL_LOGGING
