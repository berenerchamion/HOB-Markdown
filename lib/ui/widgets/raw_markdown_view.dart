import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/document_model.dart';

class RawMarkdownView extends StatefulWidget {
  final DocumentModel document;
  final double scaleFactor;
  final ScrollController? scrollController;
  final ValueChanged<String>? onChanged;

  const RawMarkdownView({
    super.key,
    required this.document,
    required this.scaleFactor,
    this.scrollController,
    this.onChanged,
  });

  @override
  State<RawMarkdownView> createState() => _RawMarkdownViewState();
}

class _RawMarkdownViewState extends State<RawMarkdownView> {
  late final TextEditingController _textController;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _internalScrollController = ScrollController();
  Timer? _debounceTimer;
  bool _copied = false;
  int _lineCount = 1;

  ScrollController get _effectiveScrollController =>
      widget.scrollController ?? _internalScrollController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.document.content);
    _lineCount = _calculateLineCount(widget.document.content);
    _textController.addListener(_handleTextChange);
  }

  @override
  void didUpdateWidget(RawMarkdownView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the document content was updated externally (e.g. file reload/open)
    if (widget.document.content != _textController.text &&
        widget.document.path != oldWidget.document.path) {
      final cursor = _textController.selection;
      _textController.text = widget.document.content;
      if (cursor.isValid && cursor.end <= widget.document.content.length) {
        _textController.selection = cursor;
      }
      setState(() {
        _lineCount = _calculateLineCount(widget.document.content);
      });
    }
  }

  int _calculateLineCount(String text) {
    if (text.isEmpty) return 1;
    return text.split('\n').length;
  }

  void _handleTextChange() {
    final text = _textController.text;
    final newCount = _calculateLineCount(text);
    // Always rebuild so the gutter stays in sync with wrapped lines, not just
    // when the logical line count changes.
    setState(() => _lineCount = newCount);

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
      if (mounted && widget.onChanged != null) {
        widget.onChanged!(text);
      }
    });
  }

  Future<void> _copyAll() async {
    await Clipboard.setData(ClipboardData(text: _textController.text));
    if (mounted) {
      setState(() => _copied = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _copied = false);
        }
      });
    }
  }

  /// Returns the pixel width needed to display the widest line-number label
  /// (i.e. a string of [_lineCount].toString().length zeros in [style]).
  double _measureGutterContentWidth(TextStyle style) {
    final digits = _lineCount.toString().length;
    final painter = TextPainter(
      text: TextSpan(text: '0' * digits, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );
    painter.layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  /// Builds the gutter label widgets.
  ///
  /// For each logical line, it uses [TextPainter] to measure how many visual
  /// rows the line occupies at [textFieldWidth]. It emits the line number for
  /// the first row and a blank [SizedBox] spacer (same height) for every
  /// continuation row, so the gutter stays aligned with the [TextField].
  ///
  /// [strutStyle] must be the same [StrutStyle] applied to the [TextField] so
  /// that gutter text and editor text share an identical line-height contract.
  List<Widget> _buildGutterEntries({
    required String text,
    required TextStyle codeStyle,
    required TextStyle gutterStyle,
    required StrutStyle strutStyle,
    required double textFieldWidth,
  }) {
    final lines = text.isEmpty ? [''] : text.split('\n');
    final entries = <Widget>[];

    // Use the strut's locked line height so gutter spacers are byte-for-byte
    // identical to what the TextField renders.  strutStyle has
    // forceStrutHeight: true, so the actual height is exactly fontSize × height.
    final lineHeight =
        (strutStyle.fontSize ?? codeStyle.fontSize ?? 13.5) *
        (strutStyle.height ?? codeStyle.height ?? 1.6);

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      int visualRows = 1;

      if (line.isNotEmpty && textFieldWidth > 0) {
        final painter = TextPainter(
          text: TextSpan(text: line, style: codeStyle),
          textDirection: TextDirection.ltr,
          strutStyle: strutStyle,
          maxLines: null,
        );
        painter.layout(maxWidth: textFieldWidth);
        visualRows =
            (painter.height / lineHeight).round().clamp(1, 9999);
        painter.dispose();
      }

      // First visual row → line number label, rendered with the shared strut
      // so its line-height box is identical to the TextField's.
      entries.add(Text(
        '${i + 1}',
        style: gutterStyle,
        strutStyle: strutStyle,
      ));

      // Continuation rows → blank spacers that match the strut line height.
      for (int r = 1; r < visualRows; r++) {
        entries.add(SizedBox(height: lineHeight));
      }
    }

    return entries;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _textController.removeListener(_handleTextChange);
    _textController.dispose();
    _focusNode.dispose();
    _internalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final codeFont = GoogleFonts.jetBrainsMono(
      fontSize: 13.5 * widget.scaleFactor,
      height: 1.6,
      color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
    );

    final gutterFont = GoogleFonts.jetBrainsMono(
      fontSize: 13.5 * widget.scaleFactor,
      height: 1.6,
      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
    );

    // A shared StrutStyle applied to both the gutter Text widgets and the
    // TextField.  forceStrutHeight: true locks the line height to exactly
    // fontSize × height, bypassing any font-ascent/descent variability.
    // This is the key guarantee that gutter rows and editor rows are the
    // same pixel height and therefore stay aligned even across many lines.
    final strutStyle = StrutStyle(
      fontFamily: codeFont.fontFamily,
      fontFamilyFallback: codeFont.fontFamilyFallback,
      fontSize: codeFont.fontSize,
      height: 1.6,
      forceStrutHeight: true,
    );

    // Fixed layout constants that mirror the SingleChildScrollView padding and
    // the gutter Container padding / margin, used to derive the true pixel
    // width available to the TextField.
    const double leftPad = 16;
    const double rightPad = 24;
    const double gutterRightPadding = 14;
    const double gutterRightMargin = 14;

    return Stack(
      children: [
        // LayoutBuilder sits outside SingleChildScrollView so its constraints
        // reflect the full widget width (before scroll padding is applied).
        LayoutBuilder(
          builder: (context, constraints) {
            // Round the gutter's content width UP to the nearest physical
            // pixel.  Flutter's layout engine snaps widget dimensions to
            // physical-pixel boundaries, so using the raw floating-point
            // TextPainter width would make textFieldWidth slightly too wide,
            // causing TextPainter to miss wraps that the TextField actually
            // performs.
            final dpr = MediaQuery.devicePixelRatioOf(context);
            final gutterContentWidth =
                (_measureGutterContentWidth(gutterFont) * dpr).ceil() / dpr;

            // Width available to the TextField content after accounting for
            // all surrounding chrome (scroll padding + gutter).
            final textFieldWidth = (constraints.maxWidth -
                    leftPad -
                    rightPad -
                    gutterContentWidth -
                    gutterRightPadding -
                    gutterRightMargin)
                .clamp(1.0, double.infinity);

            final gutterEntries = _buildGutterEntries(
              text: _textController.text,
              codeStyle: codeFont,
              gutterStyle: gutterFont,
              strutStyle: strutStyle,
              textFieldWidth: textFieldWidth,
            );

            return SingleChildScrollView(
              controller: _effectiveScrollController,
              padding:
                  const EdgeInsets.fromLTRB(leftPad, 20, rightPad, 40),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Line Numbers Gutter
                  Container(
                    padding:
                        const EdgeInsets.only(right: gutterRightPadding),
                    margin:
                        const EdgeInsets.only(right: gutterRightMargin),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: colorScheme.outlineVariant,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: gutterEntries,
                    ),
                  ),

                  // Interactive Source Code Editor
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      style: codeFont,
                      strutStyle: strutStyle,
                      cursorColor: colorScheme.primary,
                      cursorWidth: 2,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // Floating Copy All Action
        Positioned(
          top: 14,
          right: 20,
          child: FilledButton.tonalIcon(
            onPressed: _copyAll,
            icon: Icon(
                _copied ? Icons.check_rounded : Icons.copy_rounded,
                size: 15),
            label: Text(_copied ? 'Copied' : 'Copy All'),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
          ),
        ),
      ],
    );
  }
}
