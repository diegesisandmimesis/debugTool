#charset "us-ascii"
//
// debugToolException.t
//
// Convenience methods for handling exceptions thrown and caught in
// the main event scheduler.
//
#include <adv3.h>
#include <en_us.h>

#include "debugTool.h"

#ifdef __DEBUG_TOOL

modify __debugTool
	// Called by runScheduler(), invoke the debugger with the
	// stack trace generated by a runtime error (instead of our
	// direct caller, which would just be runScheduler() and a bunch
	// of system stuff.
	runtimeError(err) { debugger(setStack(err.stack_)); }
	exception(ex) {
		"\n===NOTE: our exception fu is weak; the stack is probably bogus===\n ";
		debugger(setStack());
	}
;

#endif // __DEBUG_TOOL
