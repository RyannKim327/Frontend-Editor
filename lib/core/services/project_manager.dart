import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/project.dart';

class ProjectManager {
  static const String defaultHtml = '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>My Project</title>
  <link rel="stylesheet" href="styles.css">
</head>
<body>
  <main class="card">
    <h1>Hello World</h1>
    <p>Edit the files on the left and the preview reloads automatically.</p>
    <button id="action">Click me</button>
  </main>
  <script src="script.js"></script>
</body>
</html>
''';

  static const String defaultCss = '''* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

body {
  min-height: 100vh;
  display: grid;
  place-items: center;
  font-family: system-ui, sans-serif;
  background: #0f172a;
  color: #e2e8f0;
}

.card {
  padding: 2rem;
  border-radius: 1rem;
  background: #1e293b;
  text-align: center;
}

button {
  margin-top: 1rem;
  padding: 0.6rem 1.2rem;
  border: 0;
  border-radius: 0.5rem;
  background: #f59e0b;
  color: #111827;
  font-weight: 600;
  cursor: pointer;
}
''';

  static const String defaultJs =
      '''const button = document.querySelector('#action');

button?.addEventListener('click', () => {
  button.textContent = 'It works!';
  console.log('Hello from script.js');
});
''';

  Project? _project;

  Project? get project => _project;

  Future<Project> openWorkspace() async {
    final documents = await getApplicationDocumentsDirectory();
    final root = Directory(p.join(documents.path, 'workspace'));
    await root.create(recursive: true);
    await _ensureFile(p.join(root.path, 'index.html'), defaultHtml);
    await _ensureFile(p.join(root.path, 'styles.css'), defaultCss);
    await _ensureFile(p.join(root.path, 'script.js'), defaultJs);

    final project = Project(
      id: 'workspace',
      name: 'My Project',
      rootPath: root.path,
    );
    _project = project;
    return project;
  }

  Future<String> readFile(String relativePath) async {
    return File(_pathFor(relativePath)).readAsString();
  }

  Future<void> writeFile(String relativePath, String contents) async {
    final file = File(_pathFor(relativePath));
    await file.parent.create(recursive: true);
    await file.writeAsString(contents, flush: true);
  }

  Future<void> resetTemplates() async {
    await writeFile('index.html', defaultHtml);
    await writeFile('styles.css', defaultCss);
    await writeFile('script.js', defaultJs);
  }

  String _pathFor(String relativePath) {
    final project = _project;
    if (project == null) {
      throw StateError('No project is open');
    }
    return p.join(project.rootPath, relativePath);
  }

  Future<void> _ensureFile(String path, String contents) async {
    final file = File(path);
    if (!await file.exists()) {
      await file.writeAsString(contents, flush: true);
    }
  }
}
