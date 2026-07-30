import 'package:flutter/material.dart';

/// Root navigator key shared by the provider app's GoRouter and asset picker.
///
/// Required so the document scanner can push its fullscreen route when the user
/// selects Scan Document.
final GlobalKey<NavigatorState> providerRootNavigatorKey =
    GlobalKey<NavigatorState>();
