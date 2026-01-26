default: run

# use fvm if available, else use flutter directly
flutter := if `which fvm 2> /dev/null || true` != "" { "fvm flutter" }  else { "flutter" }

run:
    {{flutter}} run --flavor local --target lib/main_local.dart
run-release:
    {{flutter}} run --release --flavor local --target lib/main_local.dart

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
