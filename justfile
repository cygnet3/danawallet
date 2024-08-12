build-apk:
    rm -r android/app/src/main/jniLibs/*
    cd rust && just build-android-release
    flutter build apk --target-platform android-arm,android-arm64
