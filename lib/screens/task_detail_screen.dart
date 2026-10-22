import 'package:flutter/material.dart';
import '../models/task.dart';
import 'add_task_sheet.dart';

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
    final result = await AddTaskSheet.show(
      context,
      taskToEdit: _currentTask,
      onSave: (updatedTask) {
        setState(() {
          _currentTask = updatedTask;
        });
        widget.onUpdate(updatedTask);
      },
    );
    if (result != null) {
      setState(() {
        _currentTask = result;
      });
      widget.onUpdate(result);
    }
  }

  void _confirmDelete() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Тапсырманы жою',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: const Text(
          'Бұл тапсырманы шынымен жойғыңыз келе ме?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Болдырмау', style: TextStyle(color: Color(0xFF64748B))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  String _formatFullDate(DateTime dt) {
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
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year} · $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final completedSubtasks =
        _currentTask.subtasks.where((s) => s.isDone).length;
    final totalSubtasks = _currentTask.subtasks.length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Тапсырма',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_horiz_rounded,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (value) {
              if (value == 'edit') {
                _editTask();
              } else if (value == 'delete') {
                _confirmDelete();
              } else if (value == 'toggle') {
                final updated = _currentTask.copyWith(isCompleted: !_currentTask.isCompleted);
                setState(() => _currentTask = updated);
                widget.onUpdate(updated);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle',
                child: Row(
                  children: [
                    Icon(
                      _currentTask.isCompleted ? Icons.undo_rounded : Icons.check_circle_outline_rounded,
                      size: 18,
                      color: const Color(0xFF4F46E5),
                    ),
                    const SizedBox(width: 10),
                    Text(_currentTask.isCompleted ? 'Орындалмаған деп белгілеу' : 'Орындалды деп белгілеу'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: const [
                    Icon(Icons.edit_outlined, size: 18, color: Color(0xFF4F46E5)),
                    SizedBox(width: 10),
                    Text('Өңдеу'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: const [
                    Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                    SizedBox(width: 10),
                    Text('Жою', style: TextStyle(color: Color(0xFFEF4444))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    _currentTask.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tags Row
                  Row(
                    children: [
                      // Subject badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _currentTask.subject,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Priority badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _currentTask.priority.backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _currentTask.priority.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _currentTask.priority.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Deadline Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.calendar_month_outlined,
                            color: Color(0xFF4F46E5),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Тапсыру мерзімі',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatFullDate(_currentTask.deadline),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description Card
                  if (_currentTask.description.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Сипаттама',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currentTask.description,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Subtasks Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ішкі тапсырмалар',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            if (totalSubtasks > 0)
                              Text(
                                '$completedSubtasks/$totalSubtasks',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4F46E5),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_currentTask.subtasks.isEmpty)
                          Text(
                            'Ішкі тапсырмалар қосылмаған',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                            ),
                          )
                        else
                          ...List.generate(_currentTask.subtasks.length, (index) {
                            final sub = _currentTask.subtasks[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: InkWell(
                                onTap: () => _toggleSubtask(index),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 180),
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: sub.isDone
                                              ? const Color(0xFF10B981)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: sub.isDone
                                                ? const Color(0xFF10B981)
                                                : (isDark
                                                    ? const Color(0xFF64748B)
                                                    : const Color(0xFFCBD5E1)),
                                            width: 1.8,
                                          ),
                                        ),
                                        child: sub.isDone
                                            ? const Icon(
                                                Icons.check_rounded,
                                                size: 15,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          sub.title,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: sub.isDone
                                                ? (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))
                                                : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                            decoration: sub.isDone ? TextDecoration.lineThrough : null,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Bottom Action Buttons
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                ),
              ),
            ),
            child: Row(
              children: [
                // Edit button
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: _editTask,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text(
                        'Өңдеу',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Delete button
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: _confirmDelete,
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                      label: const Text(
                        'Жою',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFEF2F2),
                        foregroundColor: const Color(0xFFEF4444),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
