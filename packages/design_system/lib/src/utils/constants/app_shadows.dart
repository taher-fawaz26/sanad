import 'package:flutter/material.dart';

/// Design-system shadow scale — Figma `892:4898` / Box Shadow guide.
///
/// Source of truth: Figma Shadow/Small, Shadow/Medium, Shadow/Large.
/// Color base is `#141414` with alpha from the design tokens.
///
/// Usage:
/// ```dart
/// boxShadow: AppShadows.small
/// ```
abstract final class AppShadows {
  AppShadows._();

  /// ~8% opacity (`#14141414`).
  static const Color _ink08 = Color(0x14141414);

  /// ~4% opacity (`#1414140A`).
  static const Color _ink04 = Color(0x0A141414);

  static const List<BoxShadow> none = [];

  /// Legacy micro elevation — not in Figma Box Shadow guide.
  /// Kept for backward compatibility; prefer [small] for new UI.
  static const List<BoxShadow> xs = [
    BoxShadow(
      color: _ink04,
      blurRadius: 1,
    ),
  ];

  /// Figma **Shadow Small**
  /// - `0 0 8px 0` at 8% `#141414`
  /// - `0 0 1px 0` at 4% `#141414`
  static const List<BoxShadow> small = [
    BoxShadow(
      color: _ink08,
      blurRadius: 8,
    ),
    BoxShadow(
      color: _ink04,
      blurRadius: 1,
    ),
  ];

  /// Figma **Shadow Medium**
  /// - `0 1px 8px 2px` at 8% `#141414`
  /// - `0 0 1px 0` at 8% `#141414`
  static const List<BoxShadow> medium = [
    BoxShadow(
      color: _ink08,
      blurRadius: 8,
      offset: Offset(0, 1),
      spreadRadius: 2,
    ),
    BoxShadow(
      color: _ink08,
      blurRadius: 1,
    ),
  ];

  /// Figma **Shadow Large**
  /// - `0 1px 24px 8px` at 8% `#141414`
  /// - `0 0 1px 0` at 8% `#141414`
  static const List<BoxShadow> large = [
    BoxShadow(
      color: _ink08,
      blurRadius: 24,
      offset: Offset(0, 1),
      spreadRadius: 8,
    ),
    BoxShadow(
      color: _ink08,
      blurRadius: 1,
    ),
  ];
}
