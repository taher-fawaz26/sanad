part of 'theme_bloc.dart';

enum AppThemeMode { light, dark, system }

class ThemeState extends Equatable {
  const ThemeState(this.mode);

  final AppThemeMode mode;

  bool resolvesToDark(BuildContext context) => switch (mode) {
    AppThemeMode.light => false,
    AppThemeMode.dark => true,
    AppThemeMode.system =>
      MediaQuery.platformBrightnessOf(context) == Brightness.dark,
  };

  @override
  List<Object> get props => [mode];

  factory ThemeState.fromMap(Map<String, dynamic> map) {
    final modeValue = map['mode'];
    if (modeValue is String) {
      for (final m in AppThemeMode.values) {
        if (m.name == modeValue) return ThemeState(m);
      }
    }
    if (map['isDarkMode'] == true) return const ThemeState(AppThemeMode.dark);
    return const ThemeState(AppThemeMode.light);
  }

  Map<String, dynamic> toMap() => {'mode': mode.name};
}
