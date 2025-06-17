# Dana wallet

Dana is a flutter app used for accepting bitcoin donations. It uses silent payments, a new static payments protocol, to receive donations while preserving on-chain privacy.

## Try out Dana wallet

We are looking into releasing Dana wallet on the popular app stores once the app is more stable.

In the meantime, there are three ways to try out Dana wallet:

- Using Obtanium, download the latest release from GitHub
- Manually download the latest Dana wallet APK from the [releases page](https://github.com/cygnet3/danawallet/releases)
- Using F-Droid, download Dana wallet using our [self-hosted F-Droid repository](https://fdroid.silentpayments.dev/fdroid/repo)

Downloading the APK from the releases page is probably the easiest option.
However, for some extra options (e.g. if you want to test using Mainnet), you'll need to use the F-droid repository option. More info below.

### Getting funds to test

If you downloaded the latest release on Github (either using Obtanium or manually), you will be using the Regtest network.
Regtest is an easy way to quickly try out the wallet using fake coins.

You can get some coins using our regtest faucet:

https://silentpayments.dev/faucet/regtest

Our regtest node produces a new block every minute.
After claiming some coins, you may need to wait up to a minute before the funds appear in your wallet.

### Trying out Mainnet or Signet

**Dana wallet is currently still in an experimental phase. We recommend sticking to regtest or signet. If you really want to test out the wallet on mainnet, only use funds you are willing to lose. We don't take responsibility for lost funds.**

Although using Regtest is an easy way to try out the wallet, it may not be what you want.

If you want to try out Dana on different networks, you can use the 'Signet' or 'Mainnet' flavors, published on our F-droid repository.

#### Adding our F-Droid repository

- Open F-Droid on your android phone
- Go to 'Settings'
- In the 'My Apps' section, click on 'Repositories'
- Add a new repository by clicking the '+' icon
- Scan the QR code found on this page: https://fdroid.silentpayments.dev/fdroid/repo

#### App flavors

There are 4 app 'flavors' hosted on our F-droid repository:

- 'Dana wallet', this is the default flavor, and is identical to the APK released on GitHub. Uses the Regtest network.
- 'Dana wallet - Development', this flavor has some additional extra advanced options/features. May be less stable. Uses the Regtest network.
- 'Dana wallet - Signet', this flavor is for using the Signet network.
- 'Dana wallet - Mainnet', this flavor is for using Mainnet, using real coins. Again, be very careful with this!

## Building Dana wallet from source

Below are some instructions to build Dana wallet from souce. This is only recommended if you want to want to help out with development for Dana wallet.

### Building for linux (desktop)

Building for linux should require no extra effort, simply execute

```
flutter run
```

This may also work on other platforms (macOS, Windows), but we have not tested this.

### Building for android

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
just run-dev
```

## Donate to Dana

You can donate to Dana wallet using our BIP353 address:

> ₿donate@danawallet.app

or you can use the following silent payment-address:

> sp1qq0cygnetgn3rz2kla5cp05nj5uetlsrzez0l4p8g7wehf7ldr93lcqadw65upymwzvp5ed38l8ur2rznd6934xh95msevwrdwtrpk372hyz4vr6g