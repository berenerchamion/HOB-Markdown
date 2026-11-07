import 'package:flutter/material.dart';

import '../models/readability_settings.dart';
import '../services/readability_service.dart';

// Display text and colours for readability checks, shared by the settings
// dialog, the review panel and the editor highlights.

/// The check's title and a one-line description.
(String, String) readabilityCheckText(ReadabilityCheck check) =>
    switch (check) {
      ReadabilityCheck.sentenceLength => (
        'Sentence length',
        'Flags documents with too many long sentences.',
      ),
      ReadabilityCheck.paragraphLength => (
        'Paragraph length',
        'Flags paragraphs that run too long.',
      ),
      ReadabilityCheck.subheadingDistribution => (
        'Subheading distribution',
        'Flags long stretches of text without a heading.',
      ),
      ReadabilityCheck.passiveVoice => (
        'Passive voice',
        'Flags documents with a lot of passive voice. English only.',
      ),
      ReadabilityCheck.consecutiveSentences => (
        'Repeated sentence openings',
        'Flags runs of sentences that start with the same word.',
      ),
      ReadabilityCheck.transitionWords => (
        'Transition words',
        'Flags documents with few linking words, such as "however" or '
            '"because". English only.',
      ),
      ReadabilityCheck.readingEase => (
        'Reading ease',
        'Flesch reading ease, from 0 (very hard) to 100 (very easy). '
            'English only.',
      ),
    };

/// Highlight colour for checks that mark individual sentences or phrases in
/// the editor. Paragraph and document-level checks return null: they're
/// listed in the review panel instead, because tinting whole paragraphs would
/// bury the sentence highlights.
Color? readabilityHighlightColor(
  ReadabilityCheck check,
  Brightness brightness,
) {
  final dark = brightness == Brightness.dark;
  return switch (check) {
    ReadabilityCheck.sentenceLength =>
      dark ? const Color(0x66B8860B) : const Color(0x66FFD54F),
    ReadabilityCheck.passiveVoice =>
      dark ? const Color(0x664A7FD4) : const Color(0x5590CAF9),
    ReadabilityCheck.consecutiveSentences =>
      dark ? const Color(0x669C5BD1) : const Color(0x55CE93D8),
    _ => null,
  };
}

/// One or two sentences describing a check's result, for the review panel.
String readabilityResultText(
  ReadabilityResult result,
  ReadabilitySettings settings,
) {
  int v(ReadabilityThreshold t) => settings.valueOf(t);
  final r = result;
  return switch (r.check) {
    ReadabilityCheck.sentenceLength =>
      '${r.count} of ${_plural(r.total, 'sentence')} (${r.percent}%) '
          '${r.count == 1 ? 'is' : 'are'} over '
          '${v(ReadabilityThreshold.sentenceMaxWords)} words. '
          'Aim for ${v(ReadabilityThreshold.longSentenceMaxPercent)}% or less.',
    ReadabilityCheck.paragraphLength =>
      r.count == 0
          ? 'No paragraphs over '
                '${v(ReadabilityThreshold.paragraphMaxWords)} words.'
          : '${_plural(r.count, 'paragraph')} over '
                '${v(ReadabilityThreshold.paragraphMaxWords)} words, at '
                '${_lines(r.lines)}.',
    ReadabilityCheck.subheadingDistribution =>
      r.count == 0
          ? 'No stretch runs over '
                '${v(ReadabilityThreshold.sectionMaxWords)} words without a '
                'heading.'
          : '${_plural(r.count, 'section')} over '
                '${v(ReadabilityThreshold.sectionMaxWords)} words without a '
                'heading, starting at ${_lines(r.lines)}.',
    ReadabilityCheck.passiveVoice =>
      '${r.count} of ${_plural(r.total, 'sentence')} (${r.percent}%) '
          'use${r.count == 1 ? 's' : ''} passive voice. '
          'Aim for ${v(ReadabilityThreshold.passiveMaxPercent)}% or less.',
    ReadabilityCheck.consecutiveSentences =>
      r.count == 0
          ? 'No runs of ${v(ReadabilityThreshold.consecutiveMaxRun)} or more '
                'sentences starting with the same word.'
          : '${_plural(r.count, 'run')} of sentences '
                'start${r.count == 1 ? 's' : ''} with the same word.',
    ReadabilityCheck.transitionWords =>
      '${r.count} of ${_plural(r.total, 'sentence')} (${r.percent}%) '
          'use${r.count == 1 ? 's' : ''} transition words. '
          'Aim for ${v(ReadabilityThreshold.transitionMinPercent)}% or more.',
    ReadabilityCheck.readingEase =>
      r.score == null
          ? 'Not enough text to score yet.'
          : 'Score ${r.score!.round()} (${_easeLabel(r.score!)}). '
                'Aim for ${v(ReadabilityThreshold.readingEaseMinScore)} or '
                'higher.',
  };
}

String _plural(int n, String noun) => '$n $noun${n == 1 ? '' : 's'}';

String _lines(List<int> lines) {
  if (lines.length == 1) return 'line ${lines.first}';
  const shown = 4;
  if (lines.length <= shown) {
    return 'lines ${lines.sublist(0, lines.length - 1).join(', ')} '
        'and ${lines.last}';
  }
  return 'lines ${lines.take(shown).join(', ')} '
      'and ${lines.length - shown} more';
}

String _easeLabel(double score) => switch (score) {
  >= 90 => 'very easy',
  >= 80 => 'easy',
  >= 70 => 'fairly easy',
  >= 60 => 'plain English',
  >= 50 => 'fairly hard',
  >= 30 => 'hard',
  _ => 'very hard',
};
