# Donation wallet

Donationwallet is a flutter app used for accepting bitcoin donations. It uses silent payments, a new static payments protocol, to receive donations while preserving on-chain privacy.

## Building for android

Building for an android device requires some preparatory work, to generate binaries for this architecture.

First, you need `cargo-ndk`. You may also need to add your desired toolchains:

```
cargo install cargo-ndk
rustup target add \
    aarch64-linux-android \
    armv7-linux-androideabi \
    x86_64-linux-android \
    i686-linux-android
```

After these are installed, go in to the rust directory and run `just build-android`.

```
cd rust
just build-android
```

If you don't have `just` installed, you can also copy the commands found in the `justfile`.
This generates the binaries.

Next, connect your phone and enable debugging mode.
Check if you phone is connected by running

```
flutter devices
```

Finally, to build and install the app for your android device:

```
flutter run
```
