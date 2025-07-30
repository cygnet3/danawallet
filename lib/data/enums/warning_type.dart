import 'package:flutter/material.dart';

enum WarningType {
  info,
  warn,
  error;

  Color get toColor {
    switch (this) {
      case WarningType.info:
        return Colors.blue[700]!;
      case WarningType.warn:
        return Colors.orange[700]!;
      case WarningType.error:
        return Colors.red[700]!;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case WarningType.info:
        return Colors.blue[100]!;
      case WarningType.warn:
        return Colors.orange[100]!;
      case WarningType.error:
        return Colors.red[100]!;
    }
  }

  IconData get icon {
    switch (this) {
      case WarningType.info:
        return Icons.info_rounded;
      case WarningType.warn:
        return Icons.warning_amber_rounded;
      case WarningType.error:
        return Icons.warning_amber_rounded;
    }
  }
}
