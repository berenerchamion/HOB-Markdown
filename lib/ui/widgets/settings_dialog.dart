import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/readability_settings.dart';
import '../../state/reader_controller.dart';
import '../readability_style.dart';

/// Opens the settings dialog. Changes apply and save immediately, like a
/// macOS settings window, so there is no Save or Cancel.
Future<void> showSettingsDialog(
  BuildContext context,
  ReaderController controller,
) {
  return showDialog<void>(
    context: context,
    builder: (context) => SettingsDialog(controller: controller),
  );
}

class SettingsDialog extends StatelessWidget {
  final ReaderController controller;

  const SettingsDialog({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final settings = controller.settings;
            final readability = settings.readability;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Settings',
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Close',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _SectionHeader('General'),
                        ListTile(
                          title: const Text('Theme'),
                          trailing: SegmentedButton<ThemeMode>(
                            showSelectedIcon: false,
                            segments: const [
                              ButtonSegment(
                                value: ThemeMode.system,
                                label: Text('System'),
                              ),
                              ButtonSegment(
                                value: ThemeMode.light,
                                label: Text('Light'),
                              ),
                              ButtonSegment(
                                value: ThemeMode.dark,
                                label: Text('Dark'),
                              ),
                            ],
                            selected: {settings.themeMode},
                            onSelectionChanged: (selection) =>
                                controller.setThemeMode(selection.first),
                          ),
                        ),
                        SwitchListTile(
                          title: const Text('Live reload'),
                          subtitle: const Text(
                            'Reload the open file when it changes on disk.',
                          ),
                          value: settings.liveReload,
                          onChanged: (value) => controller.updateSettings(
                            settings.copyWith(liveReload: value),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const _SectionHeader('Readability'),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Text(
                            'Limits for readability review. Review stays off '
                            'while you write and runs only when you turn it on.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        for (final check in ReadabilityCheck.values)
                          _CheckSettings(
                            check: check,
                            settings: readability,
                            onChanged: (next) => controller.updateSettings(
                              settings.copyWith(readability: next),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              icon: const Icon(Icons.restore_rounded, size: 18),
                              label: const Text('Restore readability defaults'),
                              onPressed: readability.isDefault
                                  ? null
                                  : () => controller.updateSettings(
                                      settings.copyWith(
                                        readability:
                                            const ReadabilitySettings(),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// One check: an on/off switch, then its thresholds.
class _CheckSettings extends StatelessWidget {
  final ReadabilityCheck check;
  final ReadabilitySettings settings;
  final ValueChanged<ReadabilitySettings> onChanged;

  const _CheckSettings({
    required this.check,
    required this.settings,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = settings.isEnabled(check);
    final (title, description) = readabilityCheckText(check);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          title: Text(title),
          subtitle: Text(description),
          value: enabled,
          onChanged: (value) =>
              onChanged(settings.withCheckEnabled(check, value)),
        ),
        for (final threshold in ReadabilityThreshold.forCheck(check))
          _ThresholdField(
            threshold: threshold,
            value: settings.valueOf(threshold),
            enabled: enabled,
            onChanged: (value) =>
                onChanged(settings.withValue(threshold, value)),
          ),
      ],
    );
  }
}

/// A number field that applies its value only when it's within range, and
/// otherwise shows the allowed range instead of quietly clamping.
class _ThresholdField extends StatefulWidget {
  final ReadabilityThreshold threshold;
  final int value;
  final bool enabled;
  final ValueChanged<int> onChanged;

  const _ThresholdField({
    required this.threshold,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  State<_ThresholdField> createState() => _ThresholdFieldState();
}

class _ThresholdFieldState extends State<_ThresholdField> {
  late final TextEditingController _text = TextEditingController(
    text: '${widget.value}',
  );
  String? _error;

  @override
  void didUpdateWidget(_ThresholdField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Follow changes made elsewhere, such as Restore defaults, without
    // overwriting a half-typed number when some other setting changes.
    if (oldWidget.value != widget.value &&
        int.tryParse(_text.text) != widget.value) {
      _text.text = '${widget.value}';
      _error = null;
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    final t = widget.threshold;
    final value = int.tryParse(text);
    if (value == null || value < t.min || value > t.max) {
      setState(() => _error = '${t.min}–${t.max}');
      return;
    }
    setState(() => _error = null);
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, unit) = _thresholdText(widget.threshold);
    final unitStyle = theme.textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: widget.enabled
                      ? null
                      : theme.colorScheme.onSurface.withValues(alpha: 0.38),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // The unit sits outside the field so the field's whole width is
          // left for the number: with "words" inside it, four-digit values
          // were cut off.
          SizedBox(
            width: 108,
            child: TextField(
              key: ValueKey('threshold-${widget.threshold.name}'),
              controller: _text,
              enabled: widget.enabled,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(
                  widget.threshold.max.toString().length,
                ),
              ],
              textAlign: TextAlign.end,
              onChanged: _onChanged,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                border: const OutlineInputBorder(),
                errorText: _error,
              ),
            ),
          ),
          // Sized to the widest unit in the current font and text size, so
          // every row lines up and "words" can never wrap.
          SizedBox(
            width: _unitColumnWidth(context, unitStyle),
            child: Padding(
              padding: const EdgeInsets.only(left: 8, top: 10),
              child: Text(
                unit,
                maxLines: 1,
                softWrap: false,
                style: unitStyle?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: widget.enabled ? 1 : 0.38,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Width of the unit column: the widest unit, plus its left padding.
double _unitColumnWidth(BuildContext context, TextStyle? style) {
  var widest = 0.0;
  for (final t in ReadabilityThreshold.values) {
    final painter = TextPainter(
      text: TextSpan(text: _thresholdText(t).$2, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    if (painter.width > widest) widest = painter.width;
    painter.dispose();
  }
  return (widest + 8).ceilToDouble();
}

/// The field label, and the short unit shown inside the field.
(String, String) _thresholdText(ReadabilityThreshold threshold) =>
    switch (threshold) {
      ReadabilityThreshold.sentenceMaxWords => (
        'Maximum length of a sentence in words:',
        '',
      ),
      ReadabilityThreshold.longSentenceMaxPercent => (
        'Warn when this % of sentences are longer than the maximum:',
        '%',
      ),
      ReadabilityThreshold.paragraphMaxWords => (
        'Maximum length of a paragraph in words:',
        '',
      ),
      ReadabilityThreshold.sectionMaxWords => (
        'Maximum number of words between headings:',
        '',
      ),
      ReadabilityThreshold.passiveMaxPercent => (
        'Warn when passive sentences are more than:',
        '%',
      ),
      ReadabilityThreshold.consecutiveMaxRun => (
        'Warn when this many sentences in a row start with the same word:',
        '',
      ),
      ReadabilityThreshold.transitionMinPercent => (
        'Warn when fewer sentences than this use transition words:',
        '%',
      ),
      ReadabilityThreshold.readingEaseMinScore => (
        'Warn if the Flesch score is below:',
        '',
      ),
    };
