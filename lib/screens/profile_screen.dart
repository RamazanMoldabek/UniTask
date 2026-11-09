import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/locale_service.dart';
import '../services/user_service.dart';

class ProfileScreen extends StatelessWidget {
  final List<Task> tasks;
  final bool isDarkMode;
  final Function(bool isDark) onToggleTheme;
  final VoidCallback onLogout;

  const ProfileScreen({
    super.key,
    required this.tasks,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.onLogout,
  });

  void _showLogoutDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          LocaleService.instance.t('logout_title'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(LocaleService.instance.t('logout_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              LocaleService.instance.t('cancel'),
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onLogout();
            },
            child: Text(LocaleService.instance.t('logout')),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final currentLang = LocaleService.instance.currentLanguage;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          LocaleService.instance.t('select_language'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppLanguage.values.map((lang) {
            final isSelected = lang == currentLang;
            return ListTile(
              title: Text(lang.label),
              trailing: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Color(0xFF4F46E5),
                    )
                  : null,
              onTap: () {
                LocaleService.instance.setLanguage(lang);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showRemindersDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          LocaleService.instance.t('reminders'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(LocaleService.instance.t('reminders_desc')),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text(LocaleService.instance.t('ok')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: Listenable.merge([LocaleService.instance, UserService.instance]),
      builder: (context, _) {
        final loc = LocaleService.instance;
        final userService = UserService.instance;
        final user = userService.currentUser;
        final completedCount = tasks.where((t) => t.isCompleted).length;

        return Scaffold(
          backgroundColor: isDark
              ? const Color(0xFF0F172A)
              : const Color(0xFFF8FAFC),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
              children: [
                // Title
                Text(
                  loc.t('profile_title'),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 20),

                // Profile Card (Avatar + Info)
                Row(
                  children: [
                    // Avatar circle with dynamic initials
                    Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4F46E5),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          userService.initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            user.university.isNotEmpty
                                ? user.university
                                : loc.t('major_course'),
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            user.email.isNotEmpty
                                ? '${loc.t('student')} · ${user.email}'
                                : loc.t('student'),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4F46E5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Stats row (2 side-by-side cards)
                Row(
                  children: [
                    // Card 1
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$completedCount',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                                const Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: Color(0xFF4F46E5),
                                  size: 20,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              loc.t('tasks_completed_stat'),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Card 2
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '95%',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                                const Icon(
                                  Icons.timer_outlined,
                                  color: Color(0xFF4F46E5),
                                  size: 20,
                                ),
                              ],
                            ),
                        const SizedBox(height: 6),
                        Text(
                          loc.t('on_time_stat'),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Settings header
            Text(
              loc.t('settings'),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),

            // Settings container
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  // Dark mode item
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.dark_mode_outlined,
                          size: 22,
                          color: isDark
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF475569),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            loc.t('dark_mode'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Switch(
                          value: isDarkMode,
                          onChanged: onToggleTheme,
                          activeThumbColor: const Color(0xFF4F46E5),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFF1F5F9),
                  ),
                  // Language item
                  InkWell(
                    onTap: () => _showLanguageDialog(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.translate_rounded,
                            size: 22,
                            color: isDark
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFF475569),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              loc.t('language'),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          Text(
                            loc.currentLanguage.label,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: isDark
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFF1F5F9),
                  ),
                  // Reminders item
                  InkWell(
                    onTap: () => _showRemindersDialog(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 22,
                            color: isDark
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFF475569),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              loc.t('reminders'),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          Text(
                            loc.t('enabled'),
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: isDark
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: () => _showLogoutDialog(context),
                icon: Icon(
                  Icons.logout_rounded,
                  size: 20,
                  color: isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444),
                ),
                label: Text(
                  loc.t('logout'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444),
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: isDark
                      ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                      : const Color(0xFFFEF2F2),
                  foregroundColor: isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444),
                  elevation: 0,
                  side: BorderSide(
                    color: isDark
                        ? const Color(0xFFEF4444).withValues(alpha: 0.28)
                        : const Color(0xFFFECACA),
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // App Version Footer
            Center(
              child: Text(
                loc.t('app_version'),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }
}
