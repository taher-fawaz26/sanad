import 'package:flutter/cupertino.dart' show BuildContext;
import 'package:flutter/material.dart' show BuildContext;
import 'package:flutter/widgets.dart' show BuildContext;
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// **Device breakpoint classification for typography scaling.**
///
/// Detected once from [ScreenUtil.screenWidth] — no [BuildContext] required.
/// The result is cached per app-lifetime via `_cache` so that repeated calls
/// inside the font engine are O(1) with zero heap allocations.
///
/// Multiplier philosophy:
/// - Small phones need a *slight* boost to keep text readable.
/// - Tablets intentionally use < 1.0 to prevent font explosion.
/// - xlTablet returns to 1.0 because the screen is large enough that
///   ScreenUtil's own scale already compensates.
enum DeviceClass {
  /// Width < 360 dp
  small(0.94),

  /// Width 360–479 dp (design baseline)
  normal(1),

  /// Width 480–599 dp
  large(1.04),

  /// Width 600–839 dp
  tablet(0.98),

  /// Width ≥ 840 dp
  xlTablet(0.96);

  const DeviceClass(this.fontMultiplier);

  /// Scalar applied inside the font engine — no double-scaling.
  final double fontMultiplier;
}

/// **Font-engine helper — cached device classification.**
///
/// Call [DeviceClassDetector.current] from inside `responsiveFontSize`.
/// The class is resolved lazily on first access and then frozen for the
/// lifetime of the current ScreenUtil initialisation.
abstract final class DeviceClassDetector {
  DeviceClassDetector._();

  static DeviceClass? _cache;

  /// Returns the [DeviceClass] for the current device.
  ///
  /// Safe to call from static / non-widget contexts after [ScreenUtilInit]
  /// has completed its first build.
  static DeviceClass get current {
    if (_cache != null) return _cache!;

    final width = ScreenUtil().screenWidth;

    // Guard against early access before ScreenUtilInit has run.
    // screenWidth is 0 until ScreenUtil initialises — return the neutral
    // baseline so the engine stays safe without crashing.
    if (width == 0) return DeviceClass.normal;

    return _cache = _resolve();
  }

  /// Invalidates the cached value.
  ///
  /// [ScreenUtilInit] can run again after orientation or window size changes;
  /// the width guard usually refreshes the cache. Call explicitly in widget
  /// tests after forcing new device constraints.
  static void invalidate() => _cache = null;

  static DeviceClass _resolve() {
    // Called only after width-guard confirms ScreenUtil is ready.
    final width = ScreenUtil().screenWidth;
    if (width < 360) return DeviceClass.small;
    if (width < 480) return DeviceClass.normal;
    if (width < 600) return DeviceClass.large;
    if (width < 840) return DeviceClass.tablet;
    return DeviceClass.xlTablet;
  }
}
