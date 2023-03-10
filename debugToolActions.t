#charset "us-ascii"
//
// debugToolActions.t
//
// Defines a system action that drops control to the interactive debugger.
//
#include <adv3.h>
#include <en_us.h>

#include "debugTool.h"

#ifdef __DEBUG_TOOL

modify playerActionMessages
	debugToolExit = 'Exiting debugger. '
;

// Simple system command that forces a "breakpoint", dropping into the
// interactive debugger.
DefineSystemAction(DebugToolBreakpoint)
	execSystemAction() {
		__debugTool.breakpoint();
		defaultReport(&debugToolExit);
	}
;
VerbRule(DebugToolBreakpoint) 'breakpoint': DebugToolBreakpointAction
	verbPhrase = 'breakpoint/breakpointing';

#endif // __DEBUG_TOOL
