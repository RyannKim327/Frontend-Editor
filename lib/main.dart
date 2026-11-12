import 'package:flutter/material.dart';

import 'features/workspace/workspace_page.dart';

void main() {
  runApp(const FrontendEditorApp());
}

class FrontendEditorApp extends StatelessWidget {
  const FrontendEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.amber,
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'Kimmy Dev Server',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFF111318),
        useMaterial3: true,
      ),
      home: const WorkspacePage(),
    );
  }
}
