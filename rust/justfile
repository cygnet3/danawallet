default: build-emulator build-android

gen:
    flutter_rust_bridge_codegen --rust-input src/api.rs --dart-output ../lib/bridge_generated.dart --dart-decl-output ../lib/bridge_definitions.dart

build-emulator:
    cargo ndk -t x86 -o ../android/app/src/main/jniLibs build

build-android:
    cargo ndk -o ../android/app/src/main/jniLibs build
