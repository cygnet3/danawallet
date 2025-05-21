build-apk:
    rm -r android/app/src/main/jniLibs/*
    cd rust && just build-android-release
    flutter build apk --flavor live --target-platform android-arm,android-arm64

build-apk-dev:
    rm -r android/app/src/main/jniLibs/*
    cd rust && just build-android-release
    flutter build apk --flavor dev --target-platform android-arm,android-arm64
