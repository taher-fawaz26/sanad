/// Sand Dependencies — centralized re-export of all third-party packages.
///
/// Import this package instead of individual third-party packages so that
/// version bumps are made in one place and dependency graph stays manageable.
library;

// ── Networking ───────────────────────────────────────────────────────────────
export 'package:connectivity_plus/connectivity_plus.dart';
export 'package:dio/dio.dart';
// ── Localization ────────────────────────────────────────────────────────────
export 'package:easy_localization/easy_localization.dart';
// ── Functional programming & DI ─────────────────────────────────────────────
export 'package:equatable/equatable.dart';
// ── State management ────────────────────────────────────────────────────────
export 'package:flutter_bloc/flutter_bloc.dart';
// ── UI / Layout ─────────────────────────────────────────────────────────────
export 'package:flutter_screenutil/flutter_screenutil.dart';
// ── Persistence ─────────────────────────────────────────────────────────────
export 'package:flutter_secure_storage/flutter_secure_storage.dart';
export 'package:fpdart/fpdart.dart';
export 'package:get_it/get_it.dart';
// ── Navigation ──────────────────────────────────────────────────────────────
export 'package:go_router/go_router.dart';
export 'package:hive_ce/hive.dart';
export 'package:hydrated_bloc/hydrated_bloc.dart';
export 'package:intl/intl.dart';
// ── Utilities ───────────────────────────────────────────────────────────────
export 'package:logger/logger.dart';
export 'package:meta/meta.dart';
export 'package:path_provider/path_provider.dart';
export 'package:provider/provider.dart';
