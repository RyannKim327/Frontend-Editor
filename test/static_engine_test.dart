import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_editor/core/engines/static_engine.dart';
import 'package:frontend_editor/core/models/project.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;
  late StaticEngine engine;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('static_engine_test');
    await File(p.join(tempDir.path, 'index.html'))
        .writeAsString('<h1>Hello</h1>');
    await File(p.join(tempDir.path, 'styles.css'))
        .writeAsString('body { color: red; }');
    engine = StaticEngine();
  });

  tearDown(() async {
    await engine.stop();
    engine.dispose();
    await tempDir.delete(recursive: true);
  });

  Project project() =>
      Project(id: 'test', name: 'Test', rootPath: tempDir.path);

  test('serves project files over loopback', () async {
    await engine.start(project: project());

    expect(engine.isRunning, isTrue);
    expect(engine.url, startsWith('http://127.0.0.1:'));

    final client = HttpClient();
    addTearDown(client.close);

    final request = await client.getUrl(Uri.parse(engine.url!));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    expect(response.statusCode, 200);
    expect(body, contains('Hello'));
    expect(response.headers.value('cache-control'), contains('no-store'));
  });

  test('serves additional static assets', () async {
    await engine.start(project: project());

    final client = HttpClient();
    addTearDown(client.close);

    final request = await client.getUrl(Uri.parse('${engine.url}styles.css'));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    expect(response.statusCode, 200);
    expect(body, contains('color: red'));
  });

  test('stop releases the port', () async {
    await engine.start(project: project());
    final port = engine.port!;

    await engine.stop();

    expect(engine.isRunning, isFalse);
    expect(engine.url, isNull);

    final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, port);
    await socket.close();
  });
}
