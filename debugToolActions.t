#charset "us-ascii"
#include <adv3.h>
#include <en_us.h>

#include "debugTool.h"

#ifdef __DEBUG_TOOL

// Simple system command that forces a "breakpoint", dropping into the
// interactive debugger.
DefineSystemAction(DebugToolBreakpoint)
	execSystemAction() {
		__debugTool.breakpoint();
	}
;
VerbRule(DebugToolBreakpoint) 'breakpoint': DebugToolBreakpointAction
	verbPhrase = 'breakpoint/breakpointing';

#endif // __DEBUG_TOOL
