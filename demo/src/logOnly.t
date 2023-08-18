#charset "us-ascii"
//
// logOnly.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// Demonstration of the module's logging output without any of the other
// features enabled.
//
// It can be compiled via the included makefile with
//
//	# t3make -f logOnly.t3m
//
// ...or the equivalent, depending on what TADS development environment
// you're using.
//
// This "game" is distributed under the MIT License, see LICENSE.txt
// for details.
//
#include <adv3.h>
#include <en_us.h>

versionInfo:    GameID;

class Foozle: DebugTool
	svc = 'Foozle'

	// Output a single line out debugging output.
	// This will be displayed if compiled with the -D DEBUG_TOOL_LOGGING
	// flag, and if the flag isn't given the "game" should just silently
	// exit.
	logStuff() {
		_debug('This is just some test output.');
	}
;

gameMain:       GameMainDef
	newGame() {
		local obj;

		obj = new Foozle();
		obj.logStuff();
	}
;
