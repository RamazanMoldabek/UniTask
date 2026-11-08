import 'dart:developer' as developer;

class AppLogger {
  static const String _name = 'UniTask';

  static void info(String message, {String? tag}) {
    developer.log(
      message,
      name: tag != null ? '$_name:$tag' : _name,
      level: 800,
    );
  }

  static void warning(String message, {String? tag, Object? error}) {
    developer.log(
      message,
      name: tag != null ? '$_name:$tag' : _name,
      level: 900,
      error: error,
    );
  }

  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: tag != null ? '$_name:$tag' : _name,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void network(String method, String url, {int? statusCode, String? body}) {
    final statusInfo = statusCode != null ? ' [$statusCode]' : '';
    final bodyInfo = body != null ? ' - Body: $body' : '';
    developer.log(
      '$method $url$statusInfo$bodyInfo',
      name: '$_name:Network',
      level: 800,
    );
  }

  static void socket(String event, {String? data}) {
    final dataInfo = data != null ? ': $data' : '';
    developer.log(
      '$event$dataInfo',
      name: '$_name:WebSocket',
      level: 800,
    );
  }
}

