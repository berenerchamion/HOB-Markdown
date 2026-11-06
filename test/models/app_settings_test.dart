import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hob_markdown_reader/models/app_settings.dart';
import 'package:hob_markdown_reader/models/readability_settings.dart';

void main() {
  group('ReadabilityThreshold', () {
    test('every default is inside its allowed range', () {
      for (final t in ReadabilityThreshold.values) {
        expect(t.defaultValue, inInclusiveRange(t.min, t.max), reason: t.name);
      }
    });

    test('every check has at least one threshold', () {
      for (final check in ReadabilityCheck.values) {
        expect(
          ReadabilityThreshold.forCheck(check),
          isNotEmpty,
          reason: check.name,
        );
      }
    });
  });

  group('ReadabilitySettings', () {
    test('starts with every check on and every default value', () {
      const settings = ReadabilitySettings();
      expect(settings.isDefault, isTrue);
      for (final check in ReadabilityCheck.values) {
        expect(settings.isEnabled(check), isTrue);
      }
      expect(settings.valueOf(ReadabilityThreshold.sentenceMaxWords), 20);
      expect(settings.valueOf(ReadabilityThreshold.paragraphMaxWords), 150);
    });

    test('withValue clamps to the allowed range', () {
      const t = ReadabilityThreshold.sentenceMaxWords;
      final low = const ReadabilitySettings().withValue(t, 1);
      final high = const ReadabilitySettings().withValue(t, 5000);
      expect(low.valueOf(t), t.min);
      expect(high.valueOf(t), t.max);
    });

    test('setting a value back to its default drops the override', () {
      const t = ReadabilityThreshold.sectionMaxWords;
      final changed = const ReadabilitySettings().withValue(t, 400);
      expect(changed.isDefault, isFalse);

      final back = changed.withValue(t, t.defaultValue);
      expect(back.isDefault, isTrue);
      expect(back.toJson()['thresholds'], isEmpty);
    });

    test('turning a check off and on again', () {
      const check = ReadabilityCheck.passiveVoice;
      final off = const ReadabilitySettings().withCheckEnabled(check, false);
      expect(off.isEnabled(check), isFalse);
      expect(off.withCheckEnabled(check, true), const ReadabilitySettings());
    });

    test('round-trips through JSON', () {
      final settings = const ReadabilitySettings()
          .withCheckEnabled(ReadabilityCheck.transitionWords, false)
          .withValue(ReadabilityThreshold.passiveMaxPercent, 15);

      expect(ReadabilitySettings.fromJson(settings.toJson()), settings);
    });

    test('fromJson skips unknown names and wrong types, and clamps', () {
      final settings = ReadabilitySettings.fromJson({
        'disabled': ['sentenceLength', 'noSuchCheck', 42],
        'thresholds': {
          'paragraphMaxWords': 99999,
          'noSuchThreshold': 10,
          'sectionMaxWords': 'lots',
        },
      });

      expect(settings.isEnabled(ReadabilityCheck.sentenceLength), isFalse);
      expect(
        settings.valueOf(ReadabilityThreshold.paragraphMaxWords),
        ReadabilityThreshold.paragraphMaxWords.max,
      );
      expect(settings.valueOf(ReadabilityThreshold.sectionMaxWords), 300);
    });
  });

  group('AppSettings', () {
    test('defaults', () {
      const settings = AppSettings();
      expect(settings.themeMode, ThemeMode.system);
      expect(settings.liveReload, isTrue);
      expect(settings.readability.isDefault, isTrue);
    });

    test('round-trips through JSON', () {
      final settings = AppSettings(
        themeMode: ThemeMode.dark,
        liveReload: false,
        readability: const ReadabilitySettings().withValue(
          ReadabilityThreshold.readingEaseMinScore,
          50,
        ),
      );

      final json = settings.toJson();
      expect(json['version'], AppSettings.formatVersion);
      expect(AppSettings.fromJson(json), settings);
    });

    test('fromJson falls back to defaults for missing or bad fields', () {
      final settings = AppSettings.fromJson({
        'themeMode': 'purple',
        'liveReload': 'yes',
        'readability': 'not a map',
      });
      expect(settings, const AppSettings());
    });
  });
}
