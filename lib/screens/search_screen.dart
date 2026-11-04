import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../models/task.dart';
import '../services/database_helper.dart';
import '../widgets/task_card.dart';
import 'task_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final List<Task>? tasks;
  final Function(Task task)? onToggleTask;
  final Function(Task task)? onUpdateTask;
  final Function(dynamic taskId)? onDeleteTask;

  const SearchScreen({
    super.key,
    this.tasks,
    this.onToggleTask,
    this.onUpdateTask,
    this.onDeleteTask,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController =
      TextEditingController(text: 'Мобильді');
  String _searchQuery = 'Мобильді';
  final List<String> _recentSearches = ['Мобильді', 'Деректер', 'Эссе'];

  List<Task> _searchResults = [];
  List<Subject> _subjects = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _performSearch(_searchQuery);
    _loadSubjects();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    final subs = await DatabaseHelper.instance.getSubjects();
    if (mounted) {
      setState(() {
        _subjects = subs;
      });
    }
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _searchQuery = query;
      _isLoading = true;
    });

    final results = await DatabaseHelper.instance.searchTasks(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    }
  }

  void _clearRecent() {
    setState(() {
      _recentSearches.clear();
    });
  }

  void _applyRecentSearch(String term) {
    setState(() {
      _searchController.text = term;
      _searchQuery = term;
    });
    _performSearch(term);
  }

  Future<void> _handleToggle(Task task) async {
    if (task.id.isEmpty) return;
    final intId = int.tryParse(task.id);
    if (intId != null) {
      await DatabaseHelper.instance.toggleTaskCompletion(intId, !task.isCompleted);
    }
    await _performSearch(_searchQuery);
    widget.onToggleTask?.call(task);
  }

  Future<void> _handleDelete(dynamic taskId) async {
    final intId = taskId is int ? taskId : int.tryParse(taskId.toString());
    if (intId != null) {
      await DatabaseHelper.instance.deleteTask(intId);
    }
    await _performSearch(_searchQuery);
    widget.onDeleteTask?.call(taskId);
  }

  Future<void> _handleUpdate(Task task) async {
    await DatabaseHelper.instance.updateTask(task);
    await _performSearch(_searchQuery);
    widget.onUpdateTask?.call(task);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final query = _searchQuery.trim().toLowerCase();

    final matchingSubjects = _subjects.where((sub) {
      if (query.isEmpty) return true;
      return sub.title.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
          children: [
            // Title
            Text(
              'Іздеу',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 14),

            // Search input field with purple border
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF4F46E5),
                  width: 1.5,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  _performSearch(val);
                },
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: 'Тапсырма немесе пәнді іздеу',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: Color(0xFF4F46E5),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _performSearch('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Recent Searches Section
            if (_recentSearches.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Соңғы іздеулер',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  GestureDetector(
                    onTap: _clearRecent,
                    child: const Text(
                      'Тазалау',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4F46E5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _recentSearches.map((term) {
                  final isSelected = _searchQuery.toLowerCase() == term.toLowerCase();
                  return GestureDetector(
                    onTap: () => _applyRecentSearch(term),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFEEF2FF)
                            : (isDark ? const Color(0xFF1E293B) : Colors.white),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF4F46E5)
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Text(
                        term,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? const Color(0xFF4F46E5)
                              : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),
            ],

            // Found Tasks Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Табылған тапсырмалар',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  '${_searchResults.length} нәтиже',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4F46E5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
                ),
              )
            else if (_searchResults.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'Ешқандай тапсырма табылмады',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              )
            else
              ..._searchResults.map(
                (task) => TaskCard(
                  task: task,
                  onToggle: () => _handleToggle(task),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => TaskDetailScreen(
                          task: task,
                          onUpdate: (updated) => _handleUpdate(updated),
                          onDelete: (id) {
                            final intId = id is int ? id : (int.tryParse(id.toString()) ?? int.tryParse(task.id) ?? 0);
                            _handleDelete(intId);
                          },
                        ),
                      ),
                    );
                    _performSearch(_searchQuery);
                  },
                ),
              ),
            const SizedBox(height: 16),

            // Subjects Section
            if (matchingSubjects.isNotEmpty) ...[
              Text(
                'Пәндер',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              ...matchingSubjects.map((subject) {
                final subjectTasks = _searchResults
                    .where((t) => t.subjectId == subject.id || (t.subjectTitle ?? t.subject) == subject.title)
                    .toList();
                final inProgress =
                    subjectTasks.where((t) => !t.isCompleted).length;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFEDE9FE),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFDDD6FE),
                          ),
                        ),
                        child: Icon(
                          Icons.menu_book_rounded,
                          color: subject.color,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subject.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${subjectTasks.length} тапсырма · $inProgress орындалуда',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
