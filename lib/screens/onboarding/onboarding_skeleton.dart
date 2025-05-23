import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class OnboardingSkeleton extends StatelessWidget {
  final Widget body;
  final Widget footer;
  const OnboardingSkeleton({
    super.key,
    required this.body,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = Adaptive.h(3.8);
    final horizontalPadding = Adaptive.h(3);
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: null,
        ),
        body: Padding(
            padding: EdgeInsets.fromLTRB(
                horizontalPadding, 0, horizontalPadding, bottomPadding),
            child: Column(
              children: [
                Expanded(child: body),
                footer,
              ],
            )));
  }
}
