import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hob_markdown_reader/models/app_settings.dart';
import 'package:hob_markdown_reader/services/settings_service.dart';

class ThrowingSettingsStore implements SettingsStore {
  @override
  Future<String?> read() async => throw Exception('Preferences unavailable');

  @override
  Future<void> write(String value) async =>
      throw Exception('Preferences unavailable');
}

void main() {
  group('SettingsService', () {
    test('load gives defaults when nothing has been saved', () async {
      final service = SettingsService(store: MemorySettingsStore());
      expect(await service.load(), const AppSettings());
    });

    test('save then load returns the same settings', () async {
      final store = MemorySettingsStore();
      const settings = AppSettings(
        themeMode: ThemeMode.light,
        liveReload: false,
      );

      await SettingsService(store: store).save(settings);
      expect(await SettingsService(store: store).load(), settings);
    });

    test('load gives defaults for corrupt JSON', () async {
      final service = SettingsService(store: MemorySettingsStore('{not json'));
      expect(await service.load(), const AppSettings());
    });

    test('load gives defaults for JSON that is not an object', () async {
      final service = SettingsService(store: MemorySettingsStore('[1, 2]'));
      expect(await service.load(), const AppSettings());
    });

    test('a failing store never throws', () async {
      final service = SettingsService(store: ThrowingSettingsStore());
      expect(await service.load(), const AppSettings());
      await expectLater(service.save(const AppSettings()), completes);
    });
  });
}
