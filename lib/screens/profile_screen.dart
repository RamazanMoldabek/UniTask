import 'package:flutter/material.dart';
import '../models/task.dart';

class ProfileScreen extends StatelessWidget {
  final List<Task> tasks;
  final bool isDarkMode;
  final Function(bool isDark) onToggleTheme;

  const ProfileScreen({
    super.key,
    required this.tasks,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Жүйеден шығу'),
        content: const Text('Шынымен жүйеден шыққыңыз келе ме?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Болдырмау'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Жүйеден сәтті шықтыңыз'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Шығу'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('UniTask туралы'),
        content: const Text(
          'UniTask — студенттерге арналған заманауи оқу жоспарлаушысы. Дедлайндарды қадағалап, тапсырмаларды уақытылы орындауға арналған көмекші құрал.\n\nНұсқасы: 1.0.0 (Material 3)',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Түсінікті'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final totalTasks = tasks.length;
    final completedTasks = tasks.where((t) => t.isCompleted).length;
    final urgentTasks = tasks.where((t) => !t.isCompleted && t.priority == TaskPriority.high).length;
    final completionRate = totalTasks > 0 ? ((completedTasks / totalTasks) * 100).toInt() : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Профиль',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'Қосымша туралы',
            onPressed: () => _showAboutDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          children: [
            // Student Profile Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary,
                              const Color(0xFF8B5CF6),
                            ],
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 44,
                          backgroundColor: colorScheme.surface,
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
                            child: Text(
                              'Р',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: colorScheme.surface, width: 2),
                          ),
                          child: const Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Рамазан Серік',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ақпараттық жүйелер • СДУ Университеті',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Студент ID: 210103045 • 3-курс',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Statistics Header
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Оқу үлгерімі мен статистика',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Statistics Grid (2x2)
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Тапсырмалар',
                    value: '$totalTasks',
                    subtitle: 'Барлығы енгізілген',
                    icon: Icons.assignment_rounded,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'Орындалған',
                    value: '$completedTasks',
                    subtitle: '$completionRate% орындалды',
                    icon: Icons.task_alt_rounded,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: _MetricCard(
                    title: 'Орташа GPA',
                    value: '3.85',
                    subtitle: 'Үздік нәтиже (A-)',
                    icon: Icons.grade_rounded,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'Шұғыл дедлайн',
                    value: '$urgentTasks',
                    subtitle: 'Бақылаудағы жұмыс',
                    icon: Icons.priority_high_rounded,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Settings Section
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Баптаулар мен қызметтер',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),

            Material(
              color: colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  // Theme switch
                  SwitchListTile(
                    title: const Text('Қараңғы тақырып (Dark Mode)',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(
                      isDarkMode ? 'Қараңғы режим қосулы' : 'Ашық режим қосулы',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        color: colorScheme.primary,
                      ),
                    ),
                    value: isDarkMode,
                    onChanged: (val) => onToggleTheme(val),
                  ),
                  Divider(height: 1, indent: 64, endIndent: 20, color: colorScheme.outlineVariant.withValues(alpha: 0.2)),

                  // Notifications
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.notifications_active_rounded, color: Color(0xFFF59E0B)),
                    ),
                    title: const Text('Дедлайн ескертулері',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text('Дедлайнға 2 сағат қалғанда хабарлау',
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ескертулер белсендірілген!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  Divider(height: 1, indent: 64, endIndent: 20, color: colorScheme.outlineVariant.withValues(alpha: 0.2)),

                  // Language
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.language_rounded, color: Color(0xFF10B981)),
                    ),
                    title: const Text('Интерфейс тілі',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text('Қазақша',
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {},
                  ),
                  Divider(height: 1, indent: 64, endIndent: 20, color: colorScheme.outlineVariant.withValues(alpha: 0.2)),

                  // University Portal Sync
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.sync_rounded, color: colorScheme.secondary),
                    ),
                    title: const Text('Студент порталы (Moodle/Platonus)',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text('Соңғы синхрондау: бүгін, 12:45',
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Порталмен деректер толық жаңартылды!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showLogoutDialog(context),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Жүйеден шығу'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  side: BorderSide(color: colorScheme.error.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
