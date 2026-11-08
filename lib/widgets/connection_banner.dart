import 'package:flutter/material.dart';
import '../services/websocket_service.dart';

class ConnectionBanner extends StatefulWidget {
  const ConnectionBanner({super.key});

  @override
  State<ConnectionBanner> createState() => _ConnectionBannerState();
}

class _ConnectionBannerState extends State<ConnectionBanner> {
  SocketStatus _status = WebSocketService.instance.status;
  bool _showSuccessTemporarily = false;

  @override
  void initState() {
    super.initState();
    WebSocketService.instance.statusStream.listen((status) {
      if (!mounted) return;
      if (status == SocketStatus.connected &&
          _status != SocketStatus.connected) {
        setState(() {
          _status = status;
          _showSuccessTemporarily = true;
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showSuccessTemporarily = false;
            });
          }
        });
      } else {
        setState(() {
          _status = status;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_status == SocketStatus.connected && !_showSuccessTemporarily) {
      return const SizedBox.shrink();
    }

    Color bgColor;
    Color textColor;
    IconData icon;
    String message;
    Widget? actionWidget;

    switch (_status) {
      case SocketStatus.connected:
        bgColor = const Color(0xFF10B981); // Emerald
        textColor = Colors.white;
        icon = Icons.check_circle_rounded;
        message = 'Байланыс орнатылды (Realtime қосулы)';
        break;
      case SocketStatus.connecting:
      case SocketStatus.reconnecting:
        bgColor = const Color(0xFFD97706); // Amber
        textColor = Colors.white;
        icon = Icons.sync_rounded;
        message = 'Желі жоқ / Қайта қосылуда...';
        actionWidget = const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );
        break;
      case SocketStatus.disconnected:
        bgColor = const Color(0xFFEF4444); // Red
        textColor = Colors.white;
        icon = Icons.wifi_off_rounded;
        message = 'Офлайн режимі / Желі жоқ';
        actionWidget = GestureDetector(
          onTap: () => WebSocketService.instance.connect(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Қайталау',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        );
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: bgColor,
      child: SafeArea(
        bottom: false,
        top: false,
        child: Row(
          children: [
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (actionWidget != null) ...[actionWidget],
          ],
        ),
      ),
    );
  }
}
