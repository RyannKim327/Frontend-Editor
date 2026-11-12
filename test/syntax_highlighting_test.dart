import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_editor/features/editor/syntax_highlighting_controller.dart';

Set<Color?> colorsOf(SyntaxHighlightingController controller) {
  final span = controller.buildHighlightedSpan(const TextStyle());
  return {
    for (final child in span.children ?? const <InlineSpan>[])
      if (child is TextSpan) child.style?.color,
  };
}

void main() {
  test('highlights HTML tags, attributes, strings and comments', () {
    final controller = SyntaxHighlightingController(
      language: SyntaxLanguage.html,
      text: '<!-- c -->\n<div class="card">Hi</div>',
    );

    final colors = colorsOf(controller);

    expect(colors, contains(SyntaxPalette.htmlComment));
    expect(colors, contains(SyntaxPalette.tag));
    expect(colors, contains(SyntaxPalette.parameter));
    expect(colors, contains(SyntaxPalette.string));
  });

  test('highlights CSS selectors, properties, values and comments', () {
    final controller = SyntaxHighlightingController(
      language: SyntaxLanguage.css,
      text: '/* c */\n.card { color: red; width: 10px; }',
    );

    final colors = colorsOf(controller);

    expect(colors, contains(SyntaxPalette.comment));
    expect(colors, contains(SyntaxPalette.tag));
    expect(colors, contains(SyntaxPalette.parameter));
    expect(colors, contains(SyntaxPalette.value));
    expect(colors, contains(SyntaxPalette.number));
  });

  test('highlights JavaScript keywords, functions, strings and numbers', () {
    final controller = SyntaxHighlightingController(
      language: SyntaxLanguage.javascript,
      text: '// c\nconst x = "hi"; if (x) { run(42); }',
    );

    final colors = colorsOf(controller);

    expect(colors, contains(SyntaxPalette.comment));
    expect(colors, contains(SyntaxPalette.tag));
    expect(colors, contains(SyntaxPalette.string));
    expect(colors, contains(SyntaxPalette.number));
    expect(colors, contains(SyntaxPalette.parameter));
  });
}
