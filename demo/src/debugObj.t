#charset "us-ascii"
//
// debugObj.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// Simple non-interactive test of the debugTools stack trace and
// breakpoint functionality.
//
// It can be compiled via the included makefile with
//
//	# t3make -f debugObj.t3m
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

foozle: object
	foo = 'foo'
	bar = 'bar'
	doubleQuotedString = "[This space intentionally left blank]"
	someNumber = 69105
;

gameMain:       GameMainDef
	newGame() {
		"foozle:\n ";
		foozle._debugToolObj().forEach(function(o) {
			"\t<<toString(o)>>\n ";
		});
	}
;
