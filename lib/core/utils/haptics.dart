import 'package:flutter/services.dart';

/// Centralised haptic feedback helpers. Use [Haptics.tap] for primary CTAs and
/// [Haptics.select] for lighter selection/toggle interactions.
class Haptics {
  const Haptics._();

  /// Light impact — primary buttons, default tap on a CTA.
  static Future<void> tap() => HapticFeedback.lightImpact();

  /// Medium impact — destructive or strong primary actions (Save, Submit).
  static Future<void> strong() => HapticFeedback.mediumImpact();

  /// Selection click — toggles, radios, segmented controls.
  static Future<void> select() => HapticFeedback.selectionClick();

  /// Wraps a [VoidCallback] so it fires a tap haptic before running.
  static VoidCallback? wrap(VoidCallback? callback) {
    if (callback == null) return null;
    return () {
      HapticFeedback.lightImpact();
      callback();
    };
  }

  /// Wraps an async callback (returning Future) so it fires a tap haptic
  /// before running.
  static Future<void> Function()? wrapAsync(
    Future<void> Function()? callback,
  ) {
    if (callback == null) return null;
    return () async {
      HapticFeedback.lightImpact();
      await callback();
    };
  }
}
