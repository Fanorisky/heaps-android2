# Heaps Android

![android](https://github.com/HeapsIO/heaps-android/actions/workflows/android.yml/badge.svg?branch=master)

Builds a [Heaps](https://heaps.io) sample as an Android app, using HashLink's
HL/C output compiled against SDL2, OpenAL and libjpeg-turbo via the NDK.

The **APK is built in CI only** — see [.github/workflows/android.yml](.github/workflows/android.yml).
Locally, the Makefile builds the Haxe game so it can be run and tested on the desktop.

## Setup

```sh
git clone --recursive https://github.com/HeapsIO/heaps-android
cd heaps-android
make init
```

`make init` creates a project-local `.haxelib` repo and points `heaps`, `hlsdl`,
`hlopenal` and `hashlink` at the pinned submodules, so it will not disturb a
global haxelib setup.

Requires `haxe` 4.3.x and, for `make run`, a `hashlink` 1.15 runtime providing
`hl` plus `sdl.hdll`/`fmt.hdll`/`ui.hdll`.

## Running the game locally (Linux)

```sh
make run          # builds out/main.hl and runs it with hl
```

Other targets:

| Target | Output |
|---|---|
| `make demo-c` | `out/main.c` — the HL/C sources the APK is built from |
| `make demo-hl` | `out/main.hl` — HL bytecode, for `hl` |
| `make demo-pak` | `out/res.pak` — not needed by the sample, which embeds its resources |
| `make clean` | removes generated output |

## Building the APK

Push a branch or trigger the `android` workflow manually. `make build` on Linux
intentionally fails with a pointer to CI.

## Version pinning

`heaps` is pinned to **2.1.1** and `hashlink` to **1.15**. hashlink 1.15 is the
last release built against SDL2 — 1.16+ requires SDL3, which is incompatible
with the vendored `sdl2` submodule (2.0.8).
