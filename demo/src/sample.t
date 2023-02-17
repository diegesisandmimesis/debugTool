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

gameMain:       GameMainDef
	initialPlayerChar = me
/*
	newGame() {
		local foo, bar;

		// Set some variables for the breakpoint to output
		foo = 123;
		bar = '[This space intentionally left blank]';

		// Kludge so the compiler won't complain that we defined
		// variables that aren't used.
		if(foo) {}
		if(bar) {}

		"\nThis is some placeholder text that comes before the
			stack. ";

		//__debugTool.breakpoint(&outputStuff, self);
		//__debugTool.breakpoint(&stackTrace);
		//__debugTool.stackTrace(nil, 3);
		__debugTool.stackTrace();

		"\nThis is the placeholder text that comes after the
			stack. ";

		"\nThis is some placeholder text that comes before the
			breakpoint. ";
		__debugTool.breakpoint();
	}
*/
;
