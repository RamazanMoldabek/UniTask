import 'dart:async';
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import '../utils/app_logger.dart';
import '../widgets/connection_banner.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/error_state_view.dart';
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
  StreamSubscription? _socketSubscription;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _listenToRealtimeEvents();
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    super.dispose();
  }

  void _listenToRealtimeEvents() {
    _socketSubscription =
        WebSocketService.instance.taskEventsStream.listen((event) {
      if (!mounted) return;
      try {
        final action = event['action'] as String?;
        final rawTask = event['task'];
        if (rawTask is Map<String, dynamic>) {
          final task = Task.fromJson(rawTask);
          setState(() {
            if (action == 'create') {
              if (!_tasks.any((t) => t.id == task.id)) {
                _tasks.insert(0, task);
                AppLogger.info('Realtime task created: #${task.id}');
              }
            } else if (action == 'update' || action == 'toggle') {
              final index = _tasks.indexWhere((t) => t.id == task.id);
              if (index != -1) {
                _tasks[index] = task;
                AppLogger.info('Realtime task updated: #${task.id}');
              }
            } else if (action == 'delete') {
              _tasks.removeWhere((t) => t.id == task.id);
              AppLogger.info('Realtime task deleted: #${task.id}');
            }
          });
        }
      } catch (e) {
        AppLogger.error('Error handling realtime event', error: e);
      }
    });
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
    } catch (e) {
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

    setState(() {
      final idx = _tasks.indexWhere((t) => t.id == task.id);
      if (idx != -1) {
        _tasks[idx] = updatedTask;
      }
    });

    try {
      final savedTask = await ApiService.instance.updateTask(updatedTask);
      WebSocketService.instance.broadcastTaskAction('toggle', savedTask);

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
    final taskToDelete = _tasks.firstWhere(
      (t) => t.id == taskId,
      orElse: () => Task(id: taskId, title: '', deadline: ''),
    );

    setState(() {
      _tasks.removeWhere((t) => t.id == taskId);
    });

    try {
      await ApiService.instance.deleteTask(taskId);
      WebSocketService.instance.broadcastTaskAction('delete', taskToDelete);
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
      WebSocketService.instance.broadcastTaskAction('update', updated);

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
                if (!_tasks.any((t) => t.id == createdTask.id)) {
                  _tasks.insert(0, createdTask);
                }
              });
              WebSocketService.instance
                  .broadcastTaskAction('create', createdTask);
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
        child: Column(
          children: [
            const ConnectionBanner(),
            Expanded(
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
          ],
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
          SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          ErrorStateView.noInternet(
            onRetry: _loadTasks,
            message: 'Интернет байланысын тексеріп, қайталап көріңіз',
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
          const EmptyStateView(
            title: 'Әзірге тапсырмалар жоқ. Жаңасын қосыңыз!',
            subtitle: 'Жаңа тапсырма қосу үшін төмендегі «+» түймесін басыңыз',
            icon: Icons.assignment_outlined,
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
