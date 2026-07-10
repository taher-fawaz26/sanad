import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

part 'theme_event.dart';
part 'theme_state.dart';

class ThemeBloc extends HydratedBloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(const ThemeState(AppThemeMode.light)) {
    on<LightThemeEvent>(
      (_, emit) => emit(const ThemeState(AppThemeMode.light)),
    );
    on<DarkThemeEvent>(
      (_, emit) => emit(const ThemeState(AppThemeMode.dark)),
    );
    on<SystemThemeEvent>(
      (_, emit) => emit(const ThemeState(AppThemeMode.system)),
    );
  }

  @override
  ThemeState? fromJson(Map<String, dynamic> json) => ThemeState.fromMap(json);

  @override
  Map<String, dynamic>? toJson(ThemeState state) => state.toMap();
}
