import 'package:flutter/material.dart';

import 'readability_settings.dart';

/// Preferences that persist between launches.
///
/// Secrets such as API keys never go here: this is stored as plain JSON.
class AppSettings {
  /// Bump this when the saved format changes in a way old code can't read.
  static const int formatVersion = 1;

  final ThemeMode themeMode;

  /// Reload the open file when it changes on disk.
  final bool liveReload;

  final ReadabilitySettings readability;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.liveReload = true,
    this.readability = const ReadabilitySettings(),
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? liveReload,
    ReadabilitySettings? readability,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      liveReload: liveReload ?? this.liveReload,
      readability: readability ?? this.readability,
    );
  }

  Map<String, dynamic> toJson() => {
    'version': formatVersion,
    'themeMode': themeMode.name,
    'liveReload': liveReload,
    'readability': readability.toJson(),
  };

  /// Missing or unreadable fields fall back to their defaults, so a damaged
  /// or older settings file never stops the app from starting.
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    const defaults = AppSettings();
    final liveReload = json['liveReload'];
    final readability = json['readability'];
    return AppSettings(
      themeMode:
          ThemeMode.values.asNameMap()[json['themeMode']] ?? defaults.themeMode,
      liveReload: liveReload is bool ? liveReload : defaults.liveReload,
      readability: readability is Map<String, dynamic>
          ? ReadabilitySettings.fromJson(readability)
          : defaults.readability,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      themeMode == other.themeMode &&
      liveReload == other.liveReload &&
      readability == other.readability;

  @override
  int get hashCode => Object.hash(themeMode, liveReload, readability);
}
