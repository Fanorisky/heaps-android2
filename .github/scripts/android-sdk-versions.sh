#!/usr/bin/env bash
# Reads the NDK and CMake versions out of the app's build.gradle and exports them
# for the workflow. build.gradle is the single source of truth: AGP reads these
# same values when it drives the native build, so a version resolved any other
# way would let the standalone cmake job and the APK job compile against
# different toolchains while both looked green.
set -euo pipefail

GRADLE_FILE=heaps-android-app/heapsapp/build.gradle

extract() {
	local pattern=$1 label=$2 value
	# Grab every match so an added second declaration is caught rather than
	# silently shadowed by whichever came first.
	mapfile -t matches < <(grep -oE "$pattern" "$GRADLE_FILE" | grep -oE "[0-9]+(\.[0-9]+)*")
	if [ "${#matches[@]}" -ne 1 ]; then
		echo "Expected exactly one $label in $GRADLE_FILE, found ${#matches[@]}: ${matches[*]-none}" >&2
		exit 1
	fi
	value=${matches[0]}
	echo "$value"
}

NDK_VERSION=$(extract "ndkVersion '[0-9.]+'" "ndkVersion")
CMAKE_VERSION=$(extract "version '[0-9.]+'" "cmake version")
COMPILE_SDK=$(extract "compileSdk [0-9]+" "compileSdk")
MIN_SDK=$(extract "minSdk [0-9]+" "minSdk")

echo "NDK_VERSION=$NDK_VERSION"
echo "CMAKE_VERSION=$CMAKE_VERSION"
echo "COMPILE_SDK=$COMPILE_SDK"
echo "MIN_SDK=$MIN_SDK"

{
	echo "NDK_VERSION=$NDK_VERSION"
	echo "CMAKE_VERSION=$CMAKE_VERSION"
	echo "COMPILE_SDK=$COMPILE_SDK"
	echo "MIN_SDK=$MIN_SDK"
	echo "CMAKE_BIN=$ANDROID_HOME/cmake/$CMAKE_VERSION/bin/cmake"
	echo "NINJA_BIN=$ANDROID_HOME/cmake/$CMAKE_VERSION/bin/ninja"
} >>"$GITHUB_ENV"
