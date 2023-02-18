#charset "us-ascii"
#include <adv3.h>
#include <en_us.h>

#ifdef __DEBUG_TOOL

#include <dynfunc.h>
#include "debugTool.h"

// Most of the old breakpoint() logic is now in debugger()
// in debugToolDebugger.t
modify __debugTool
	breakpoint() {
		// Minor magic to make sure the stack levels are right.
		// Short version:  debugger() normally expects to be
		// called from the frame that will be the top of the stack,
		// but *we* got called (instead of directly calling the
		// debugger), so we use setStack() to save the stack
		// "correctly" (with our caller at the top).  setStack()
		// returns the stack it just set, so we pass that as the
		// arg to the debugger, so it will use that (instead of
		// a stack with us, breakpoint(), at the top.
		// If none of this makes sense, rejoice that you probably
		// don't have to worry about it.
		debugger(setStack());
	}
;

#endif // __DEBUG_TOOL
