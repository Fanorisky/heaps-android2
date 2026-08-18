.PHONY: all init build install clean demo demo-c demo-hl demo-pak run haxelib-init

# On Linux this repo builds the Haxe game only; the APK is built by CI
# (.github/workflows/android.yml). Windows/macOS keep their original gradle flow.
ifeq ($(OS),Windows_NT)
HOST := Windows
else
HOST := $(shell uname -s)
endif

SAMPLES := heaps/samples
HAXE_LIBS := format:3.8.0 hxbit:1.5.0

all: build install

ifeq ($(HOST),Linux)

# Everything Haxe-side resolves through a project-local .haxelib repo so the
# pinned submodules are used instead of whatever is in the global haxelib.
init: haxelib-init

haxelib-init:
	haxelib newrepo
	haxelib dev heaps ./heaps
	haxelib dev hlsdl ./hashlink/libs/sdl
	haxelib dev hlopenal ./hashlink/libs/openal
	haxelib dev hashlink ./hashlink/other/haxelib
	@for l in $(HAXE_LIBS); do \
		haxelib install --always $${l%%:*} $${l##*:} || exit 1; \
	done

# out/main.c is the only artifact the APK needs. Resources are embedded by
# hxd.Res.initEmbed() in World.hx, so no res.pak and no hl binary required.
demo: demo-c

demo-c:
	cd $(SAMPLES) && haxe -hl ../../out/main.c ../../config/main.hxml

demo-hl:
	cd $(SAMPLES) && haxe -hl ../../out/main.hl ../../config/main.hxml

demo-pak:
	cd $(SAMPLES) && haxe -hl ../../out/pak.hl ../../config/pak.hxml && hl ../../out/pak.hl -out ../../out/res

run: demo-hl
	cd out && hl main.hl

build install:
	@echo "The APK is built by GitHub Actions, not locally."
	@echo "See .github/workflows/android.yml — push a branch or run the workflow manually."
	@exit 1

clean:
	rm -rf out/main.c out/main.hl out/pak.hl out/res.pak out/hl out/h3d out/hxd \
		out/h2d out/hxsl out/haxe out/sdl out/sys out/format out/_std out/_Xml out/hlc.json

else

init:
ifeq ($(HOST),Windows)
	powershell ./hashlink.ps1 1.11.0
	choco install --no-progress haxe openal ffmpeg android-sdk android-ndk
else
	brew install haxe
	brew bundle install --file hashlink/Brewfile
	brew install --cask android-studio
	chmod u+x /Applications/Android\ Studio.app/Contents/plugins/android/lib/templates/gradle/wrapper/gradlew
endif
	make -C hashlink
	make install -C hashlink
	haxelib setup /usr/local/lib/haxe/lib
	make gen-local
build:
	CMD=assembleDebug make gradle
install:
	adb install heaps-android-app/heapsapp/build/outputs/apk/debug/heapsapp-debug.apk
clean:
	CMD=clean make gradle
demo: demo-hl demo-pak
demo-hl:
	cd $(SAMPLES) && haxelib install --always ../../config/main.hxml && haxe -hl ../../out/main.c ../../config/main.hxml
demo-pak:
	cd $(SAMPLES) && haxe -hl ../../out/pak.hl ../../config/pak.hxml && hl ../../out/pak.hl -out ../../out/res

ifeq ($(HOST),Windows)
gradle:
	cd heaps-android-app && gradlew.bat $(CMD)
gen-local:
	(echo sdk.dir=C:\\Android\\android-sdk&& echo ndk.dir=C:\\Android\\android-ndk-r21d) > heaps-android-app/local.properties
else
gradle:
	/Applications/Android\ Studio.app/Contents/plugins/android/lib/templates/gradle/wrapper/gradlew $(CMD) -p heaps-android-app
gen-local:
	echo "sdk.dir=$(HOME)/Library/Android/sdk" > heaps-android-app/local.properties
endif

endif
