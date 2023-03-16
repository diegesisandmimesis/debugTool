//
// debugTool.h
//

// Uncomment to enable debugging options.
//#define __DEBUG_TOOL

// The "root" path of the project.  This can either be an absolute
// path or the relative path FROM the directory the story file lives
// in TO where t3make was run.
// Let's say your home directory is /home/tads, you copied the source
// of this module by doing a git clone in your home director, so
// now the source is in /home/tads/debugTool.  That will give you,
// in part:
//
//	/home/tads/debugTool/
//	/home/tads/debugTool/demo/makefile.t3m
//	/home/tads/debugTool/demo/src/sample.t
//
// And you can compile sample.t by doing something like:
//
//	# cd /home/tads/debugTool/demo
//	# t3make -d -a -f makefile.t3m
//
// This will create the game file in:
//
//	/home/tads/debugTool/demo/games/game.t3
//
// ...which you could then "play" with:
//
//	# frob -s 0 games/game.t3
//
// In this case you would want something in this header like:
//
//	#define DEBUG_TOOL_PATH '..'
//
// ...or to add...
//
//	-D DEBUG_TOOL_PATH='..'
//
// ...to the makefile.
//
// This is because:
//
//	-The .t3 lives in ./demo/games
//	-The makefile lives in ./demo
//	-And the makefile refers to the source file as ./demo/src/sample.t
//
// So to get from where the game is to the base path used by the makefile
// (and therefore the relative paths that get baked into the compiled
// story file), you need ".." (up one directory level).
//
// IF THIS IS ALL TOO CONFUSING
//
// You can just keep the source and the story file in the same directory
// and leave DEBUG_TOOL_PATH as '.' (the current directory).
//
//
#ifndef DEBUG_TOOL_PATH
#define DEBUG_TOOL_PATH '.'
#endif // DEBUG_TOOL_PATH

// A emscripten-specific fix for the interactive debugger.
// If you're not debugging in a web-based interpreter you probably don't
// need to worry about this.
//#define DEBUG_TOOL_EMSCRIPTEN_FIX

// Replace the main scheduling loop to catch all "bad" exceptions and
// drop them to the interactive debugger.
// "Bad" exceptions are RuntimeError exceptions and generic exceptions
// that aren't handled outside of the default catch block.
// TADS3 somewhat idiosyncratically throws exceptions to handle certain
// "benign" situations, like a verify() method wishing to abort the
// remainder of command processing.  The assumption here is that
// developers DO NOT want to drop into the debugger for that kind of thing,
// so we don't by default.  If you DO want that to happen, you can just
// tweak the appropriate catch() blocks in the replacement runScheduler()
// function in debugToolEvents.t
//#define DEBUG_TOOL_CATCH_ALL

// Don't comment out the line below.  It's used for dependency checking.
#define DEBUG_TOOL_H
