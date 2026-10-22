import 'package:flutter/material.dart';
import '../models/task.dart';
import '../widgets/task_card.dart';
import 'task_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final List<Task> tasks;
  final Function(Task task) onToggleTask;
  final Function(Task task) onUpdateTask;
  final Function(String taskId) onDeleteTask;

  const SearchScreen({
    super.key,
    required this.tasks,
    required this.onToggleTask,
    required this.onUpdateTask,
    required this.onDeleteTask,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController =
      TextEditingController(text: 'Мобильді');
  String _searchQuery = 'Мобильді';
  final List<String> _recentSearches = ['Мобильді', 'Математика', 'Эссе'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final query = _searchQuery.trim().toLowerCase();
    final matchingTasks = widget.tasks.where((t) {
      if (query.isEmpty) return true;
      return t.title.toLowerCase().contains(query) ||
          t.subject.toLowerCase().contains(query) ||
          t.description.toLowerCase().contains(query);
    }).toList();

    // Group subjects from tasks
    final subjectSet = widget.tasks.map((t) => t.subject).toSet();
    final subjectsList = subjectSet.where((sub) {
      if (query.isEmpty) return true;
      return sub.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
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
                  setState(() {
                    _searchQuery = val;
                  });
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
                  '${matchingTasks.length} нәтиже',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4F46E5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (matchingTasks.isEmpty)
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
              ...matchingTasks.map(
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
            const SizedBox(height: 16),

            // Subjects Section
            Text(
              'Пәндер',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),

            ...subjectsList.map((subject) {
              final subjectTasks = widget.tasks.where((t) => t.subject == subject).toList();
              final inProgress = subjectTasks.where((t) => !t.isCompleted).length;
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
                      child: const Icon(
                        Icons.devices_rounded,
                        color: Color(0xFF4F46E5),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject,
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
        ),
      ),
    );
  }
}
