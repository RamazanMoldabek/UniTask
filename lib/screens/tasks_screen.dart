import 'dart:async';
import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../models/task.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart';
import '../services/websocket_service.dart';
import '../utils/app_logger.dart';
import '../widgets/connection_banner.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/error_state_view.dart';
import '../widgets/task_card.dart';
import 'task_detail_screen.dart';
import 'add_task_sheet.dart';

typedef TasksListScreen = TasksScreen;

class TasksScreen extends StatefulWidget {
  final List<Task>? tasks;
  final Function(Task task)? onToggleTask;
  final Function(Task task)? onAddTask;
  final Function(Task task)? onUpdateTask;
  final Function(dynamic taskId)? onDeleteTask;

  const TasksScreen({
    super.key,
    this.tasks,
    this.onToggleTask,
    this.onAddTask,
    this.onUpdateTask,
    this.onDeleteTask,
  });

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedSubjectFilter;
  String _sortBy = 'default';

  List<Task> _tasks = [];
  List<Subject> _subjects = [];
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription? _socketSubscription;

  static const List<Subject> _fallbackSubjects = [
    Subject(id: 1, title: 'Мобильді әзірлеу', colorHex: '#4F46E5'),
    Subject(id: 2, title: 'Деректер қоры', colorHex: '#0EA5E9'),
    Subject(id: 3, title: 'Ағылшын тілі', colorHex: '#10B981'),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _listenToRealtimeEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
              }
            } else if (action == 'update' || action == 'toggle') {
              final index = _tasks.indexWhere((t) => t.id == task.id);
              if (index != -1) {
                _tasks[index] = task;
              }
            } else if (action == 'delete') {
              _tasks.removeWhere((t) => t.id == task.id);
            }
          });
        }
      } catch (e) {
        AppLogger.error('Realtime event error in TasksScreen', error: e);
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tasksFuture = ApiService.instance.fetchTasks();
      final subjectsFuture = DatabaseHelper.instance.getSubjects().catchError(
            (_) => _fallbackSubjects,
          );

      final results = await Future.wait([
        tasksFuture,
        subjectsFuture,
      ]);

      if (mounted) {
        final tasks = results[0] as List<Task>;
        final subjects = results[1] as List<Subject>;

        setState(() {
          _tasks = tasks;
          _subjects = subjects.isNotEmpty ? subjects : _fallbackSubjects;
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
    final original = List<Task>.from(_tasks);
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
          _tasks = original;
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

  void _showSubjectFilterSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text(
                'Пән бойынша сүзу',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
            ListTile(
              title: const Text('Барлық пәндер'),
              trailing: _selectedSubjectFilter == null
                  ? const Icon(Icons.check_rounded, color: Color(0xFF4F46E5))
                  : null,
              onTap: () {
                setState(() {
                  _selectedSubjectFilter = null;
                });
                Navigator.pop(ctx);
              },
            ),
            ..._subjects.map((sub) {
              final isSelected = _selectedSubjectFilter == sub.title;
              return ListTile(
                leading: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: sub.color,
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(
                  sub.title,
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? const Color(0xFF4F46E5) : null,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_rounded, color: Color(0xFF4F46E5))
                    : null,
                onTap: () {
                  setState(() {
                    _selectedSubjectFilter = sub.title;
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

  void _showSortOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text(
                'Сұрыптау тәсілі',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
            ListTile(
              title: const Text('Әдепкі (күйі мен мерзімі бойынша)'),
              trailing: _sortBy == 'default'
                  ? const Icon(Icons.check_rounded, color: Color(0xFF4F46E5))
                  : null,
              onTap: () {
                setState(() => _sortBy = 'default');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Дедлайн мерзімі бойынша'),
              trailing: _sortBy == 'deadline'
                  ? const Icon(Icons.check_rounded, color: Color(0xFF4F46E5))
                  : null,
              onTap: () {
                setState(() => _sortBy = 'deadline');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Басымдық бойынша (Жоғарыдан төменге)'),
              trailing: _sortBy == 'priority'
                  ? const Icon(Icons.check_rounded, color: Color(0xFF4F46E5))
                  : null,
              onTap: () {
                setState(() => _sortBy = 'priority');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    var filteredList = _tasks.where((t) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesTitle = t.title.toLowerCase().contains(q);
        final matchesSubject =
            (t.subject.isNotEmpty ? t.subject : (t.subjectTitle ?? ''))
                .toLowerCase()
                .contains(q);
        final matchesDesc = (t.description ?? '').toLowerCase().contains(q);
        if (!matchesTitle && !matchesSubject && !matchesDesc) return false;
      }
      if (_selectedSubjectFilter != null) {
        final sTitle =
            t.subject.isNotEmpty ? t.subject : (t.subjectTitle ?? '');
        if (sTitle != _selectedSubjectFilter) return false;
      }
      return true;
    }).toList();

    if (_sortBy == 'deadline') {
      filteredList.sort((a, b) => a.deadlineDateTime.compareTo(b.deadlineDateTime));
    } else if (_sortBy == 'priority') {
      int pRank(String p) {
        switch (p) {
          case 'Жоғары':
            return 1;
          case 'Орташа':
            return 2;
          case 'Төмен':
            return 3;
          default:
            return 4;
        }
      }

      filteredList.sort((a, b) => pRank(a.priority).compareTo(pRank(b.priority)));
    } else {
      filteredList.sort((a, b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        return a.deadlineDateTime.compareTo(b.deadlineDateTime);
      });
    }

    final inProgressTasks = filteredList.where((t) => !t.isCompleted).toList();
    final completedTasks = filteredList.where((t) => t.isCompleted).toList();

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            const ConnectionBanner(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                color: const Color(0xFF4F46E5),
                child: _buildBody(
                  context,
                  isDark: isDark,
                  filteredTasks: filteredList,
                  inProgressTasks: inProgressTasks,
                  completedTasks: completedTasks,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required bool isDark,
    required List<Task> filteredTasks,
    required List<Task> inProgressTasks,
    required List<Task> completedTasks,
  }) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.18),
          ErrorStateView.noInternet(
            onRetry: _loadData,
            message: 'Интернет байланысын тексеріп, қайталап көріңіз',
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
      children: [
        // Top Header
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
              onPressed: () async {
                await AddTaskSheet.show(
                  context,
                  onSave: (task) async {
                    setState(() {
                      if (!_tasks.any((t) => t.id == task.id)) {
                        _tasks.insert(0, task);
                      }
                    });
                    WebSocketService.instance
                        .broadcastTaskAction('create', task);
                    widget.onAddTask?.call(task);
                  },
                );
              },
              icon: const Icon(
                Icons.add_rounded,
                color: Color(0xFF4F46E5),
                size: 26,
              ),
              tooltip: 'Тапсырма жасау',
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
                color:
                    isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 20,
                color:
                    isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
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

        // Filters & Sort Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${filteredTasks.length} тапсырма',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            Row(
              children: [
                InkWell(
                  onTap: _showSortOptions,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.sort_rounded,
                          size: 16,
                          color: Color(0xFF4F46E5),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Сұрыптау',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: _showSubjectFilterSheet,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
          ],
        ),
        const SizedBox(height: 16),

        if (_tasks.isEmpty)
          const EmptyStateView(
            title: 'Әзірге тапсырмалар жоқ. Жаңасын қосыңыз!',
            subtitle: 'Жаңа тапсырма қосу үшін жоғарғы «+» батырмасын басыңыз',
            icon: Icons.assignment_outlined,
          )
        else if (filteredTasks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 48,
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
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
          )
        else ...[
          // Section 1: In Progress
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
                onToggle: () => _handleToggle(task),
                onDelete: () => _handleDelete(task.id),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => TaskDetailScreen(
                        task: task,
                        onUpdate: (updated) => _handleUpdate(updated),
                        onDelete: (id) =>
                            _handleDelete(id?.toString() ?? task.id),
                      ),
                    ),
                  );
                  _loadData();
                },
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Section 2: Completed
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
                onToggle: () => _handleToggle(task),
                onDelete: () => _handleDelete(task.id),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => TaskDetailScreen(
                        task: task,
                        onUpdate: (updated) => _handleUpdate(updated),
                        onDelete: (id) =>
                            _handleDelete(id?.toString() ?? task.id),
                      ),
                    ),
                  );
                  _loadData();
                },
              ),
            ),
          ],
        ],
      ],
    );
  }
}
