import '../models/project.dart';

abstract class RuntimeEngine {
  String get name;

  bool get isRunning;

  int? get port;

  String? get url;

  Stream<String> get logs;

  Future<void> start({required Project project, int port = 0});

  Future<void> stop();

  void dispose();
}
