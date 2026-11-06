import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

/// Where the settings JSON is kept. Swappable so tests never touch the
/// real preferences on the machine running them.
abstract class SettingsStore {
  Future<String?> read();
  Future<void> write(String value);
}

/// Keeps settings in memory only. The default, so tests and widgets created
/// without a real store don't need the platform plugin.
class MemorySettingsStore implements SettingsStore {
  String? _value;

  MemorySettingsStore([this._value]);

  @override
  Future<String?> read() async => _value;

  @override
  Future<void> write(String value) async => _value = value;
}

/// Saves settings with the platform's preferences store (UserDefaults on
/// macOS), which works inside the app sandbox.
class SharedPreferencesSettingsStore implements SettingsStore {
  static const String _key = 'settings';

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  @override
  Future<String?> read() => _prefs.getString(_key);

  @override
  Future<void> write(String value) => _prefs.setString(_key, value);
}

class SettingsService {
  final SettingsStore _store;

  SettingsService({SettingsStore? store})
    : _store = store ?? MemorySettingsStore();

  /// Never throws: anything unreadable gives the defaults, because a bad
  /// settings file shouldn't stop someone opening their documents.
  Future<AppSettings> load() async {
    try {
      final raw = await _store.read();
      if (raw == null) return const AppSettings();
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return const AppSettings();
      return AppSettings.fromJson(json);
    } catch (e) {
      debugPrint('HOB Markdown: Failed to load settings, using defaults: $e');
      return const AppSettings();
    }
  }

  /// Never throws: a failed save only means the change won't outlast this
  /// session, which isn't worth interrupting the user for.
  Future<void> save(AppSettings settings) async {
    try {
      await _store.write(jsonEncode(settings.toJson()));
    } catch (e) {
      debugPrint('HOB Markdown: Failed to save settings: $e');
    }
  }
}
