import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';

import '../models/project.dart';
import 'runtime_engine.dart';

class StaticEngine implements RuntimeEngine {
  final StreamController<String> _logs = StreamController<String>.broadcast();

  HttpServer? _server;

  @override
  String get name => 'Static (Shelf)';

  @override
  bool get isRunning => _server != null;

  @override
  int? get port => _server?.port;

  @override
  String? get url {
    final server = _server;
    if (server == null) return null;
    return 'http://127.0.0.1:${server.port}/';
  }

  @override
  Stream<String> get logs => _logs.stream;

  @override
  Future<void> start({required Project project, int port = 0}) async {
    await stop();

    final staticHandler = createStaticHandler(
      project.rootPath,
      defaultDocument: project.entryFile,
    );

    final handler = const Pipeline()
        .addMiddleware(_logRequests())
        .addMiddleware(_noCache())
        .addHandler(staticHandler);

    final server = await shelf_io.serve(
      handler,
      InternetAddress.loopbackIPv4,
      port,
    );
    server.autoCompress = true;
    _server = server;
    _log('Serving ${project.rootPath} at $url');
  }

  @override
  Future<void> stop() async {
    final server = _server;
    if (server == null) return;
    _server = null;
    await server.close(force: true);
    _log('Server stopped');
  }

  @override
  void dispose() {
    unawaited(stop());
    unawaited(_logs.close());
  }

  Middleware _noCache() {
    return (innerHandler) {
      return (request) async {
        final response = await innerHandler(request);
        return response.change(
          headers: {
            ...response.headers,
            'cache-control': 'no-store, no-cache, must-revalidate',
            'pragma': 'no-cache',
            'expires': '0',
          },
        );
      };
    };
  }

  Middleware _logRequests() {
    return (innerHandler) {
      return (request) async {
        final response = await innerHandler(request);
        _log(
          '${request.method} /${request.url.path} -> ${response.statusCode}',
        );
        return response;
      };
    };
  }

  void _log(String message) {
    if (!_logs.isClosed) _logs.add(message);
  }
}
