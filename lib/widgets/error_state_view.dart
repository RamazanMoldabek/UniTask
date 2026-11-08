import 'package:flutter/material.dart';

enum ErrorType {
  noInternet,
  notFound,
  serverError,
}

class ErrorStateView extends StatelessWidget {
  final ErrorType type;
  final String? title;
  final String? message;
  final VoidCallback? onRetry;
  final String? retryButtonText;

  const ErrorStateView({
    super.key,
    this.type = ErrorType.noInternet,
    this.title,
    this.message,
    this.onRetry,
    this.retryButtonText,
  });

  factory ErrorStateView.noInternet({
    VoidCallback? onRetry,
    String? message,
  }) {
    return ErrorStateView(
      type: ErrorType.noInternet,
      title: 'Сервермен байланыс жоқ',
      message: message ?? 'Интернет байланысын тексеріп, қайталап көріңіз',
      onRetry: onRetry,
      retryButtonText: 'Қайталау',
    );
  }

  factory ErrorStateView.notFound({
    VoidCallback? onRetry,
    String? message,
  }) {
    return ErrorStateView(
      type: ErrorType.notFound,
      title: '404 - Бет немесе дерек табылмады',
      message: message ?? 'Сұралған ресурс немесе тапсырма серверде табылмады',
      onRetry: onRetry,
      retryButtonText: 'Басты бетке оралу',
    );
  }

  factory ErrorStateView.serverError({
    VoidCallback? onRetry,
    String? message,
  }) {
    return ErrorStateView(
      type: ErrorType.serverError,
      title: '500 - Сервер қатесі',
      message: message ?? 'Сервер жауап бере алмады. Кейінірек қайталап көріңіз',
      onRetry: onRetry,
      retryButtonText: 'Қайта көру',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    IconData iconData;
    Color iconColor;
    Color iconBgColor;
    String defaultTitle;
    String defaultMessage;
    String defaultButtonText;

    switch (type) {
      case ErrorType.notFound:
        iconData = Icons.search_off_rounded;
        iconColor = const Color(0xFF8B5CF6); // Purple
        iconBgColor = isDark
            ? const Color(0xFF8B5CF6).withValues(alpha: 0.15)
            : const Color(0xFFF3E8FF);
        defaultTitle = '404 - Бет табылмады';
        defaultMessage = 'Сұралған деректер жойылған немесе мекенжай қате';
        defaultButtonText = 'Басты бетке';
        break;
      case ErrorType.serverError:
        iconData = Icons.cloud_off_rounded;
        iconColor = const Color(0xFFF59E0B); // Amber
        iconBgColor = isDark
            ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
            : const Color(0xFFFEF3C7);
        defaultTitle = '500 - Сервер қатесі';
        defaultMessage = 'Серверде уақытша ақау. Біз оны жөндеп жатырмыз';
        defaultButtonText = 'Қайта көру';
        break;
      case ErrorType.noInternet:
        iconData = Icons.wifi_off_rounded;
        iconColor = const Color(0xFFEF4444); // Red
        iconBgColor = isDark
            ? const Color(0xFFEF4444).withValues(alpha: 0.15)
            : const Color(0xFFFEE2E2);
        defaultTitle = 'Сервермен байланыс жоқ';
        defaultMessage = 'Интернет байланысын тексеріп, қайталап көріңіз';
        defaultButtonText = 'Қайталау';
        break;
    }

    final effectiveTitle = title ?? defaultTitle;
    final effectiveMessage = message ?? defaultMessage;
    final effectiveButtonText = retryButtonText ?? defaultButtonText;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                size: 40,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              effectiveTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              effectiveMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  effectiveButtonText,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
