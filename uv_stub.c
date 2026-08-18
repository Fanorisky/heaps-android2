/*
 * Stub implementation of the libuv primitives that HL/C needs at link time.
 *
 * The generated C (out/hl/natives.h) references uv_close_handle, uv_default_loop,
 * uv_fs_start_wrap and uv_run because heaps pulls in hxd.fs.LocalFileSystem via
 * h3d.prim.ModelDatabase / h3d.mat.MaterialDatabase. On desktop those resolve at
 * runtime from uv.hdll, but hlc resolves every primitive at *link* time, so a
 * missing symbol here becomes an UnsatisfiedLinkError when Java calls
 * System.loadLibrary("heapsapp").
 *
 * Building hashlink/libs/uv is not an option: only include/libuv/src/win is
 * vendored, there are no unix sources to compile against.
 *
 * Live resource reloading is a dev-time feature, so no-ops are the right
 * behaviour on Android. Follows the same pattern as hashlink/libs/ui/ui_stub.c.
 */
#define HL_NAME(n) uv_##n
#include <hl.h>

#define uv_handle void
#define uv_loop void

#define _HANDLE _ABSTRACT(uv_handle)
#define _LOOP _ABSTRACT(uv_loop)
#define _FS _HANDLE
#define _CALLB _FUN(_VOID, _NO_ARG)

HL_PRIM void HL_NAME(close_handle)( uv_handle *h, vclosure *c ) {
}

HL_PRIM uv_loop *HL_NAME(default_loop)() {
	return NULL;
}

HL_PRIM uv_handle *HL_NAME(fs_start_wrap)( uv_loop *loop, vclosure *cb, vbyte *path ) {
	return NULL;
}

HL_PRIM int HL_NAME(run)( uv_loop *loop, int mode ) {
	return 0;
}

DEFINE_PRIM(_VOID, close_handle, _HANDLE _CALLB);
DEFINE_PRIM(_LOOP, default_loop, _NO_ARG);
DEFINE_PRIM(_FS, fs_start_wrap, _LOOP _FUN(_VOID, _I32) _BYTES);
DEFINE_PRIM(_I32, run, _LOOP _I32);
