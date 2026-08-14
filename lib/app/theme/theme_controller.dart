import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/repository_providers.dart';
import '../../domain/entities/app_settings.dart';

/// Holds the active [ThemeMode], backed by the single-row [AppSettings]
/// table so the choice survives app restarts.
class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController(this._ref) : super(ThemeMode.system) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    final AppSettings settings =
        await _ref.read(settingsRepositoryProvider).getSettings();
    state = _toThemeMode(settings.themeMode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _ref
        .read(settingsRepositoryProvider)
        .updateThemeMode(_toStoredValue(mode));
  }

  static ThemeMode _toThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _toStoredValue(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}

final StateNotifierProvider<ThemeModeController, ThemeMode>
    themeModeControllerProvider =
    StateNotifierProvider<ThemeModeController, ThemeMode>(
  (Ref ref) => ThemeModeController(ref),
);
