import 'package:flutter/services.dart';

class AutoIndentFormatter extends TextInputFormatter {
  AutoIndentFormatter({required this.indentSize});

  final int indentSize;

  static const _voidHtmlTags = {
    'area',
    'base',
    'br',
    'col',
    'embed',
    'hr',
    'img',
    'input',
    'link',
    'meta',
    'param',
    'source',
    'track',
    'wbr',
  };

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!_isNewlineInsertion(oldValue, newValue)) {
      return newValue;
    }

    final cursor = newValue.selection.baseOffset;
    final beforeNewline = newValue.text.substring(0, cursor - 1);
    final lineStart = beforeNewline.lastIndexOf('\n') + 1;
    final currentLine = beforeNewline.substring(lineStart);
    final leadingWhitespace = _leadingWhitespace(currentLine);
    final extraIndent = _opensBlock(currentLine.trimRight())
        ? ' ' * indentSize
        : '';
    final insertion = leadingWhitespace + extraIndent;

    if (insertion.isEmpty) {
      return newValue;
    }

    final text =
        newValue.text.substring(0, cursor) +
        insertion +
        newValue.text.substring(cursor);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: cursor + insertion.length),
      composing: TextRange.empty,
    );
  }

  bool _isNewlineInsertion(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length != oldValue.text.length + 1) {
      return false;
    }
    final cursor = newValue.selection.baseOffset;
    if (cursor < 1 || cursor > newValue.text.length) {
      return false;
    }
    return newValue.text[cursor - 1] == '\n';
  }

  String _leadingWhitespace(String line) {
    final match = RegExp(r'^[ \t]*').firstMatch(line);
    return match?.group(0) ?? '';
  }

  bool _opensBlock(String line) {
    if (line.isEmpty) {
      return false;
    }

    final last = line[line.length - 1];
    if (last == '{' || last == '(' || last == '[') {
      return true;
    }

    if (last != '>') {
      return false;
    }

    final openIndex = line.lastIndexOf('<');
    if (openIndex == -1) {
      return false;
    }

    final tag = line.substring(openIndex);
    if (tag.startsWith('</') || tag.startsWith('<!') || tag.endsWith('/>')) {
      return false;
    }

    final nameMatch = RegExp(r'^<\s*([a-zA-Z0-9-]+)').firstMatch(tag);
    final tagName = nameMatch?.group(1)?.toLowerCase();
    return tagName == null || !_voidHtmlTags.contains(tagName);
  }
}
