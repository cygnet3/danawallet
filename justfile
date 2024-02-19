default: build-emulator build-mobile

gen:
    # flutter pub get
    flutter_rust_bridge_codegen --rust-input rust/src/api.rs --dart-output ./lib/bridge_generated.dart --dart-decl-output ./lib/bridge_definitions.dart

build-emulator:
    cd rust && cargo ndk -t x86 -o ../android/app/src/main/jniLibs build

build-mobile:
    cd rust && cargo ndk -o ../android/app/src/main/jniLibs build
