/*
	hl.h chooses its debug-break implementation from HL_LINUX, and __ANDROID__
	also satisfies `defined(__linux__)`, so an Android arm64 build takes the
	Linux/x86 branch and emits `int3` inline asm -- which the assembler rejects
	with "unrecognized instruction mnemonic". Upstream hl.h has no Android
	branch (it predates this target), and there is no NDK equivalent worth
	wiring up: nothing here runs under a native debugger that reads
	embed-breakpoints.

	So neutralise the macro, which is exactly what hl.h itself does for any
	platform it does not recognise (`#else #define hl_debug_break()`).

	This is force-included ahead of the sources that reference it, so it must
	include hl.h itself and override afterwards -- hl.h defines the macro
	unconditionally, so predefining it would just be redefined. hl.h's HL_H
	include guard makes the source's own #include a no-op, leaving this
	definition in place.
*/
#ifndef HEAPSAPP_ANDROID_DEBUG_BREAK_H
#define HEAPSAPP_ANDROID_DEBUG_BREAK_H

#include <hl.h>

#undef hl_debug_break
#define hl_debug_break()

#endif
