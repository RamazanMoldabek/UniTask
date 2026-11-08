import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/task.dart';
import '../utils/app_logger.dart';

enum SocketStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

class WebSocketService {
  static const String defaultEndpoint = 'wss://echo.websocket.events';
  static final WebSocketService instance = WebSocketService._internal();

  factory WebSocketService() => instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;

  SocketStatus _status = SocketStatus.disconnected;
  SocketStatus get status => _status;

  final _statusController = StreamController<SocketStatus>.broadcast();
  Stream<SocketStatus> get statusStream => _statusController.stream;

  final _taskEventsController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get taskEventsStream =>
      _taskEventsController.stream;

  bool _isManualDisconnect = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectIntervalSeconds = 15;

  void connect({String endpoint = defaultEndpoint}) {
    _isManualDisconnect = false;
    _reconnectTimer?.cancel();

    _updateStatus(
        _reconnectAttempts > 0 ? SocketStatus.reconnecting : SocketStatus.connecting);
    AppLogger.socket('Connecting to $endpoint (Attempt ${_reconnectAttempts + 1})');

    try {
      final uri = Uri.parse(endpoint);
      _channel = WebSocketChannel.connect(uri);

      _subscription = _channel!.stream.listen(
        (dynamic rawMessage) {
          if (_status != SocketStatus.connected) {
            _reconnectAttempts = 0;
            _updateStatus(SocketStatus.connected);
            AppLogger.socket('WebSocket connected successfully');
          }
          _handleIncomingMessage(rawMessage);
        },
        onError: (dynamic error) {
          AppLogger.error('WebSocket error', error: error);
          _handleDisconnect();
        },
        onDone: () {
          AppLogger.socket('WebSocket connection closed by host');
          _handleDisconnect();
        },
        cancelOnError: true,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create WebSocket channel',
          error: e, stackTrace: stackTrace);
      _handleDisconnect();
    }
  }

  void _handleIncomingMessage(dynamic rawMessage) {
    AppLogger.socket('Message received', data: rawMessage.toString());
    try {
      final decoded = jsonDecode(rawMessage.toString());
      if (decoded is Map<String, dynamic>) {
        _taskEventsController.add(decoded);
      }
    } catch (_) {
      // Ignored non-json messages (like raw text echo)
    }
  }

  void _handleDisconnect() {
    _cleanupChannel();
    if (_isManualDisconnect) {
      _updateStatus(SocketStatus.disconnected);
      return;
    }

    _updateStatus(SocketStatus.disconnected);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectAttempts++;
    final delaySeconds =
        (_reconnectAttempts * 2).clamp(2, _maxReconnectIntervalSeconds);

    _updateStatus(SocketStatus.reconnecting);
    AppLogger.socket(
        'Scheduling reconnect in $delaySeconds seconds (Attempt $_reconnectAttempts)');

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (!_isManualDisconnect) {
        connect();
      }
    });
  }

  void broadcastTaskAction(String action, Task task) {
    final payload = {
      'type': 'task_event',
      'action': action, // 'create', 'update', 'delete', 'toggle'
      'task': task.toJson(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    final jsonString = jsonEncode(payload);

    if (_status == SocketStatus.connected && _channel != null) {
      try {
        _channel!.sink.add(jsonString);
        AppLogger.socket('Sent broadcast', data: jsonString);
      } catch (e) {
        AppLogger.error('Failed to send WebSocket message', error: e);
      }
    } else {
      AppLogger.warning(
          'Socket not connected. Event queued/local only: $action task #${task.id}');
    }

    // Local loopback so listeners update instantly regardless of server echo speed
    _taskEventsController.add(payload);
  }

  void disconnect() {
    _isManualDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;
    _cleanupChannel();
    _updateStatus(SocketStatus.disconnected);
    AppLogger.socket('WebSocket manually disconnected');
  }

  void _cleanupChannel() {
    _subscription?.cancel();
    _subscription = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  void _updateStatus(SocketStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      _statusController.add(_status);
    }
  }

  void dispose() {
    disconnect();
    _statusController.close();
    _taskEventsController.close();
  }
}

