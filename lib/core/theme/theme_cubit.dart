import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._sharedPreferences)
      : super(_getInitialThemeMode(_sharedPreferences));

  static const _themePreferenceKey = 'theme_mode';

  final SharedPreferences _sharedPreferences;

  static ThemeMode _getInitialThemeMode(SharedPreferences preferences) {
    final savedTheme = preferences.getString(_themePreferenceKey);

    return switch (savedTheme) {
      'dark' => ThemeMode.dark,
      _ => ThemeMode.light,
    };
  }

  Future<void> toggleTheme() async {
    final nextThemeMode =
        state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;

    await _sharedPreferences.setString(
      _themePreferenceKey,
      nextThemeMode == ThemeMode.dark ? 'dark' : 'light',
    );

    emit(nextThemeMode);
  }
}
