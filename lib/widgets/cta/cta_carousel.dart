import 'package:flutter/material.dart';

class CtaCarousel extends StatefulWidget {
  final List<Widget> ctas;
  final double maxHeight;

  const CtaCarousel({
    super.key,
    required this.ctas,
    this.maxHeight = 200.0,
  });

  @override
  State<CtaCarousel> createState() => _CtaCarouselState();
}

class _CtaCarouselState extends State<CtaCarousel> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ctas.isEmpty) {
      return const SizedBox.shrink();
    }

    // If only one CTA, show it directly without carousel
    if (widget.ctas.length == 1) {
      return widget.ctas.first;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // CTA carousel with fixed height for compact CTAs
        SizedBox(
          height: 50, // Fixed height for compact CTAs
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.ctas.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: widget.ctas[index],
              );
            },
          ),
        ),
        
        // Page indicators (only if more than one CTA)
        if (widget.ctas.length > 1) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.ctas.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == index
                      ? const Color(0xFF007AFF)
                      : const Color(0xFFD1D1D6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }
}
