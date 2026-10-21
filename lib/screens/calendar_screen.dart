import 'package:flutter/material.dart';
import '../models/task.dart';
import 'task_detail_screen.dart';
import 'add_task_screen.dart';

class CalendarScreen extends StatefulWidget {
  final List<Task> tasks;
  final Function(Task task) onToggleTask;
  final Function(Task task) onUpdateTask;
  final Function(String id) onDeleteTask;
  final Function(Task task) onAddTask;

  const CalendarScreen({
    super.key,
    required this.tasks,
    required this.onToggleTask,
    required this.onUpdateTask,
    required this.onDeleteTask,
    required this.onAddTask,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<Task> _getTasksForSelectedDate() {
    return widget.tasks.where((t) => _isSameDay(t.deadline, _selectedDate)).toList();
  }

  bool _hasTasksOnDate(DateTime date) {
    return widget.tasks.any((t) => _isSameDay(t.deadline, date));
  }

  String _getMonthName(int month) {
    const months = [
      'Қаңтар',
      'Ақпан',
      'Наурыз',
      'Сәуір',
      'Мамыр',
      'Маусым',
      'Шілде',
      'Тамыз',
      'Қыркүйек',
      'Қазан',
      'Қараша',
      'Желтоқсан'
    ];
    return months[month - 1];
  }

  String _getWeekDayShort(int weekday) {
    const days = ['Дс', 'Сс', 'Ср', 'Бс', 'Жм', 'Сн', 'Жк'];
    return days[weekday - 1];
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  List<DateTime> _generateWeekDays() {
    // Generate 14 days around the selected date
    final start = _selectedDate.subtract(const Duration(days: 3));
    return List.generate(14, (i) => start.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dayTasks = _getTasksForSelectedDate();
    final weekDays = _generateWeekDays();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Күнтізбе мен жоспар',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task_rounded),
            tooltip: 'Тапсырма қосу',
            onPressed: () async {
              final newTask = await Navigator.of(context).push<Task>(
                MaterialPageRoute(builder: (context) => const AddTaskScreen()),
              );
              if (newTask != null) {
                widget.onAddTask(newTask);
              }
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Header with navigation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, color: colorScheme.primary, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      '${_getMonthName(_selectedDate.month)} ${_selectedDate.year}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    final now = DateTime.now();
                    setState(() {
                      _selectedDate = DateTime(now.year, now.month, now.day);
                    });
                  },
                  icon: const Icon(Icons.today_rounded, size: 16),
                  label: const Text('Бүгін'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),

          // Horizontal Date Picker Strip
          SizedBox(
            height: 94,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: weekDays.length,
              separatorBuilder: (ctx, i) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final date = weekDays[index];
                final isSelected = _isSameDay(date, _selectedDate);
                final isToday = _isSameDay(date, DateTime.now());
                final hasTasks = _hasTasksOnDate(date);

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 58,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary
                          : isToday
                              ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : isToday
                                ? colorScheme.primary
                                : colorScheme.outlineVariant.withValues(alpha: 0.3),
                        width: isToday && !isSelected ? 1.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: colorScheme.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          _getWeekDayShort(date.weekday),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? colorScheme.onPrimary
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                          ),
                        ),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasTasks
                                ? (isSelected ? colorScheme.onPrimary : colorScheme.primary)
                                : Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Day summary chip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_selectedDate.day} ${_getMonthName(_selectedDate.month).toLowerCase()}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: dayTasks.isEmpty
                        ? colorScheme.surfaceContainerHighest
                        : colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    dayTasks.isEmpty
                        ? 'Тапсырма жоқ'
                        : '${dayTasks.length} тапсырма',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: dayTasks.isEmpty
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Tasks List for Selected Day
          Expanded(
            child: dayTasks.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.event_available_rounded,
                                size: 56,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Бұл күнге тапсырмалар жоқ!',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Тынығуға немесе басқа жұмыстарға уақыт бөлуге тамаша мүмкіндік ✨',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 20),
                            FilledButton.tonalIcon(
                              onPressed: () async {
                                final newTask = await Navigator.of(context).push<Task>(
                                  MaterialPageRoute(
                                    builder: (context) => const AddTaskScreen(),
                                  ),
                                );
                                if (newTask != null) {
                                  widget.onAddTask(newTask);
                                }
                              },
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Тапсырма қосу'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: dayTasks.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final task = dayTasks[index];
                      return InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => TaskDetailScreen(
                                task: task,
                                onUpdate: widget.onUpdateTask,
                                onDelete: widget.onDeleteTask,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Checkbox
                              IconButton(
                                icon: Icon(
                                  task.isCompleted
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  color: task.isCompleted
                                      ? const Color(0xFF10B981)
                                      : colorScheme.outline,
                                  size: 26,
                                ),
                                onPressed: () => widget.onToggleTask(task),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          task.subject,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: task.priority.color.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            task.priority.label,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: task.priority.color,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      task.title,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        decoration:
                                            task.isCompleted ? TextDecoration.lineThrough : null,
                                        color: task.isCompleted
                                            ? colorScheme.onSurfaceVariant
                                            : colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 14,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatTime(task.deadline),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        if (task.subtasks.isNotEmpty) ...[
                                          const SizedBox(width: 12),
                                          Icon(
                                            Icons.checklist_rounded,
                                            size: 14,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${task.subtasks.where((s) => s.isDone).length}/${task.subtasks.length}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
