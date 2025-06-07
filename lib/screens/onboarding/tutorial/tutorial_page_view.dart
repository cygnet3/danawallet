import 'package:danawallet/screens/onboarding/get_started.dart';
import 'package:danawallet/screens/onboarding/onboarding_skeleton.dart';
import 'package:danawallet/screens/onboarding/tutorial/tutorial_1.dart';
import 'package:danawallet/screens/onboarding/tutorial/tutorial_2.dart';
import 'package:danawallet/screens/onboarding/tutorial/tutorial_3.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class TutorialPageView extends StatefulWidget {
  const TutorialPageView({super.key});

  @override
  State<StatefulWidget> createState() => TutorialPageViewState();
}

class TutorialPageViewState extends State<TutorialPageView> {
  PageController controller = PageController();
  int _curr = 0;
  final List<Widget> _list = <Widget>[
    const TutorialScreen1(),
    const TutorialScreen2(),
    const TutorialScreen3(),
  ];

  void onPressNext() {
    if (_curr == _list.length - 1) {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const GetStartedScreen()));
    } else {
      controller.jumpToPage(_curr + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final footer = Column(
      children: [
        SizedBox(
          height: Adaptive.h(3),
        ),
        DotsIndicator(
          dotsCount: 3,
          position: _curr.toDouble(),
        ),
        const SizedBox(
          height: 15,
        ),
        FooterButton(
          title: 'Next',
          onPressed: onPressNext,
        )
      ],
    );

    final body = PageView(
      controller: controller,
      scrollDirection: Axis.horizontal,
      onPageChanged: (nmb) {
        setState(() {
          _curr = nmb;
        });
      },
      children: _list,
    );

    return OnboardingSkeleton(body: body, footer: footer);
  }
}
