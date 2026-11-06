/// The readability checks HOB Markdown can run on a document.
///
/// Display text lives in the UI layer, so these stay plain identifiers.
enum ReadabilityCheck {
  sentenceLength,
  paragraphLength,
  subheadingDistribution,
  passiveVoice,
  consecutiveSentences,
  transitionWords,
  readingEase,
}

/// A user-adjustable limit used by one [ReadabilityCheck].
///
/// Each threshold carries its own default and allowed range, so the settings
/// screen can build its fields from this list instead of hardcoding them.
enum ReadabilityThreshold {
  sentenceMaxWords(
    ReadabilityCheck.sentenceLength,
    defaultValue: 20,
    min: 5,
    max: 100,
  ),
  longSentenceMaxPercent(
    ReadabilityCheck.sentenceLength,
    defaultValue: 25,
    min: 0,
    max: 100,
  ),
  paragraphMaxWords(
    ReadabilityCheck.paragraphLength,
    defaultValue: 150,
    min: 20,
    max: 1000,
  ),
  sectionMaxWords(
    ReadabilityCheck.subheadingDistribution,
    defaultValue: 300,
    min: 50,
    max: 2000,
  ),
  passiveMaxPercent(
    ReadabilityCheck.passiveVoice,
    defaultValue: 10,
    min: 0,
    max: 100,
  ),
  consecutiveMaxRun(
    ReadabilityCheck.consecutiveSentences,
    defaultValue: 3,
    min: 2,
    max: 10,
  ),
  transitionMinPercent(
    ReadabilityCheck.transitionWords,
    defaultValue: 30,
    min: 0,
    max: 100,
  ),
  readingEaseMinScore(
    ReadabilityCheck.readingEase,
    defaultValue: 60,
    min: 0,
    max: 100,
  );

  const ReadabilityThreshold(
    this.check, {
    required this.defaultValue,
    required this.min,
    required this.max,
  });

  final ReadabilityCheck check;
  final int defaultValue;
  final int min;
  final int max;

  static List<ReadabilityThreshold> forCheck(ReadabilityCheck check) =>
      values.where((t) => t.check == check).toList();
}

/// Which readability checks are on, and the limits they use.
///
/// Only values that differ from the defaults are stored. That way, if a later
/// version improves a default, people who never changed it get the new one.
class ReadabilitySettings {
  final Set<ReadabilityCheck> _disabled;
  final Map<ReadabilityThreshold, int> _overrides;

  const ReadabilitySettings() : _disabled = const {}, _overrides = const {};

  const ReadabilitySettings._(this._disabled, this._overrides);

  bool isEnabled(ReadabilityCheck check) => !_disabled.contains(check);

  int valueOf(ReadabilityThreshold threshold) =>
      _overrides[threshold] ?? threshold.defaultValue;

  bool get isDefault => _disabled.isEmpty && _overrides.isEmpty;

  ReadabilitySettings withCheckEnabled(ReadabilityCheck check, bool enabled) {
    final disabled = {..._disabled};
    if (enabled) {
      disabled.remove(check);
    } else {
      disabled.add(check);
    }
    return ReadabilitySettings._(disabled, _overrides);
  }

  /// Returns a copy with [threshold] set to [value], clamped to its range.
  ReadabilitySettings withValue(ReadabilityThreshold threshold, int value) {
    final clamped = value.clamp(threshold.min, threshold.max);
    final overrides = {..._overrides};
    if (clamped == threshold.defaultValue) {
      overrides.remove(threshold);
    } else {
      overrides[threshold] = clamped;
    }
    return ReadabilitySettings._(_disabled, overrides);
  }

  Map<String, dynamic> toJson() => {
    'disabled': [for (final check in _disabled) check.name],
    'thresholds': {
      for (final entry in _overrides.entries) entry.key.name: entry.value,
    },
  };

  /// Reads settings saved by any version of the app. Unknown names and
  /// values of the wrong type are skipped, and numbers are clamped.
  factory ReadabilitySettings.fromJson(Map<String, dynamic> json) {
    var settings = const ReadabilitySettings();

    final disabled = json['disabled'];
    if (disabled is List) {
      for (final name in disabled) {
        final check = ReadabilityCheck.values.asNameMap()[name];
        if (check != null) {
          settings = settings.withCheckEnabled(check, false);
        }
      }
    }

    final thresholds = json['thresholds'];
    if (thresholds is Map) {
      for (final entry in thresholds.entries) {
        final threshold = ReadabilityThreshold.values.asNameMap()[entry.key];
        final value = entry.value;
        if (threshold != null && value is num) {
          settings = settings.withValue(threshold, value.round());
        }
      }
    }

    return settings;
  }

  @override
  bool operator ==(Object other) =>
      other is ReadabilitySettings &&
      _disabled.length == other._disabled.length &&
      _disabled.containsAll(other._disabled) &&
      _overrides.length == other._overrides.length &&
      _overrides.entries.every((e) => other._overrides[e.key] == e.value);

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(_disabled),
    Object.hashAllUnordered(
      _overrides.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );
}
