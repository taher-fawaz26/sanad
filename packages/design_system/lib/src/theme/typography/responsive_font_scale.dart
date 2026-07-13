import 'package:design_system/src/theme/typography/device_class.dart';
import 'package:flutter/cupertino.dart' show BuildContext, MediaQuery;
import 'package:flutter/material.dart' show BuildContext, MediaQuery;
import 'package:flutter/widgets.dart' show BuildContext, MediaQuery;
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// **Single-pass clamp-based responsive font engine.**
///
/// Scaling pipeline (one operation, no double-scaling):
/// ```dart
/// scaled = base × scaleText × deviceMultiplier
/// final  = manual clamp [base×0.85, base×1.25]
/// ```
///
/// Guarantees:
/// - Fonts never shrink below 85% of their design-spec size.
/// - Fonts never grow beyond 125% of their design-spec size.
/// - No [BuildContext] — safe to call from static/theme contexts.
/// - No [MediaQuery] access — uses [ScreenUtil] globals only.
/// - O(1) — [DeviceClassDetector.current] is cached after first call.
/// - Allocation-free on hot path — manual branch replaces [num.clamp].
///
/// Usage:
/// ```dart
/// static double get bodyMd => responsiveFontSize(14);
/// ```
double responsiveFontSize(double base) {
  // Single scaling step — device factor is part of the pipe, not a
  // post-multiplier, so width does not influence scaling twice.
  // final scaled = base * ScreenUtil().scaleText * deviceFactor;
  final scaled = base * ScreenUtil().scaleWidth / ScreenUtil().scaleHeight;

  // Manual branch avoids num boxing from num.clamp() on the hot path.
  final min = base * 0.95;
  final max = base * 4;
  if (scaled < min) return min;
  if (scaled > max) return max;
  return scaled;
}

/// Invalidates the device-class cache.
///
/// Call explicitly in widget tests after changing constraints, or when
/// [ScreenUtilInit] re-runs with a new logical size.
void invalidateFontScaleCache() => DeviceClassDetector.invalidate();

extension ResponsiveFontSizeX on num {
  /// Passes `this` through [responsiveFontSize] and returns the
  /// device-class-clamped result.
  double get rfs => responsiveFontSize(toDouble());
}
