import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_editor/features/editor/editor_panel.dart';

Widget buildEditor({
  required TextEditingController controller,
  bool wrap = true,
  int indentSize = 2,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 320,
        height: 400,
        child: EditorPanel(
          files: const ['index.html', 'styles.css'],
          selectedFile: 'index.html',
          controller: controller,
          onFileSelected: (_) {},
          onChanged: (_) {},
          fontSize: 14,
          indentSize: indentSize,
          wrap: wrap,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders file tabs and editor', (tester) async {
    final controller = TextEditingController(text: '<h1>Hi</h1>');
    addTearDown(controller.dispose);

    await tester.pumpWidget(buildEditor(controller: controller));

    expect(find.text('index.html'), findsOneWidget);
    expect(find.text('styles.css'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('renders without wrapping', (tester) async {
    final controller = TextEditingController(
      text: 'const value = "a very long line that should not wrap";',
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      buildEditor(controller: controller, wrap: false, indentSize: 4),
    );

    expect(find.byType(TextField), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
