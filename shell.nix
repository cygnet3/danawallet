{ pkgs ? import <nixpkgs> { 
    config.android_sdk.accept_license = true; 
    config.allowUnfree = true; 
  } 
}: 

let 
  androidComposition = pkgs.androidenv.composeAndroidPackages {
    platformVersions = [ "34" ];
    abiVersions = [ "arm64-v8a" ];
    includeEmulator = true;
    includeSystemImages = true;
    includeNDK = true;
    systemImageTypes = [ "google_apis_playstore" ];
    ndkVersions = [ "26.3.11579264" ]; # Include both versions
    buildToolsVersions = [ "34.0.0" ]; # Explicitly include build tools
  }; 
in 

pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    flutter
    rustup
    flutter_rust_bridge_codegen
    git
    just
    cargo-ndk
    androidComposition.androidsdk
    androidComposition.platform-tools
    jdk17
    gradle
  ];

  # Environment variables
  ANDROID_SDK_ROOT = "${androidComposition.androidsdk}/libexec/android-sdk";
  ANDROID_HOME = "${androidComposition.androidsdk}/libexec/android-sdk"; # Flutter sometimes expects this
  ANDROID_NDK_HOME = "${androidComposition.androidsdk}/libexec/android-sdk/ndk/26.3.11579264"; # Use the version Flutter expects
  RUSTUP_HOME = "${builtins.getEnv "HOME"}/.danawallet/rustup";
  CARGO_HOME = "${builtins.getEnv "HOME"}/.danawallet/cargo";
  GRADLE_USER_HOME = "${builtins.getEnv "HOME"}/.danawallet/gradle";
  JAVA_HOME = "${pkgs.jdk17}";
  ANDROID_USER_HOME = "${builtins.getEnv "HOME"}/.danawallet/android"; # Create a writable Android SDK location
  
  # Fixed PATH - removed syntax error and made it more robust
  shellHook = ''
    export PATH="${androidComposition.androidsdk}/libexec/android-sdk/emulator:${androidComposition.androidsdk}/libexec/android-sdk/platform-tools:${androidComposition.androidsdk}/libexec/android-sdk/tools/bin:$PATH"
    
    # Initialize rustup if needed
    if [ ! -d "$RUSTUP_HOME" ]; then
      echo "Initializing rustup..."
      rustup-init -y --no-modify-path
    fi
    
    # Ensure we have the stable toolchain and Android targets
    rustup toolchain install stable
    rustup default stable
    rustup target add aarch64-linux-android armv7-linux-androideabi
    
    # Create a completely writable Android SDK
    WRITABLE_SDK="$HOME/.danawallet/android-sdk"
    NIX_SDK="${androidComposition.androidsdk}/libexec/android-sdk"
    
    if [ ! -d "$WRITABLE_SDK" ]; then
      echo "Setting up writable Android SDK..."
      mkdir -p "$WRITABLE_SDK"
      
      # Copy the entire SDK to writable location
      cp -r "$NIX_SDK"/* "$WRITABLE_SDK/" 2>/dev/null || true
      
      # Make sure it's writable
      chmod -R u+w "$WRITABLE_SDK" 2>/dev/null || true
      
      echo "Writable Android SDK created at $WRITABLE_SDK"
    fi
    
    # Override all Android paths to use writable SDK
    export ANDROID_SDK_ROOT="$WRITABLE_SDK"
    export ANDROID_HOME="$WRITABLE_SDK"
    export ANDROID_NDK_HOME="$WRITABLE_SDK/ndk/26.3.11579264"
    
    # Android NDK toolchain configuration - use the writable SDK
    NDK_PATH="$ANDROID_NDK_HOME"
    export CC_aarch64_linux_android="$NDK_PATH/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android34-clang"
    export CXX_aarch64_linux_android="$NDK_PATH/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android34-clang++"
    export AR_aarch64_linux_android="$NDK_PATH/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-ar"
    export CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER="$NDK_PATH/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android34-clang"
    export PUB_CACHE="$HOME/.danawallet/pub-cache"

    echo "Android SDK: $ANDROID_SDK_ROOT"
    echo "Flutter version: $(flutter --version | head -1)"
    echo "Rust toolchain: $(rustc --version)"
    echo "NDK Clang: $CC_aarch64_linux_android"
    echo "Available emulators:"
    emulator -list-avds || echo "No AVDs found. Create one with: flutter emulators --create"
    
    # Check if we need to accept licenses
    yes | flutter doctor --android-licenses > /dev/null 2>&1 || true

    echo "Commands:"
    echo "'just gen-rust' to build rust libs"
    echo "'just' to build and launch flutter app"
  '';
}