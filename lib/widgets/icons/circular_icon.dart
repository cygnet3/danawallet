import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class CircularIcon extends StatelessWidget {
  final String iconPath;
  final double? iconHeight;
  final double radius;
  final Color color;

  const CircularIcon(
      {super.key,
      required this.iconPath,
      required this.radius,
      this.iconHeight,
      this.color = danaBlue});
  @override
  Widget build(BuildContext context) {
    final icon = SvgPicture.asset(
      height: iconHeight,
      iconPath,
      colorFilter: ColorFilter.mode(Bitcoin.white, BlendMode.srcIn),
    );

    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: icon,
    );
  }
}
