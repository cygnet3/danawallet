default: run-dev

run-dev:
    flutter run --flavor dev --target lib/main_dev.dart
run-dev-release:
    flutter run --release --flavor dev --target lib/main_dev.dart
run-live:
    flutter run --flavor live
run-live-release:
    flutter run --release --flavor live
run-mainnet:
    flutter run --flavor mainnet
run-mainnet-release:
    flutter run --release --flavor mainnet
run-signet:
    flutter run --flavor signet
run-signet-release:
    flutter run --release --flavor signet

build-apk-dev:
    just clean-bin
    just build-android-release
    flutter build apk --flavor dev --target-platform android-arm,android-arm64
build-apk-live:
    just clean-bin
    just build-android-release
    flutter build apk --flavor live --target-platform android-arm,android-arm64

clean-bin:
    cd rust && just clean-bin
gen:
    cd rust && just gen
build-emulator:
    cd rust && just build-emulator
build-android:
    cd rust && just build-android
build-android-release:
    cd rust && just build-android-release

gen-rust:
    just gen
    just build-android
