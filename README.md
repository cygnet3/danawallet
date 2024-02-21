# Donation wallet

Donationwallet is a flutter app used for accepting bitcoin donations. It uses silent payments, a new static payments protocol, to receive donations while preserving on-chain privacy.

## Building

First clone the repository, along with the submodule

```
git clone --recursive https://github.com/cygnet3/donationwallet.git
```

Next, if building for android, you need build the android binaries. This will require the rust toolchain. See instructions in the [sp-backend](https://github.com/cygnet3/sp-backend) repository.

Connect your phone and enable debugging mode.
Then, check if you phone is connected by running

```
flutter devices
```

Finally, to build and install the app for your android device:

```
flutter run
```