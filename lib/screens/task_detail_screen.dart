import 'package:flutter/material.dart';
import '../models/task.dart';
import 'add_task_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;
  final Function(Task updatedTask) onUpdate;
  final Function(String taskId) onDelete;

  const TaskDetailScreen({
    super.key,
    required this.task,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late Task _currentTask;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task;
  }

  void _toggleTaskStatus() {
    final updated = _currentTask.copyWith(isCompleted: !_currentTask.isCompleted);
    setState(() {
      _currentTask = updated;
    });
    widget.onUpdate(updated);
  }

  void _toggleSubtask(int index) {
    final newSubtasks = _currentTask.subtasks.map((s) => s.copyWith()).toList();
    newSubtasks[index].isDone = !newSubtasks[index].isDone;

    final updated = _currentTask.copyWith(subtasks: newSubtasks);
    setState(() {
      _currentTask = updated;
    });
    widget.onUpdate(updated);
  }

  Future<void> _editTask() async {
    final result = await Navigator.of(context).push<Task>(
      MaterialPageRoute(
        builder: (context) => AddTaskScreen(taskToEdit: _currentTask),
      ),
    );

    if (result != null) {
      setState(() {
        _currentTask = result;
      });
      widget.onUpdate(result);
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Тапсырманы жою'),
        content: const Text('Бұл тапсырманы шынымен жойғыңыз келе ме? Бұл әрекетті қайтару мүмкін емес.'),
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
              widget.onDelete(_currentTask.id);
              Navigator.of(context).pop();
            },
            child: const Text('Жою'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'қаңтар',
      'ақпан',
      'наурыз',
      'сәуір',
      'мамыр',
      'маусым',
      'шілде',
      'тамыз',
      'қыркүйек',
      'қазан',
      'қараша',
      'желтоқсан'
    ];
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, сағат $hour:$min';
  }

  String _getRemainingTime(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (_currentTask.isCompleted) {
      return 'Орындалды';
    }
    if (difference.isNegative) {
      return 'Мерзімі өтіп кетті';
    }
    if (difference.inDays > 0) {
      return '${difference.inDays} күн ${difference.inHours % 24} сағат қалды';
    }
    if (difference.inHours > 0) {
      return '${difference.inHours} сағат ${difference.inMinutes % 60} мин қалды';
    }
    return '${difference.inMinutes} минут қалды';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final subtasksDoneCount = _currentTask.subtasks.where((s) => s.isDone).length;
    final totalSubtasks = _currentTask.subtasks.length;
    final subtaskProgress = totalSubtasks > 0 ? (subtasksDoneCount / totalSubtasks) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Тапсырма мәліметі',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Өңдеу',
            onPressed: _editTask,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Жою',
            color: colorScheme.error,
            onPressed: _confirmDelete,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _editTask,
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Өңдеу'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _toggleTaskStatus,
                  icon: Icon(
                    _currentTask.isCompleted
                        ? Icons.replay_rounded
                        : Icons.check_circle_rounded,
                  ),
                  label: Text(
                    _currentTask.isCompleted ? 'Қайта бастау' : 'Тапсырманы аяқтау',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _currentTask.isCompleted
                        ? colorScheme.secondary
                        : colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and Priority Badges
            Row(
              children: [
                // Completion Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _currentTask.isCompleted
                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                        : colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _currentTask.isCompleted
                            ? Icons.check_circle_rounded
                            : Icons.pending_rounded,
                        size: 16,
                        color: _currentTask.isCompleted
                            ? const Color(0xFF10B981)
                            : colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _currentTask.isCompleted ? 'Орындалды' : 'Орындалуда',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _currentTask.isCompleted
                              ? const Color(0xFF10B981)
                              : colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Priority Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _currentTask.priority.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _currentTask.priority.icon,
                        size: 16,
                        color: _currentTask.priority.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _currentTask.priority.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _currentTask.priority.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Subject label
            Row(
              children: [
                Icon(Icons.school_outlined, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  _currentTask.subject,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Main Title
            Text(
              _currentTask.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                decoration: _currentTask.isCompleted ? TextDecoration.lineThrough : null,
                color: _currentTask.isCompleted
                    ? colorScheme.onSurfaceVariant.withValues(alpha: 0.7)
                    : colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),

            // Deadline Information Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.access_time_filled_rounded, color: colorScheme.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Мерзімі (Дедлайн)',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(_currentTask.deadline),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getRemainingTime(_currentTask.deadline),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _currentTask.deadline.isBefore(DateTime.now()) &&
                                    !_currentTask.isCompleted
                                ? colorScheme.error
                                : colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Description Section
            Text(
              'Сипаттамасы',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                _currentTask.description.isNotEmpty
                    ? _currentTask.description
                    : 'Қосымша жазбалар енгізілмеген.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: _currentTask.description.isNotEmpty
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Checklist / Subtasks Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Ішкі тапсырмалар (Чек-лист)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$subtasksDoneCount / $totalSubtasks',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: subtaskProgress,
                minHeight: 8,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  subtaskProgress == 1.0 ? const Color(0xFF10B981) : colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 14),

            if (_currentTask.subtasks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Ішкі қадамдар қосылмаған',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _currentTask.subtasks.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final subtask = _currentTask.subtasks[index];
                  return InkWell(
                    onTap: () => _toggleSubtask(index),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: subtask.isDone
                            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                            : colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            subtask.isDone
                                ? Icons.check_box_rounded
                                : Icons.check_box_outline_blank_rounded,
                            color: subtask.isDone ? colorScheme.primary : colorScheme.outline,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              subtask.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                decoration:
                                    subtask.isDone ? TextDecoration.lineThrough : null,
                                color: subtask.isDone
                                    ? colorScheme.onSurfaceVariant
                                    : colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
