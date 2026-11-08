import 'package:flutter/material.dart';
import '../widgets/error_state_view.dart';

class ErrorScreen extends StatelessWidget {
  final ErrorType type;
  final String? title;
  final String? message;
  final VoidCallback? onRetry;
  final String? retryButtonText;

  const ErrorScreen({
    super.key,
    this.type = ErrorType.noInternet,
    this.title,
    this.message,
    this.onRetry,
    this.retryButtonText,
  });

  static Future<void> showNotFound(
    BuildContext context, {
    String? message,
    VoidCallback? onBack,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => ErrorScreen(
          type: ErrorType.notFound,
          message: message,
          onRetry: onBack ?? () => Navigator.of(ctx).pop(),
          retryButtonText: 'Артқа қайту',
        ),
      ),
    );
  }

  static Future<void> showDisconnect(
    BuildContext context, {
    String? message,
    VoidCallback? onRetry,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => ErrorScreen(
          type: ErrorType.noInternet,
          message: message,
          onRetry: onRetry ?? () => Navigator.of(ctx).pop(),
          retryButtonText: 'Қайта қосылу',
        ),
      ),
    );
  }

  static Future<void> showServerError(
    BuildContext context, {
    String? message,
    VoidCallback? onRetry,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => ErrorScreen(
          type: ErrorType.serverError,
          message: message,
          onRetry: onRetry ?? () => Navigator.of(ctx).pop(),
          retryButtonText: 'Қайта көру',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: ErrorStateView(
          type: type,
          title: title,
          message: message,
          onRetry: onRetry ?? () => Navigator.of(context).maybePop(),
          retryButtonText: retryButtonText,
        ),
      ),
    );
  }
}

