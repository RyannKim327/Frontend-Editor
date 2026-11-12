import 'package:flutter/material.dart';

import 'auto_indent_formatter.dart';

class EditorPanel extends StatelessWidget {
  const EditorPanel({
    super.key,
    required this.files,
    required this.selectedFile,
    required this.controller,
    required this.onFileSelected,
    required this.onChanged,
    required this.fontSize,
    required this.indentSize,
    required this.wrap,
  });

  final List<String> files;
  final String selectedFile;
  final TextEditingController controller;
  final ValueChanged<String> onFileSelected;
  final ValueChanged<String> onChanged;
  final double fontSize;
  final int indentSize;
  final bool wrap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: fontSize,
      height: 1.45,
      color: Colors.white,
    );

    final field = TextField(
      controller: controller,
      onChanged: onChanged,
      expands: true,
      maxLines: null,
      minLines: null,
      textAlignVertical: TextAlignVertical.top,
      keyboardType: TextInputType.multiline,
      autocorrect: false,
      enableSuggestions: false,
      style: textStyle,
      cursorColor: Colors.amber,
      scrollPadding: EdgeInsets.zero,
      inputFormatters: [AutoIndentFormatter(indentSize: indentSize)],
      decoration: const InputDecoration(
        border: InputBorder.none,
        isCollapsed: true,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: theme.colorScheme.surfaceContainerHighest,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final file in files)
                  _FileTab(
                    label: file,
                    selected: file == selectedFile,
                    onTap: () => onFileSelected(file),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ColoredBox(
            color: const Color(0xFF0B0D10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: wrap
                  ? field
                  : ListenableBuilder(
                      listenable: controller,
                      builder: (context, _) => LayoutBuilder(
                        builder: (context, constraints) => _horizontalField(
                          field: field,
                          textStyle: textStyle,
                          minWidth: constraints.maxWidth,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _horizontalField({
    required Widget field,
    required TextStyle textStyle,
    required double minWidth,
  }) {
    var longestLine = '';
    for (final line in controller.text.split('\n')) {
      if (line.length > longestLine.length) {
        longestLine = line;
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 0, minWidth: minWidth),
              child: Padding(
                padding: const EdgeInsets.only(right: 32),
                child: Text(longestLine, style: textStyle),
              ),
            ),
            Expanded(child: field),
          ],
        ),
      ),
    );
  }
}

class _FileTab extends StatelessWidget {
  const _FileTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? theme.colorScheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
