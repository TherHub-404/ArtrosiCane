import 'package:flutter/widgets.dart';

/// Reference design width (logical px) the UI was laid out against.
/// Modern phones cluster around 390-412 dp; narrow Android devices
/// (e.g. Samsung Galaxy S26 / S26+) report ~360 dp.
const double kBaselineWidth = 390.0;

/// Lower/upper bounds for the width scale factor so tiny phones stay
/// readable and tablets do not blow type up disproportionately.
const double _minWidthScale = 0.82;
const double _maxWidthScale = 1.10;

/// Responsive helpers driven by the current screen width.
///
/// Use [BuildContextResponsive.scaled] for font sizes, spacing, and image
/// dimensions so a layout tuned at [kBaselineWidth] adapts down to ~360 dp
/// (Galaxy S26+) and ~320 dp without text wrapping awkwardly or overflowing.
extension BuildContextResponsive on BuildContext {
  /// Current screen width in logical pixels.
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// Current screen height in logical pixels.
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// Width-based scale factor relative to [kBaselineWidth], clamped to a
  /// sane range so layouts never collapse or balloon.
  double get widthScale =>
      (screenWidth / kBaselineWidth).clamp(_minWidthScale, _maxWidthScale);

  /// Scales a logical dimension (font size, spacing, image size) to the
  /// current screen width.
  double scaled(double value) => value * widthScale;

  /// Scales a value but never above its baseline (useful for spacing that
  /// should shrink on small screens but not grow on large ones).
  double scaledDown(double value) =>
      value * widthScale.clamp(_minWidthScale, 1.0);
}
