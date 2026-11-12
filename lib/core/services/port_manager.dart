import 'dart:io';

class PortManager {
  const PortManager();

  Future<bool> isAvailable(int port) async {
    try {
      final socket = await ServerSocket.bind(
        InternetAddress.loopbackIPv4,
        port,
      );
      await socket.close();
      return true;
    } on SocketException {
      return false;
    }
  }

  Future<int> findAvailable({int start = 8080, int end = 65535}) async {
    for (var port = start; port <= end; port++) {
      if (await isAvailable(port)) return port;
    }
    throw StateError('No available port found');
  }
}
