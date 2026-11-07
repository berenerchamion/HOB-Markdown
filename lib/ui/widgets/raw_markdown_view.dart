import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/document_model.dart';
import '../../models/readability_settings.dart';
import '../../services/readability_service.dart';
import '../readability_style.dart';

class RawMarkdownView extends StatefulWidget {
  final DocumentModel document;
  final double scaleFactor;
  final ScrollController? scrollController;
  final ValueChanged<String>? onChanged;

  /// Readability findings to highlight, or null when review is off.
  final ReadabilityReport? review;

  const RawMarkdownView({
    super.key,
    required this.document,
    required this.scaleFactor,
    this.scrollController,
    this.onChanged,
    this.review,
  });

  @override
  State<RawMarkdownView> createState() => _RawMarkdownViewState();
}

class _RawMarkdownViewState extends State<RawMarkdownView> {
  static const double _leftPad = 16;
  static const double _topPad = 20;
  static const double _rightPad = 24;
  static const double _gutterRightPadding = 14;
  static const double _gutterRightMargin = 14;
  static const double _dividerWidth = 1;
  static const double _lineHeightFactor = 1.6;

  late final _ReviewTextController _textController;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _internalScrollController = ScrollController();

  // Keys used to reach the real render objects. The gutter is drawn from the
  // editor's actual layout, so it can never disagree with where text wraps.
  final GlobalKey _fieldKey = GlobalKey();
  final GlobalKey _stackKey = GlobalKey();
  final ValueNotifier<int> _repaintTick = ValueNotifier<int>(0);
  RenderEditable? _editable;

  Timer? _debounceTimer;
  bool _copied = false;

  /// How long typing has to stop before readability highlights come back.
  /// Long enough that they don't flash back between sentences while
  /// someone is still writing.
  static const Duration reviewResumeDelay = Duration(seconds: 5);
  Timer? _reviewResumeTimer;
  late String _lastText;

  // Character offset where each logical line starts. Cheap to rebuild (one
  // pass of indexOf) and holds only ints, never per-line strings or widgets.
  List<int> _lineStarts = const [0];

  // Cached, already-laid-out painters for the line-number labels.
  final Map<int, TextPainter> _numberPainters = {};
  String _numberStyleKey = '';
  TextStyle? _gutterStyle;
  StrutStyle? _strut;
  TextScaler _scaler = TextScaler.noScaling;

  ScrollController get _effectiveScrollController =>
      widget.scrollController ?? _internalScrollController;

  @override
  void initState() {
    super.initState();
    _textController = _ReviewTextController(text: widget.document.content)
      ..review = widget.review;
    _lineStarts = _computeLineStarts(widget.document.content);
    _lastText = widget.document.content;
    _textController.addListener(_handleTextChange);
  }

  @override
  void didUpdateWidget(RawMarkdownView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // No notify needed: this widget is rebuilding anyway, which rebuilds the
    // TextField and asks the controller for fresh spans.
    _textController.review = widget.review;
    // If the document content was updated externally (e.g. file reload/open)
    if (widget.document.content != _textController.text &&
        widget.document.path != oldWidget.document.path) {
      final cursor = _textController.selection;
      // A reload or newly opened file isn't typing, so don't pause review.
      _lastText = widget.document.content;
      _textController.text = widget.document.content;
      if (cursor.isValid && cursor.end <= widget.document.content.length) {
        _textController.selection = cursor;
      }
      setState(() {
        _lineStarts = _computeLineStarts(widget.document.content);
      });
    }
  }

  List<int> _computeLineStarts(String text) {
    final starts = <int>[0];
    var i = text.indexOf('\n');
    while (i != -1) {
      starts.add(i + 1);
      i = text.indexOf('\n', i + 1);
    }
    return starts;
  }

  void _handleTextChange() {
    // The listener also fires for cursor moves and selections; only real
    // edits should hide the highlights.
    if (_textController.text != _lastText) {
      _lastText = _textController.text;
      _pauseReview();
    }

    final starts = _computeLineStarts(_textController.text);
    final digitsChanged =
        starts.length.toString().length != _lineStarts.length.toString().length;
    _lineStarts = starts;

    // The gutter repaints itself when the text changes (it listens to the
    // controller), so a rebuild is only needed when the number column has to
    // get wider or narrower.
    if (digitsChanged) setState(() {});

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
      if (mounted && widget.onChanged != null) {
        widget.onChanged!(_textController.text);
      }
    });
  }

  void _pauseReview() {
    _textController.reviewPaused = true;
    _reviewResumeTimer?.cancel();
    _reviewResumeTimer = Timer(reviewResumeDelay, () {
      if (mounted) setState(() => _textController.reviewPaused = false);
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

  /// Walks the render tree below [root] and returns the first [RenderEditable],
  /// the object that actually lays out and wraps the text.
  RenderEditable? _findRenderEditable(RenderObject? root) {
    RenderEditable? found;
    void visit(RenderObject node) {
      if (found != null) return;
      if (node is RenderEditable) {
        found = node;
        return;
      }
      node.visitChildren(visit);
    }

    if (root != null) visit(root);
    return found;
  }

  RenderEditable? _currentEditable() {
    final cached = _editable;
    if (cached != null && cached.attached) return cached;
    _editable = _findRenderEditable(
      _fieldKey.currentContext?.findRenderObject(),
    );
    return _editable;
  }

  TextPainter _numberPainter(int number) {
    final cached = _numberPainters[number];
    if (cached != null) return cached;
    if (_numberPainters.length > 800) _clearNumberPainters();
    final painter = TextPainter(
      text: TextSpan(text: '$number', style: _gutterStyle),
      textDirection: TextDirection.ltr,
      strutStyle: _strut,
      textScaler: _scaler,
    )..layout();
    _numberPainters[number] = painter;
    return painter;
  }

  void _clearNumberPainters() {
    for (final painter in _numberPainters.values) {
      painter.dispose();
    }
    _numberPainters.clear();
  }

  /// Width needed for the widest line number.
  double _measureGutterContentWidth(
    TextStyle style,
    TextScaler scaler,
    int digits,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: '0' * digits, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width.ceilToDouble();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _reviewResumeTimer?.cancel();
    _textController.removeListener(_handleTextChange);
    _textController.dispose();
    _focusNode.dispose();
    _internalScrollController.dispose();
    _repaintTick.dispose();
    _clearNumberPainters();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final codeFont = GoogleFonts.jetBrainsMono(
      fontSize: 13.5 * widget.scaleFactor,
      height: _lineHeightFactor,
      color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
    );

    final gutterFont = GoogleFonts.jetBrainsMono(
      fontSize: 13.5 * widget.scaleFactor,
      height: _lineHeightFactor,
      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
    );

    // Shared strut: every row in the editor and every gutter label is exactly
    // fontSize x height tall, regardless of font metrics.
    final strutStyle = StrutStyle(
      fontFamily: codeFont.fontFamily,
      fontFamilyFallback: codeFont.fontFamilyFallback,
      fontSize: codeFont.fontSize,
      height: _lineHeightFactor,
      forceStrutHeight: true,
    );

    final scaler = MediaQuery.textScalerOf(context);
    final digits = _lineStarts.length.toString().length;
    final gutterWidth = _measureGutterContentWidth(gutterFont, scaler, digits);

    // Throw away cached labels if their look changed (zoom, theme, text scale).
    final styleKey =
        '${gutterFont.fontSize}|${gutterFont.color}|${scaler.scale(13.5)}';
    if (styleKey != _numberStyleKey) {
      _clearNumberPainters();
      _numberStyleKey = styleKey;
    }
    _gutterStyle = gutterFont;
    _strut = strutStyle;
    _scaler = scaler;

    final lineHeight = codeFont.fontSize! * _lineHeightFactor;
    final textLeft =
        gutterWidth + _gutterRightPadding + _dividerWidth + _gutterRightMargin;
    final dividerX = gutterWidth + _gutterRightPadding + _dividerWidth / 2;

    return Stack(
      children: [
        // The LayoutBuilder makes this subtree rebuild when the window is
        // resized (which changes where lines wrap); the post-frame tick then
        // asks the gutter to repaint against the new layout.
        LayoutBuilder(
          builder: (context, constraints) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _repaintTick.value++;
            });
            return SingleChildScrollView(
              controller: _effectiveScrollController,
              padding: const EdgeInsets.fromLTRB(
                _leftPad,
                _topPad,
                _rightPad,
                40,
              ),
              child: Stack(
                key: _stackKey,
                children: [
                  // Interactive Source Code Editor
                  Padding(
                    padding: EdgeInsets.only(left: textLeft),
                    child: TextField(
                      key: _fieldKey,
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

                  // Line-number gutter, painted only for visible lines.
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        key: const ValueKey('line-number-gutter'),
                        painter: _GutterPainter(
                          repaint: Listenable.merge([
                            _effectiveScrollController,
                            _textController,
                            _repaintTick,
                          ]),
                          currentEditable: _currentEditable,
                          lineStarts: () => _lineStarts,
                          numberPainter: _numberPainter,
                          scroll: _effectiveScrollController,
                          stackKey: _stackKey,
                          topPad: _topPad,
                          lineHeight: lineHeight,
                          gutterWidth: gutterWidth,
                          dividerX: dividerX,
                          dividerColor: colorScheme.outlineVariant,
                        ),
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
              size: 15,
            ),
            label: Text(_copied ? 'Copied' : 'Copy All'),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
          ),
        ),
      ],
    );
  }
}

/// Paints the divider and the line numbers for the lines currently on screen.
///
/// Positions come from the editor's own layout ([RenderEditable]), so wrapped
/// lines and font metrics can't throw the numbers out of alignment. Cost per
/// paint depends on how many lines are visible, not on file length: a binary
/// search finds the first visible line, then only those labels are drawn.
class _GutterPainter extends CustomPainter {
  _GutterPainter({
    required Listenable repaint,
    required this.currentEditable,
    required this.lineStarts,
    required this.numberPainter,
    required this.scroll,
    required this.stackKey,
    required this.topPad,
    required this.lineHeight,
    required this.gutterWidth,
    required this.dividerX,
    required this.dividerColor,
  }) : super(repaint: repaint);

  final RenderEditable? Function() currentEditable;
  final List<int> Function() lineStarts;
  final TextPainter Function(int number) numberPainter;
  final ScrollController scroll;
  final GlobalKey stackKey;
  final double topPad;
  final double lineHeight;
  final double gutterWidth;
  final double dividerX;
  final Color dividerColor;

  @override
  void paint(Canvas canvas, Size size) {
    // Divider spans the full height of the document.
    canvas.drawLine(
      Offset(dividerX, 0),
      Offset(dividerX, size.height),
      Paint()
        ..color = dividerColor
        ..strokeWidth = 1,
    );

    final editable = currentEditable();
    final stackObject = stackKey.currentContext?.findRenderObject();
    final starts = lineStarts();
    if (editable == null ||
        !editable.hasSize ||
        stackObject is! RenderBox ||
        !stackObject.hasSize ||
        starts.isEmpty) {
      return;
    }

    // Where the editor's top edge sits in this painter's coordinate space.
    final originDy = stackObject
        .globalToLocal(editable.localToGlobal(Offset.zero))
        .dy;

    double centerOf(int line) => editable
        .getLocalRectForCaret(TextPosition(offset: starts[line]))
        .center
        .dy;

    // Visible window in editor-local coordinates, with a little overscan.
    final hasScroll = scroll.positions.isNotEmpty;
    final scrollTop = hasScroll ? scroll.positions.last.pixels : 0.0;
    final viewport = hasScroll
        ? scroll.positions.last.viewportDimension
        : size.height;
    final visibleTop = scrollTop - topPad - originDy - lineHeight * 2;
    final visibleBottom =
        scrollTop - topPad - originDy + viewport + lineHeight * 2;

    // Binary search: first line whose centre is at or below the visible top.
    var lo = 0;
    var hi = starts.length - 1;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (centerOf(mid) < visibleTop) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }

    for (var i = lo; i < starts.length; i++) {
      final center = centerOf(i);
      if (center > visibleBottom) break;
      final label = numberPainter(i + 1);
      label.paint(
        canvas,
        Offset(gutterWidth - label.width, originDy + center - label.height / 2),
      );
    }
  }

  // Repainting is driven by the `repaint` listenable (scroll, text, resize),
  // and each paint is cheap, so always repaint when a new painter is supplied.
  @override
  bool shouldRepaint(_GutterPainter oldDelegate) => true;
}

/// Draws readability highlights behind the editor text.
///
/// Highlights are hidden while someone is typing and come back once they've
/// paused for [_RawMarkdownViewState.reviewResumeDelay]. They're also only
/// drawn while the text matches what was analysed, so they can never sit on
/// the wrong words.
class _ReviewTextController extends TextEditingController {
  _ReviewTextController({super.text});

  ReadabilityReport? review;

  /// True while someone is typing, so highlights stay out of the way.
  bool reviewPaused = false;

  // Where two highlights overlap, the more specific one wins: a passive
  // phrase or a repeated opening shows on top of its long sentence.
  static int _priority(ReadabilityCheck check) => switch (check) {
    ReadabilityCheck.sentenceLength => 0,
    _ => 1,
  };

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final report = review;
    if (report == null ||
        reviewPaused ||
        report.source != text ||
        (withComposing && value.isComposingRangeValid)) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }

    final brightness = Theme.of(context).brightness;
    final ranges = <({int start, int end, int priority, Color color})>[];
    for (final issue in report.issues) {
      final color = readabilityHighlightColor(issue.check, brightness);
      if (color == null || issue.end <= issue.start) continue;
      ranges.add((
        start: issue.start,
        end: issue.end,
        priority: _priority(issue.check),
        color: color,
      ));
    }
    if (ranges.isEmpty) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }

    // Sweep the boundaries left to right, keeping the ranges that cover the
    // current segment, and colour each segment by the top one.
    ranges.sort((a, b) => a.start.compareTo(b.start));
    final points = <int>{
      0,
      text.length,
      for (final r in ranges) ...[r.start, r.end],
    }.toList()..sort();

    final children = <TextSpan>[];
    final active = <({int start, int end, int priority, Color color})>[];
    var next = 0;
    for (var p = 0; p < points.length - 1; p++) {
      final a = points[p];
      final b = points[p + 1];
      active.removeWhere((r) => r.end <= a);
      while (next < ranges.length && ranges[next].start <= a) {
        if (ranges[next].end > a) active.add(ranges[next]);
        next++;
      }
      Color? color;
      var best = -1;
      for (final r in active) {
        if (r.priority > best) {
          best = r.priority;
          color = r.color;
        }
      }
      children.add(
        TextSpan(
          text: text.substring(a, b),
          style: color == null ? null : TextStyle(backgroundColor: color),
        ),
      );
    }
    return TextSpan(style: style, children: children);
  }
}
