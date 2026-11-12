import 'package:flutter/material.dart';

enum SyntaxLanguage { html, css, javascript }

class SyntaxPalette {
  static const Color htmlComment = Color(0xFF505050);
  static const Color comment = Color(0xFF78FF81);
  static const Color tag = Color(0xFFFF8370);
  static const Color parameter = Color(0xFFFF8FF2);
  static const Color string = Color(0xFFF0FF80);
  static const Color number = Color(0xFFF0FF80);
  static const Color value = Color(0xFFF0FF80);
  static const Color punctuation = Color(0xFFD0D0D0);
}

class SyntaxHighlightingController extends TextEditingController {
  SyntaxHighlightingController({required this.language, super.text});

  final SyntaxLanguage language;

  static final RegExp _htmlPattern = RegExp(
    r'''(?<comment><!--[\s\S]*?-->)|(?<doctype><!DOCTYPE[^>]*>)|(?<tag></?[a-zA-Z][\w-]*)|(?<string>"[^"]*"|'[^']*')|(?<attribute>\b[a-zA-Z_:][\w:.-]*\b)(?=\s*=)|(?<bracket>[<>/])''',
    caseSensitive: false,
    multiLine: true,
  );

  static final RegExp _cssPattern = RegExp(
    r'''(?<comment>/\*[\s\S]*?\*/)|(?<string>"[^"]*"|'[^']*')|(?<atrule>@[a-zA-Z-]+)|(?<property>[a-zA-Z-]+)(?=\s*:)|(?<selector>[.#]?[a-zA-Z][\w-]*)(?=\s*\{)|(?<number>#[0-9a-fA-F]{3,8}\b|\b\d+(?:\.\d+)?(?:px|em|rem|%|vh|vw|s|ms|deg|fr)?\b)|(?<value>[a-zA-Z][\w-]*)|(?<punct>[{}:;])''',
    multiLine: true,
  );

  static final RegExp _javascriptPattern = RegExp(
    r'''(?<comment>//[^\n]*|/\*[\s\S]*?\*/)|(?<string>"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|`(?:\\.|[^`\\])*`)|(?<keyword>\b(?:const|let|var|function|return|if|else|for|while|do|switch|case|break|continue|new|class|extends|import|export|from|default|async|await|try|catch|finally|throw|typeof|instanceof|this|super|null|undefined|true|false|void|delete|in|of|yield|static|get|set)\b)|(?<number>\b\d+(?:\.\d+)?\b)|(?<function>\b[A-Za-z_$][\w$]*(?=\s*\())''',
    multiLine: true,
  );

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    return buildHighlightedSpan(style ?? const TextStyle());
  }

  TextSpan buildHighlightedSpan(TextStyle style) {
    if (text.isEmpty) {
      return TextSpan(style: style, text: '');
    }

    final pattern = switch (language) {
      SyntaxLanguage.html => _htmlPattern,
      SyntaxLanguage.css => _cssPattern,
      SyntaxLanguage.javascript => _javascriptPattern,
    };

    final children = <InlineSpan>[];
    var cursor = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > cursor) {
        children.add(TextSpan(text: text.substring(cursor, match.start)));
      }

      final color = _colorFor(match);
      children.add(
        TextSpan(
          text: match.group(0),
          style: color == null ? null : TextStyle(color: color),
        ),
      );
      cursor = match.end;
    }

    if (cursor < text.length) {
      children.add(TextSpan(text: text.substring(cursor)));
    }

    return TextSpan(style: style, children: children);
  }

  Color? _colorFor(RegExpMatch match) {
    switch (language) {
      case SyntaxLanguage.html:
        if (match.namedGroup('comment') != null) {
          return SyntaxPalette.htmlComment;
        }
        if (match.namedGroup('doctype') != null) {
          return SyntaxPalette.htmlComment;
        }
        if (match.namedGroup('tag') != null) {
          return SyntaxPalette.tag;
        }
        if (match.namedGroup('attribute') != null) {
          return SyntaxPalette.parameter;
        }
        if (match.namedGroup('string') != null) {
          return SyntaxPalette.string;
        }
        if (match.namedGroup('bracket') != null) {
          return SyntaxPalette.punctuation;
        }
      case SyntaxLanguage.css:
        if (match.namedGroup('comment') != null) {
          return SyntaxPalette.comment;
        }
        if (match.namedGroup('string') != null) {
          return SyntaxPalette.string;
        }
        if (match.namedGroup('atrule') != null) {
          return SyntaxPalette.tag;
        }
        if (match.namedGroup('property') != null) {
          return SyntaxPalette.parameter;
        }
        if (match.namedGroup('selector') != null) {
          return SyntaxPalette.tag;
        }
        if (match.namedGroup('number') != null) {
          return SyntaxPalette.number;
        }
        if (match.namedGroup('value') != null) {
          return SyntaxPalette.value;
        }
        if (match.namedGroup('punct') != null) {
          return SyntaxPalette.punctuation;
        }
      case SyntaxLanguage.javascript:
        if (match.namedGroup('comment') != null) {
          return SyntaxPalette.comment;
        }
        if (match.namedGroup('string') != null) {
          return SyntaxPalette.string;
        }
        if (match.namedGroup('keyword') != null) {
          return SyntaxPalette.tag;
        }
        if (match.namedGroup('number') != null) {
          return SyntaxPalette.number;
        }
        if (match.namedGroup('function') != null) {
          return SyntaxPalette.parameter;
        }
    }
    return null;
  }
}
