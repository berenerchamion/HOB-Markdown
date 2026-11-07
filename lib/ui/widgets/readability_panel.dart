import 'package:flutter/material.dart';

import '../../models/readability_settings.dart';
import '../../services/readability_service.dart';
import '../../state/reader_controller.dart';
import '../readability_style.dart';
import 'settings_dialog.dart';

/// Side panel listing the readability results for the current document.
///
/// Only shown while review is on. It lists results and never pops up or
/// steals focus, so it can stay open while writing.
class ReadabilityPanel extends StatelessWidget {
  final ReaderController controller;

  const ReadabilityPanel({super.key, required this.controller});

  static const double width = 300;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final report = controller.readabilityReport;
    final settings = controller.settings.readability;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(left: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Readability',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  tooltip: 'Readability settings',
                  onPressed: () => showSettingsDialog(context, controller),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  tooltip: 'Close review',
                  onPressed: controller.toggleReview,
                ),
              ],
            ),
          ),
          if (report != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                '${report.wordCount} words · '
                '${report.sentenceCount} sentences',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: report == null
                ? const SizedBox.shrink()
                : _Results(report: report, settings: settings),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Text(
              [
                if (controller.viewMode == ViewMode.rendered)
                  'Highlights show in the Source and Split views.',
                'Checks are tuned for English and are only a guide.',
              ].join(' '),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Results extends StatelessWidget {
  final ReadabilityReport report;
  final ReadabilitySettings settings;

  const _Results({required this.report, required this.settings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (report.results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'All readability checks are turned off in Settings.',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        for (final result in report.results)
          Padding(
            key: ValueKey('readability-${result.check.name}'),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(
                    result.passed
                        ? Icons.check_circle_outline_rounded
                        : Icons.error_outline_rounded,
                    size: 18,
                    color: result.passed
                        ? colorScheme.primary
                        : colorScheme.tertiary,
                    semanticLabel: result.passed ? 'Good' : 'Needs work',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              readabilityCheckText(result.check).$1,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (readabilityHighlightColor(
                                result.check,
                                theme.brightness,
                              )
                              case final swatch?) ...[
                            const SizedBox(width: 8),
                            // Matches the highlight colour in the editor.
                            Container(
                              width: 14,
                              height: 10,
                              decoration: BoxDecoration(
                                color: swatch,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        readabilityResultText(result, settings),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
