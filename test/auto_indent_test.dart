import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_editor/features/editor/auto_indent_formatter.dart';

void main() {
  TextEditingValue value(String text, int cursor) => TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: cursor),
  );

  test('keeps the current indentation after a newline', () {
    final formatter = AutoIndentFormatter(indentSize: 2);
    final result = formatter.formatEditUpdate(
      value('  foo', 5),
      value('  foo\n', 6),
    );

    expect(result.text, '  foo\n  ');
    expect(result.selection.baseOffset, 8);
  });

  test('adds indentation after an opening brace', () {
    final formatter = AutoIndentFormatter(indentSize: 2);
    final result = formatter.formatEditUpdate(
      value('body {', 6),
      value('body {\n', 7),
    );

    expect(result.text, 'body {\n  ');
  });

  test('uses the configured indent size', () {
    final formatter = AutoIndentFormatter(indentSize: 4);
    final result = formatter.formatEditUpdate(
      value('  if (x) {', 10),
      value('  if (x) {\n', 11),
    );

    expect(result.text, '  if (x) {\n      ');
  });

  test('indents after an opening HTML tag', () {
    final formatter = AutoIndentFormatter(indentSize: 2);
    final result = formatter.formatEditUpdate(
      value('<div>', 5),
      value('<div>\n', 6),
    );

    expect(result.text, '<div>\n  ');
  });

  test('does not indent after a closing HTML tag', () {
    final formatter = AutoIndentFormatter(indentSize: 2);
    final result = formatter.formatEditUpdate(
      value('</div>', 6),
      value('</div>\n', 7),
    );

    expect(result.text, '</div>\n');
  });

  test('does not indent after a void HTML tag', () {
    final formatter = AutoIndentFormatter(indentSize: 2);
    final result = formatter.formatEditUpdate(
      value('<br>', 4),
      value('<br>\n', 5),
    );

    expect(result.text, '<br>\n');
  });

  test('leaves ordinary edits untouched', () {
    final formatter = AutoIndentFormatter(indentSize: 2);
    final result = formatter.formatEditUpdate(value('a', 1), value('ab', 2));

    expect(result.text, 'ab');
  });
}
