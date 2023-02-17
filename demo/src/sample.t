#charset "us-ascii"
//
// sample.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This is a very simple demonstration "game" for the debugTool library.
//
// It can be compiled via the included makefile with
//
//	# t3make -f makefile.t3m
//
// ...or the equivalent, depending on what TADS development environment
// you're using.
//
// This "game" is distributed under the MIT License, see LICENSE.txt
// for details.
//
#include <adv3.h>
#include <en_us.h>

versionInfo:    GameID
        name = 'debugTool Library Demo Game'
        byline = 'Diegesis & Mimesis'
        desc = 'Demo game for the debugTool library. '
        version = '1.0'
        IFID = '12345'
	showAbout() {
		"This is a simple test game that demonstrates the features
		of the debugTool library.
		<.p>
		Examining the pebble will output a stack trace (with
		pebble.desc() at the top of the stack).
		<.p>
		Taking the pebble will encounter a <q>breakpoint</q> and drop
		control to the interactive debugger.
		<.p>
		The debugger can also be started by using the >BREAKPOINT
		command at the regular parser prompt.
		<.p>
		Consult the README.txt document distributed with the library
		source for a quick summary of how to use the library in your
		own games.
		<.p>
		The library source is also extensively commented in a way
		intended to make it as readable as possible. ";
	}
;

startRoom: Room 'Void'
        "This is a featureless void."
;
+me: Person;
+pebble: Thing 'small round pebble' 'pebble'
	"A small, round pebble.  It has debugging information:
		<<__debugTool.stackTrace()>> "

	foozle = 0

	dobjFor(Take) {
		action() {
			__debugTool.breakpoint();
			inherited();
		}
	}
;

gameMain: GameMainDef initialPlayerChar = me;
