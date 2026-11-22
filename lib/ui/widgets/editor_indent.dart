import 'package:flutter/services.dart';

/// One level of indentation: two spaces. Spaces rather than a tab because
/// Flutter draws a tab one space wide, and two because that's enough to nest
/// a `-` list item. Shift+Tab also removes a leading tab, for files that use
/// them.
const int _spacesPerIndent = 2;
const String _indent = '  ';

/// Tab in the editor, as code editors do it: with a cursor or a selection
/// inside one line, the selection is replaced by one indent. With a selection
/// that spans lines, an indent is added to the start of every selected line
/// instead, so pressing Tab doesn't delete the selected text.
TextEditingValue indentText(TextEditingValue value) {
  final selection = value.selection;
  if (!selection.isValid) return value;
  final text = value.text;
  if (selection.isCollapsed || !selection.textInside(text).contains('\n')) {
    return value.replaced(selection, _indent);
  }

  final starts = _selectedLineStarts(text, selection);
  final buffer = StringBuffer();
  var last = 0;
  for (final start in starts) {
    buffer
      ..write(text.substring(last, start))
      ..write(_indent);
    last = start;
  }
  buffer.write(text.substring(last));

  // Each indent inserted before an offset pushes it right. A selection that
  // starts at a line start stays put, so it covers the new indent too.
  int map(int offset) =>
      offset + _indent.length * starts.where((s) => s < offset).length;
  return TextEditingValue(
    text: buffer.toString(),
    selection: TextSelection(
      baseOffset: map(selection.baseOffset),
      extentOffset: map(selection.extentOffset),
    ),
  );
}

/// Shift+Tab in the editor: removes one level of indentation (a leading tab,
/// or up to two leading spaces) from the cursor's line, or from every line
/// the selection touches. Returns [value] unchanged if there is nothing to
/// remove.
TextEditingValue outdentText(TextEditingValue value) {
  final selection = value.selection;
  if (!selection.isValid) return value;
  final text = value.text;

  final removals = <int, int>{}; // line start -> characters removed
  for (final start in _selectedLineStarts(text, selection)) {
    var count = 0;
    if (start < text.length && text[start] == '\t') {
      count = 1;
    } else {
      while (count < _spacesPerIndent &&
          start + count < text.length &&
          text[start + count] == ' ') {
        count++;
      }
    }
    if (count > 0) removals[start] = count;
  }
  if (removals.isEmpty) return value;

  final buffer = StringBuffer();
  var last = 0;
  removals.forEach((start, count) {
    buffer.write(text.substring(last, start));
    last = start + count;
  });
  buffer.write(text.substring(last));

  // Offsets after a removed run move left by its length; offsets inside the
  // run land at the start of the line.
  int map(int offset) {
    var shift = 0;
    removals.forEach((start, count) {
      if (start < offset) {
        shift += (offset - start) < count ? offset - start : count;
      }
    });
    return offset - shift;
  }

  return TextEditingValue(
    text: buffer.toString(),
    selection: TextSelection(
      baseOffset: map(selection.baseOffset),
      extentOffset: map(selection.extentOffset),
    ),
  );
}

/// Start offsets of the lines [selection] touches. A selection that ends
/// exactly at the start of a line (after selecting whole lines) doesn't
/// include that line, matching what editors do.
List<int> _selectedLineStarts(String text, TextSelection selection) {
  final first = selection.start == 0
      ? 0
      : text.lastIndexOf('\n', selection.start - 1) + 1;
  final starts = <int>[first];
  var newline = text.indexOf('\n', first);
  while (newline != -1 && newline + 1 < selection.end) {
    starts.add(newline + 1);
    newline = text.indexOf('\n', newline + 1);
  }
  return starts;
}
