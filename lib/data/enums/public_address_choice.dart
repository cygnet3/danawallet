import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

enum PublicAddressChoice {
  twitter,
  nostr,
  hrf,
  website;

  String get toName {
    switch (this) {
      case PublicAddressChoice.twitter:
        return "Twitter/X";
      case PublicAddressChoice.nostr:
        return "Nostr";
      case PublicAddressChoice.website:
        return "Your website";
      case PublicAddressChoice.hrf:
        return "Oslo Freedom Forum";
    }
  }

  Widget get icon {
    switch (this) {
      case PublicAddressChoice.twitter:
        return SvgPicture.asset("assets/icons/twitter.svg");
      case PublicAddressChoice.nostr:
        return SvgPicture.asset("assets/icons/nostr.svg");
      case PublicAddressChoice.website:
        return SvgPicture.asset("assets/icons/globe.svg");
      case PublicAddressChoice.hrf:
        return const Image(image: AssetImage('assets/icons/off.png'));
    }
  }
}
