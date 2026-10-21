import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/task.dart';
import 'screens/home_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const UniTaskApp());
}

class UniTaskApp extends StatefulWidget {
  const UniTaskApp({super.key});

  @override
  State<UniTaskApp> createState() => _UniTaskAppState();
}

class _UniTaskAppState extends State<UniTaskApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryIndigo = Color(0xFF6366F1);

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
          surfaceContainerHighest: const Color(0xFFEEF2F6),
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
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: primaryIndigo.withValues(alpha: 0.15),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: primaryIndigo,
              );
            }
            return const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: Color(0xFF64748B),
            );
          }),
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
        scaffoldBackgroundColor: const Color(0xFF0B1120),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B1120),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF0F172A),
          indicatorColor: const Color(0xFF818CF8).withValues(alpha: 0.2),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFF818CF8),
              );
            }
            return const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: Color(0xFF94A3B8),
            );
          }),
        ),
      ),
      home: MainNavigationShell(
        isDarkMode: _themeMode == ThemeMode.dark,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool isDark) onToggleTheme;

  const MainNavigationShell({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  late List<Task> _tasks;

  @override
  void initState() {
    super.initState();
    _tasks = Task.sampleTasks;
  }

  void _handleToggleTask(Task task) {
    setState(() {
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task.copyWith(isCompleted: !task.isCompleted);
      }
    });
  }

  void _handleAddTask(Task task) {
    setState(() {
      _tasks.insert(0, task);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('«${task.title}» тапсырмасы қосылды'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _handleUpdateTask(Task updatedTask) {
    setState(() {
      final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
      if (index != -1) {
        _tasks[index] = updatedTask;
      }
    });
  }

  void _handleDeleteTask(String taskId) {
    setState(() {
      _tasks.removeWhere((t) => t.id == taskId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Тапсырма сәтті жойылды'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
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
      ProfileScreen(
        tasks: _tasks,
        isDarkMode: widget.isDarkMode,
        onToggleTheme: widget.onToggleTheme,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment_rounded),
            label: 'Тапсырмалар',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Күнтізбе',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}
