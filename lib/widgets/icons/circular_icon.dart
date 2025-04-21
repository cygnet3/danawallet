import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class CircularIcon extends StatelessWidget {
  final String iconPath;
  final double? iconHeight;
  final double radius;

  const CircularIcon(
      {super.key,
      required this.iconPath,
      required this.radius,
      this.iconHeight});
  @override
  Widget build(BuildContext context) {
    final icon = SvgPicture.asset(
      height: iconHeight,
      iconPath,
      colorFilter: ColorFilter.mode(Bitcoin.white, BlendMode.srcIn),
    );

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color.fromARGB(255, 10, 109, 214),
      child: icon,
    );
  }
}
