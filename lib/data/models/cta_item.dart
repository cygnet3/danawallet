import 'package:flutter/material.dart';

/// Represents a Call-to-Action item in the CTA carousel
class CtaItem {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final Widget Function(BuildContext context, VoidCallback onComplete) dialogBuilder;
  final bool isDismissible;

  const CtaItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.dialogBuilder,
    this.isDismissible = true,
  });
}

