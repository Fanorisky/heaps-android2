cmake_minimum_required(VERSION 3.10)

project(heapsapp)

include_directories(hashlink/src)

# Gradle passes ANDROID_NDK, but a standalone cmake invocation using the NDK
# toolchain file only sets CMAKE_ANDROID_NDK. Needed by the ndk-build call below.
if(NOT ANDROID_NDK)
	set(ANDROID_NDK ${CMAKE_ANDROID_NDK})
endif()

# LibHL

file(GLOB libhl
    hashlink/src/std/*.c
	hashlink/src/gc.c
)
# Needs the debugger's ptrace/process plumbing, which Android does not provide.
# (src/allocator.c is deliberately absent: gc.c #includes it.)
list(REMOVE_ITEM libhl ${CMAKE_CURRENT_SOURCE_DIR}/hashlink/src/std/debug.c)

# hashlink 1.15 vendors PCRE2, where 1.11 vendored PCRE1 -- hence the pcre2_
# prefix and the exclusions below. These three are #included by their siblings
# rather than compiled on their own, so building them as separate translation
# units either fails outright or duplicates symbols. Mirrors the PCRE list in
# hashlink's own Makefile and CMakeLists.
file(GLOB pcre hashlink/include/pcre/pcre2_*.c)
foreach(f pcre2_jit_match.c pcre2_jit_misc.c pcre2_ucptables.c)
	list(REMOVE_ITEM pcre ${CMAKE_CURRENT_SOURCE_DIR}/hashlink/include/pcre/${f})
endforeach()

add_library(hl STATIC
	${pcre}
	${libhl}
    hashlink/src/std/sys_android.c
	uv_stub.c
)

target_include_directories(hl PRIVATE hashlink/include/pcre)
# PCRE2 hard-errors without a code unit width, and takes its feature set from
# include/pcre/config.h. Both values match what hashlink builds PCRE2 with.
target_compile_definitions(hl PRIVATE HAVE_CONFIG_H PCRE2_CODE_UNIT_WIDTH=16)
target_link_libraries(hl log)

# FMT

set(TJ_LIB ${CMAKE_CURRENT_SOURCE_DIR}/libjpeg-turbo/obj/local/${ANDROID_ABI}/libjpeg-turbo.a)
add_custom_target(turbojpeg
	${ANDROID_NDK}/ndk-build APP_ABI=${ANDROID_ABI} APP_PLATFORM=${ANDROID_PLATFORM}
	NDK_PROJECT_PATH=./libjpeg-turbo
	WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
	BYPRODUCTS ${TJ_LIB}
)

file(GLOB fmt hashlink/libs/fmt/*.c)
file(GLOB png hashlink/include/png/*.c)
file(GLOB zlib hashlink/include/zlib/*.c)
file(GLOB vorbis hashlink/include/vorbis/*.c)
file(GLOB mikkt hashlink/include/mikktspace/*.c)
file(GLOB minimp3 hashlink/include/minimp3/*.c)

add_library(fmt.hdll STATIC
	${fmt}
	${png}
	${zlib}
	${vorbis}
	${mikkt}
)

add_dependencies(fmt.hdll turbojpeg)
file(GLOB tj_include libjpeg-turbo/jni/vendor/libjpeg-turbo/libjpeg-turbo-*)
target_link_libraries(fmt.hdll ${TJ_LIB})
target_compile_definitions(fmt.hdll PRIVATE PNG_ARM_NEON_OPT=0) #disable Neon support for now

target_include_directories(fmt.hdll PRIVATE
	hashlink/include/png
	hashlink/include/mikktspace
	hashlink/include/minimp3
	hashlink/include/vorbis
	hashlink/include/zlib
	${tj_include}
)

# SDL

# SDL_STATIC defaults ON, which would compile every SDL source a second time for
# an archive nothing links. SDL_TEST/VIDEO_VULKAN are likewise dead weight here.
set(SDL_STATIC OFF CACHE BOOL "" FORCE)
set(SDL_TEST OFF CACHE BOOL "" FORCE)
set(VIDEO_VULKAN OFF CACHE BOOL "" FORCE)
add_subdirectory(sdl2)
file(GLOB sdl hashlink/libs/sdl/*.c)
add_library(sdl.hdll STATIC ${sdl})
target_include_directories(sdl.hdll PUBLIC sdl2/include)
target_link_libraries(sdl.hdll SDL2 SDL2main EGL GLESv3)

# OpenAL

# Belt-and-braces: openal-nativetools/CMakeLists.txt already defaults these OFF,
# but force them so a stale CMake cache can't re-enable host-only executables.
set(ALSOFT_UTILS OFF CACHE BOOL "" FORCE)
set(ALSOFT_EXAMPLES OFF CACHE BOOL "" FORCE)
set(ALSOFT_TESTS OFF CACHE BOOL "" FORCE)
set(ALSOFT_NO_CONFIG_UTIL ON CACHE BOOL "" FORCE)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/openal-nativetools/CMakeLists.txt ${CMAKE_CURRENT_SOURCE_DIR}/openal-soft COPYONLY)
add_subdirectory(openal-soft)
file(GLOB openal hashlink/libs/openal/*.c)
add_library(openal.hdll STATIC ${openal})
target_include_directories(openal.hdll PUBLIC openal-soft/include)
target_link_libraries(openal.hdll OpenAL)

# UI

file(GLOB ui hashlink/libs/ui/ui_stub.c)
add_library(ui.hdll STATIC ${ui})

# Heaps Application

add_library(heapsapp SHARED out/main.c jni.c)
target_include_directories(heapsapp PRIVATE out)
target_link_libraries(heapsapp hl sdl.hdll fmt.hdll openal.hdll ui.hdll)
