default: run

# use fvm if available, else use flutter directly
flutter := if `which fvm 2> /dev/null || true` != "" { "fvm flutter" }  else { "flutter" }

run:
    {{flutter}} run --flavor local --target lib/main_dev.dart
run-release:
    {{flutter}} run --release --flavor local --target lib/main_dev.dart

build-apk-dev:
    just clean-bin
    just build-android
    {{flutter}} build apk --flavor dev --target-platform android-arm,android-arm64
build-apk-live:
    just clean-bin
    just build-android
    {{flutter}} build apk --flavor live --target-platform android-arm,android-arm64
build-apk-signet:
    just clean-bin
    just build-android
    {{flutter}} build apk --flavor signet --target-platform android-arm,android-arm64

clean-bin:
    cd rust && just clean-bin
gen:
    cd rust && just gen
build-emulator:
    cd rust && just build-emulator
build-android:
    cd rust && just build-android

gen-rust:
    just gen
    just build-android
