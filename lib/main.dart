import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/task.dart';
import 'screens/home_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/search_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/error_screen.dart';
import 'widgets/error_state_view.dart';
import 'services/api_service.dart';
import 'services/database_helper.dart';
import 'services/websocket_service.dart';
import 'utils/app_logger.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // Start Realtime WebSocket connection
  WebSocketService.instance.connect();
  AppLogger.info('UniTask application initialized');
  runApp(const UniTaskApp());
}

class UniTaskApp extends StatefulWidget {
  const UniTaskApp({super.key});

  @override
  State<UniTaskApp> createState() => _UniTaskAppState();
}

class _UniTaskAppState extends State<UniTaskApp> {
  ThemeMode _themeMode = ThemeMode.light;
  bool _showSplash = true;
  bool _isLoggedIn = true;

  void _toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void _handleLogin() {
    setState(() {
      _isLoggedIn = true;
    });
  }

  void _handleLogout() {
    setState(() {
      _isLoggedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryIndigo = Color(0xFF4F46E5);

    return MaterialApp(
      title: 'UniTask',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryIndigo,
          brightness: Brightness.light,
          primary: primaryIndigo,
          surface: const Color(0xFFF8FAFC),
          surfaceContainerLow: Colors.white,
          surfaceContainerHighest: const Color(0xFFEEF2FF),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8FAFC),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryIndigo,
          brightness: Brightness.dark,
          primary: const Color(0xFF818CF8),
          surface: const Color(0xFF0F172A),
          surfaceContainerLow: const Color(0xFF1E293B),
          surfaceContainerHighest: const Color(0xFF334155),
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F172A),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: _showSplash
          ? SplashScreen(
              onFinish: () {
                setState(() {
                  _showSplash = false;
                });
              },
            )
          : (_isLoggedIn
              ? MainNavigationShell(
                  isDarkMode: _themeMode == ThemeMode.dark,
                  onToggleTheme: _toggleTheme,
                  onLogout: _handleLogout,
                )
              : LoginScreen(onLogin: _handleLogin)),
      routes: {
        '/404': (context) => const ErrorScreen(type: ErrorType.notFound),
        '/disconnect': (context) => const ErrorScreen(type: ErrorType.noInternet),
        '/500': (context) => const ErrorScreen(type: ErrorType.serverError),
      },
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (_) => const ErrorScreen(type: ErrorType.notFound),
      ),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool isDark) onToggleTheme;
  final VoidCallback onLogout;

  const MainNavigationShell({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.onLogout,
  });

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  List<Task> _tasks = [];
  StreamSubscription? _socketSub;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _socketSub = WebSocketService.instance.taskEventsStream.listen((event) {
      if (!mounted) return;
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
            final idx = _tasks.indexWhere((t) => t.id == task.id);
            if (idx != -1) {
              _tasks[idx] = task;
            }
          } else if (action == 'delete') {
            _tasks.removeWhere((t) => t.id == task.id);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    try {
      final tasks = await ApiService.instance.fetchTasks();
      if (mounted) {
        setState(() {
          _tasks = tasks;
        });
      }
    } catch (_) {
      try {
        final tasks = await DatabaseHelper.instance.getTasks();
        if (mounted) {
          setState(() {
            _tasks = tasks;
          });
        }
      } catch (_) {}
    }
  }

  Future<void> _handleToggleTask(Task task) async {
    if (task.id.isEmpty) return;
    try {
      final updated = task.copyWith(isCompleted: !task.isCompleted);
      await ApiService.instance.updateTask(updated);
      await _loadTasks();
    } catch (_) {}
  }

  Future<void> _handleAddTask(Task task) async {
    await _loadTasks();
  }

  Future<void> _handleUpdateTask(Task updatedTask) async {
    try {
      await ApiService.instance.updateTask(updatedTask);
      await _loadTasks();
    } catch (_) {}
  }

  Future<void> _handleDeleteTask(dynamic taskId) async {
    if (taskId != null) {
      try {
        await ApiService.instance.deleteTask(taskId.toString());
        await _loadTasks();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;

    final screens = [
      HomeScreen(
        tasks: _tasks,
        onToggleTask: _handleToggleTask,
        onAddTask: _handleAddTask,
        onUpdateTask: _handleUpdateTask,
        onDeleteTask: _handleDeleteTask,
      ),
      TasksScreen(
        tasks: _tasks,
        onToggleTask: _handleToggleTask,
        onAddTask: _handleAddTask,
        onUpdateTask: _handleUpdateTask,
        onDeleteTask: _handleDeleteTask,
      ),
      CalendarScreen(
        tasks: _tasks,
        onToggleTask: _handleToggleTask,
        onUpdateTask: _handleUpdateTask,
        onDeleteTask: _handleDeleteTask,
        onAddTask: _handleAddTask,
      ),
      SearchScreen(
        tasks: _tasks,
        onToggleTask: _handleToggleTask,
        onUpdateTask: _handleUpdateTask,
        onDeleteTask: _handleDeleteTask,
      ),
      ProfileScreen(
        tasks: _tasks,
        isDarkMode: widget.isDarkMode,
        onToggleTheme: widget.onToggleTheme,
        onLogout: widget.onLogout,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              width: 1,
            ),
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'Басты', isDark),
                _buildNavItem(1, Icons.assignment_outlined, Icons.assignment_rounded, 'Тапсырмалар', isDark),
                _buildNavItem(2, Icons.calendar_month_outlined, Icons.calendar_month_rounded, 'Күнтізбе', isDark),
                _buildNavItem(3, Icons.search_rounded, Icons.search_rounded, 'Іздеу', isDark),
                _buildNavItem(4, Icons.person_outline_rounded, Icons.person_rounded, 'Профиль', isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData unselectedIcon,
    IconData selectedIcon,
    String label,
    bool isDark,
  ) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark
                        ? const Color(0xFF312E81).withValues(alpha: 0.5)
                        : const Color(0xFFEEF2FF))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isSelected ? selectedIcon : unselectedIcon,
                size: 20,
                color: isSelected
                    ? const Color(0xFF4F46E5)
                    : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF4F46E5)
                    : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
