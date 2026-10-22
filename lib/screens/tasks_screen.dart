import 'package:flutter/material.dart';
import '../models/task.dart';
import '../widgets/task_card.dart';
import 'task_detail_screen.dart';
import 'add_task_sheet.dart';

class TasksScreen extends StatefulWidget {
  final List<Task> tasks;
  final Function(Task task) onToggleTask;
  final Function(Task task) onAddTask;
  final Function(Task task) onUpdateTask;
  final Function(String taskId) onDeleteTask;

  const TasksScreen({
    super.key,
    required this.tasks,
    required this.onToggleTask,
    required this.onAddTask,
    required this.onUpdateTask,
    required this.onDeleteTask,
  });

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedSubjectFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSubjectFilterSheet() {
    final subjects = ['Барлық пәндер', ...Task.availableSubjects];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text(
                'Пән бойынша сүзу',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ...subjects.map((sub) {
              final isAll = sub == 'Барлық пәндер';
              final isSelected = isAll
                  ? _selectedSubjectFilter == null
                  : _selectedSubjectFilter == sub;
              return ListTile(
                title: Text(
                  sub,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? const Color(0xFF4F46E5) : null,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_rounded, color: Color(0xFF4F46E5))
                    : null,
                onTap: () {
                  setState(() {
                    _selectedSubjectFilter = isAll ? null : sub;
                  });
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredTasks = widget.tasks.where((t) {
      if (_selectedSubjectFilter != null && t.subject != _selectedSubjectFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesTitle = t.title.toLowerCase().contains(q);
        final matchesSubject = t.subject.toLowerCase().contains(q);
        if (!matchesTitle && !matchesSubject) return false;
      }
      return true;
    }).toList();

    final inProgressTasks =
        filteredTasks.where((t) => !t.isCompleted).toList();
    final completedTasks =
        filteredTasks.where((t) => t.isCompleted).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
          children: [
            // Top Header: Title and + button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Тапсырмалар',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    AddTaskSheet.show(
                      context,
                      onSave: widget.onAddTask,
                    );
                  },
                  icon: const Icon(
                    Icons.add_rounded,
                    color: Color(0xFF4F46E5),
                    size: 26,
                  ),
                  tooltip: 'Тапсырма қосу',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Search Bar
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim();
                  });
                },
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: 'Тапсырманы іздеу',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Count and Filter row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredTasks.length} тапсырма',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                InkWell(
                  onTap: _showSubjectFilterSheet,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.tune_rounded,
                          size: 15,
                          color: Color(0xFF4F46E5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _selectedSubjectFilter ?? 'Пән бойынша',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: Color(0xFF4F46E5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Section 1: In Progress (Орындалуда)
            if (inProgressTasks.isNotEmpty) ...[
              Row(
                children: [
                  Text(
                    'Орындалуда',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${inProgressTasks.length}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...inProgressTasks.map(
                (task) => TaskCard(
                  task: task,
                  onToggle: () => widget.onToggleTask(task),
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
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Section 2: Completed (Аяқталды)
            if (completedTasks.isNotEmpty) ...[
              Row(
                children: [
                  Text(
                    'Аяқталды',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${completedTasks.length}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...completedTasks.map(
                (task) => TaskCard(
                  task: task,
                  onToggle: () => widget.onToggleTask(task),
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
                ),
              ),
            ],

            if (filteredTasks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Тапсырмалар табылмады',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
