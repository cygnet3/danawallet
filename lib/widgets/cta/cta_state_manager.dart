import 'package:shared_preferences/shared_preferences.dart';

/// Utility class for managing CTA state persistence
class CtaStateManager {
  static const String _keyCompletedCtas = 'completed_ctas';
  static const String _keyDismissedCtas = 'dismissed_ctas';

  /// Load completed CTAs from storage
  static Future<Set<String>> getCompletedCtas() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_keyCompletedCtas) ?? []).toSet();
  }

  /// Load dismissed CTAs from storage
  static Future<Set<String>> getDismissedCtas() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_keyDismissedCtas) ?? []).toSet();
  }

  /// Save completed CTAs to storage
  static Future<void> setCompletedCtas(Set<String> completedCtas) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyCompletedCtas, completedCtas.toList());
  }

  /// Save dismissed CTAs to storage
  static Future<void> setDismissedCtas(Set<String> dismissedCtas) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyDismissedCtas, dismissedCtas.toList());
  }

  /// Clear all CTA state from storage
  static Future<void> clearCtaState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCompletedCtas);
    await prefs.remove(_keyDismissedCtas);
  }
}
