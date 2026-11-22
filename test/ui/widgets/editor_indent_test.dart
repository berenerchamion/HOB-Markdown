import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hob_markdown_reader/ui/widgets/editor_indent.dart';

TextEditingValue v(String text, int base, [int? extent]) => TextEditingValue(
  text: text,
  selection: TextSelection(baseOffset: base, extentOffset: extent ?? base),
);

void main() {
  group('indentText', () {
    test('inserts two spaces at the cursor', () {
      final r = indentText(v('ab', 1));
      expect(r.text, 'a  b');
      expect(r.selection, const TextSelection.collapsed(offset: 3));
    });

    test('replaces a selection inside one line', () {
      expect(indentText(v('abcd', 1, 3)).text, 'a  d');
    });

    test('indents every line of a multi-line selection', () {
      // Selects from inside "one" to inside "two".
      final r = indentText(v('one\ntwo\nthree', 1, 5));
      expect(r.text, '  one\n  two\nthree');
      expect(r.selection, const TextSelection(baseOffset: 3, extentOffset: 9));
    });

    test('a selection ending at a line start leaves that line alone', () {
      final r = indentText(v('one\ntwo\nthree', 0, 8));
      expect(r.text, '  one\n  two\nthree');
      expect(r.selection, const TextSelection(baseOffset: 0, extentOffset: 12));
    });
  });

  group('outdentText', () {
    test('removes a leading tab from the cursor line', () {
      final r = outdentText(v('a\n\tb', 4));
      expect(r.text, 'a\nb');
      expect(r.selection, const TextSelection.collapsed(offset: 3));
    });

    test('removes up to two leading spaces', () {
      expect(outdentText(v('    x', 5)).text, '  x');
      expect(outdentText(v(' x', 2)).text, 'x');
    });

    test('a cursor inside the indent moves to the line start', () {
      final r = outdentText(v('  x', 1));
      expect(r.text, 'x');
      expect(r.selection, const TextSelection.collapsed(offset: 0));
    });

    test('outdents every selected line, skipping unindented ones', () {
      final r = outdentText(v('\tone\ntwo\n  three', 1, 11));
      expect(r.text, 'one\ntwo\nthree');
      expect(r.selection, const TextSelection(baseOffset: 0, extentOffset: 8));
    });

    test('returns the same value when nothing is indented', () {
      final value = v('abc', 1);
      expect(identical(outdentText(value), value), isTrue);
    });
  });
}
