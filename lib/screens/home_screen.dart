import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/api_service.dart';
import '../widgets/task_card.dart';
import 'task_detail_screen.dart';
import 'add_task_sheet.dart';

class HomeScreen extends StatefulWidget {
  final List<Task>? tasks;
  final Function(Task task)? onToggleTask;
  final Function(Task task)? onAddTask;
  final Function(Task task)? onUpdateTask;
  final Function(dynamic taskId)? onDeleteTask;

  const HomeScreen({
    super.key,
    this.tasks,
    this.onToggleTask,
    this.onAddTask,
    this.onUpdateTask,
    this.onDeleteTask,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _filterOnlyUrgent = false;
  List<Task> _tasks = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tasks = await ApiService.instance.fetchTasks();
      if (mounted) {
        setState(() {
          _tasks = tasks;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Сервермен байланыс жоқ';
        });
      }
    }
  }

  Future<void> _handleToggle(Task task) async {
    final updatedTask = task.copyWith(isCompleted: !task.isCompleted);

    // Optimistic UI update
    setState(() {
      final idx = _tasks.indexWhere((t) => t.id == task.id);
      if (idx != -1) {
        _tasks[idx] = updatedTask;
      }
    });

    try {
      final savedTask = await ApiService.instance.updateTask(updatedTask);
      if (mounted) {
        setState(() {
          final idx = _tasks.indexWhere((t) => t.id == task.id);
          if (idx != -1) {
            _tasks[idx] = savedTask;
          }
        });
        widget.onToggleTask?.call(savedTask);
      }
    } catch (e) {
      // Revert upon network/server failure
      if (mounted) {
        setState(() {
          final idx = _tasks.indexWhere((t) => t.id == task.id);
          if (idx != -1) {
            _tasks[idx] = task;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Жаңарту қатесі: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleDelete(String taskId) async {
    final originalTasks = List<Task>.from(_tasks);
    setState(() {
      _tasks.removeWhere((t) => t.id == taskId);
    });

    try {
      await ApiService.instance.deleteTask(taskId);
      widget.onDeleteTask?.call(taskId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Тапсырма сәтті жойылды'),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _tasks = originalTasks;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Жою қатесі: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleUpdate(Task task) async {
    try {
      final updated = await ApiService.instance.updateTask(task);
      setState(() {
        final idx = _tasks.indexWhere((t) => t.id == task.id);
        if (idx != -1) {
          _tasks[idx] = updated;
        }
      });
      widget.onUpdateTask?.call(updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Жаңарту қатесі: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _getKazakhFormattedDate() {
    final now = DateTime.now();
    const weekdays = [
      'Дүйсенбі',
      'Сейсенбі',
      'Сәрсенбі',
      'Бейсенбі',
      'Жұма',
      'Сенбі',
      'Жексенбі'
    ];
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
    final weekday = weekdays[now.weekday - 1];
    final month = months[now.month - 1];
    return '$weekday, ${now.day} $month';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final totalTasks = _tasks.length;
    final completedTasksCount = _tasks.where((t) => t.isCompleted).length;
    final remainingCount = totalTasks - completedTasksCount;
    final progress =
        totalTasks > 0 ? (completedTasksCount / totalTasks).clamp(0.0, 1.0) : 0.0;

    final inProgressTasks = _tasks.where((t) {
      if (t.isCompleted) return false;
      if (_filterOnlyUrgent) {
        return t.priority == 'Жоғары';
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await AddTaskSheet.show(
            context,
            onSave: (createdTask) async {
              setState(() {
                _tasks.insert(0, createdTask);
              });
              widget.onAddTask?.call(createdTask);
            },
          );
        },
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadTasks,
          color: const Color(0xFF4F46E5),
          child: _buildBodyContent(
            context,
            isDark: isDark,
            totalTasks: totalTasks,
            completedTasksCount: completedTasksCount,
            remainingCount: remainingCount,
            progress: progress,
            inProgressTasks: inProgressTasks,
          ),
        ),
      ),
    );
  }

  Widget _buildBodyContent(
    BuildContext context, {
    required bool isDark,
    required int totalTasks,
    required int completedTasksCount,
    required int remainingCount,
    required double progress,
    required List<Task> inProgressTasks,
  }) {
    // 1. Loading State
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
      );
    }

    // 2. Error State
    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.22),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEE2E2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.wifi_off_rounded,
                      size: 36,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Интернет байланысын тексеріп, қайталап көріңіз',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _loadTasks,
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    label: const Text(
                      'Қайталау',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // 3. Success State
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
      children: [
        // Header: Date + Greeting + Avatar PT
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getKazakhFormattedDate(),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Сәлем, Рамазан!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            // Avatar PT
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Text(
                  'PT',
                  style: TextStyle(
                    color: Color(0xFF4F46E5),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Achievement Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Осы аптадағы жетістік',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(
                    Icons.emoji_events_outlined,
                    color: Colors.white.withValues(alpha: 0.85),
                    size: 22,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '$completedTasksCount/$totalTasks орындалды',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                totalTasks == 0
                    ? 'Алғашқы тапсырманы қосыңыз!'
                    : (remainingCount > 0
                        ? 'Керемет! Тағы $remainingCount тапсырма қалды.'
                        : 'Тамаша! Барлық тапсырма орындалды! 🎉'),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Filter Chips
        Row(
          children: [
            // "Барлығы" chip
            GestureDetector(
              onTap: () {
                setState(() {
                  _filterOnlyUrgent = false;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: !_filterOnlyUrgent
                      ? const Color(0xFF4F46E5)
                      : (isDark ? const Color(0xFF1E293B) : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: !_filterOnlyUrgent
                        ? const Color(0xFF4F46E5)
                        : (isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0)),
                  ),
                ),
                child: Text(
                  'Барлығы',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: !_filterOnlyUrgent
                        ? Colors.white
                        : (isDark
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFF64748B)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // "Шұғыл" chip
            GestureDetector(
              onTap: () {
                setState(() {
                  _filterOnlyUrgent = true;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _filterOnlyUrgent
                      ? const Color(0xFF4F46E5)
                      : (isDark ? const Color(0xFF1E293B) : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _filterOnlyUrgent
                        ? const Color(0xFF4F46E5)
                        : (isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      size: 16,
                      color: _filterOnlyUrgent
                          ? Colors.white
                          : const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Шұғыл',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _filterOnlyUrgent
                            ? Colors.white
                            : (isDark
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Section Header: "Алдағы тапсырмалар"
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Алдағы тапсырмалар',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            Text(
              '${inProgressTasks.length} тапсырма',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4F46E5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Tasks Content
        if (_tasks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEEF2FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    size: 32,
                    color: Color(0xFF4F46E5),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Әзірге тапсырмалар жоқ. Жаңасын қосыңыз!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Жаңа тапсырма қосу үшін төмендегі «+» түймесін басыңыз',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          )
        else if (inProgressTasks.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.task_alt_rounded,
                    size: 36,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _filterOnlyUrgent
                        ? 'Шұғыл тапсырмалар жоқ'
                        : 'Орындалатын тапсырма жоқ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...inProgressTasks.map(
            (task) => TaskCard(
              task: task,
              onToggle: () => _handleToggle(task),
              onDelete: () => _handleDelete(task.id),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => TaskDetailScreen(
                      task: task,
                      onUpdate: (updated) => _handleUpdate(updated),
                      onDelete: (id) => _handleDelete(id?.toString() ?? task.id),
                    ),
                  ),
                );
                _loadTasks();
              },
            ),
          ),
        const SizedBox(height: 8),

        // Completed Tasks Summary Banner
        if (completedTasksCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$completedTasksCount тапсырма аяқталды',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Жақсы қарқынмен келе жатырсың!',
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
              ],
            ),
          ),
      ],
    );
  }
}
