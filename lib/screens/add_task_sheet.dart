import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../models/task.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart';
import '../utils/app_logger.dart';
import '../utils/validators.dart';

typedef AddTaskBottomSheet = AddTaskSheet;

class AddTaskSheet extends StatefulWidget {
  final Task? taskToEdit;
  final Function(Task task) onSave;

  const AddTaskSheet({
    super.key,
    this.taskToEdit,
    required this.onSave,
  });

  static Future<Task?> show(
    BuildContext context, {
    Task? taskToEdit,
    required Function(Task task) onSave,
  }) {
    return showModalBottomSheet<Task>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddTaskSheet(
        taskToEdit: taskToEdit,
        onSave: onSave,
      ),
    );
  }

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  List<Subject> _subjects = [];
  Subject? _selectedSubject;
  bool _isLoadingSubjects = true;
  bool _isSubmitting = false;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  late TaskPriority _selectedPriority;

  static const List<Subject> _fallbackSubjects = [
    Subject(id: 1, title: 'Мобильді әзірлеу', colorHex: '#4F46E5'),
    Subject(id: 2, title: 'Деректер қоры', colorHex: '#0EA5E9'),
    Subject(id: 3, title: 'Ағылшын тілі', colorHex: '#10B981'),
    Subject(id: 4, title: 'Жалпы', colorHex: '#8B5CF6'),
  ];

  @override
  void initState() {
    super.initState();
    final edit = widget.taskToEdit;
    if (edit != null) {
      _titleController = TextEditingController(text: edit.title);
      _descriptionController =
          TextEditingController(text: edit.description ?? '');
      _selectedDate = edit.deadlineDateTime;
      _selectedTime = TimeOfDay.fromDateTime(edit.deadlineDateTime);
      _selectedPriority = edit.priorityEnum;
    } else {
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();
      _selectedDate = null;
      _selectedTime = null;
      _selectedPriority = TaskPriority.medium;
    }

    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    try {
      final list = await DatabaseHelper.instance.getSubjects();
      if (!mounted) return;

      setState(() {
        _subjects = list.isNotEmpty ? list : _fallbackSubjects;
        _isLoadingSubjects = false;
        _resolveSelectedSubject();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _subjects = _fallbackSubjects;
        _isLoadingSubjects = false;
        _resolveSelectedSubject();
      });
    }
  }

  void _resolveSelectedSubject() {
    final edit = widget.taskToEdit;
    if (edit != null) {
      final match = _subjects.firstWhere(
        (s) =>
            (edit.subjectId != null && s.id == edit.subjectId) ||
            s.title.toLowerCase() ==
                (edit.subjectTitle ?? edit.subject).toLowerCase(),
        orElse: () => _subjects.isNotEmpty
            ? _subjects.first
            : const Subject(id: 1, title: 'Жалпы', colorHex: '#4F46E5'),
      );
      _selectedSubject = match;
    } else if (_subjects.isNotEmpty) {
      _selectedSubject = _subjects.first;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _selectedDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'Күнді таңдаңыз',
      cancelText: 'Болдырмау',
      confirmText: 'Таңдау',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4F46E5),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final initial = _selectedTime ?? const TimeOfDay(hour: 18, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: 'Уақытты таңдаңыз',
      cancelText: 'Болдырмау',
      confirmText: 'Таңдау',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4F46E5),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _showAddSubjectDialog() {
    final textController = TextEditingController();
    String selectedHex = '#4F46E5';
    final colors = [
      '#4F46E5', // Indigo
      '#0EA5E9', // Sky blue
      '#10B981', // Emerald
      '#F59E0B', // Amber
      '#EC4899', // Pink
      '#8B5CF6', // Purple
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Жаңа пән қосу',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: textController,
                  autofocus: true,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Пән атауын енгізіңіз',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Түсін таңдаңыз:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: colors.map((hex) {
                    final colorVal = Color(
                        int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
                    final isPicked = selectedHex == hex;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedHex = hex;
                        });
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: colorVal,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isPicked ? Colors.white : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: isPicked
                              ? [
                                  BoxShadow(
                                    color: colorVal.withValues(alpha: 0.5),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : [],
                        ),
                        child: isPicked
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 18)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Болдырмау',
                    style: TextStyle(color: Color(0xFF64748B))),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final newTitle = textController.text.trim();
                  if (newTitle.isNotEmpty) {
                    final subject = Subject(
                      title: newTitle,
                      colorHex: selectedHex,
                    );
                    int? newId;
                    try {
                      newId =
                          await DatabaseHelper.instance.insertSubject(subject);
                    } catch (_) {}
                    final createdSubject = subject.copyWith(id: newId ?? 999);

                    setState(() {
                      _subjects.add(createdSubject);
                      _selectedSubject = createdSubject;
                    });
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                  }
                },
                child: const Text('Қосу'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _save() async {
    final titleError = Validators.validateTaskTitle(_titleController.text);
    if (titleError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(titleError),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final date = _selectedDate ?? DateTime.now().add(const Duration(days: 1));
    final time = _selectedTime ?? const TimeOfDay(hour: 18, minute: 0);
    final deadline =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);

    final isEdit =
        widget.taskToEdit != null && widget.taskToEdit!.id.isNotEmpty;
    final subjectTitle = _selectedSubject?.title ?? 'Жалпы';

    final taskToSave = Task(
      id: isEdit ? widget.taskToEdit!.id : '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      subject: subjectTitle,
      subjectId: _selectedSubject?.id,
      subjectTitle: subjectTitle,
      deadline: deadline.toIso8601String(),
      priority: _selectedPriority.label,
      isCompleted: widget.taskToEdit?.isCompleted ?? false,
      isFavorite: widget.taskToEdit?.isFavorite ?? false,
      subtasks: widget.taskToEdit?.subtasks ?? const [],
    );

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      Task savedTask;
      if (isEdit) {
        savedTask = await ApiService.instance.updateTask(taskToSave);
      } else {
        savedTask = await ApiService.instance.createTask(taskToSave);
      }

      // Also persist to local database as cache if available
      try {
        if (isEdit) {
          await DatabaseHelper.instance.updateTask(savedTask);
        } else {
          await DatabaseHelper.instance.insertTask(savedTask);
        }
      } catch (_) {}

      widget.onSave(savedTask);
      AppLogger.info('Task saved: #${savedTask.id} (${savedTask.title})');
      navigator.pop(savedTask);

      messenger.showSnackBar(
        SnackBar(
          content: Text(
              isEdit ? 'Өзгерістер сақталды' : 'Тапсырма сәтті қосылды'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        messenger.showSnackBar(
          SnackBar(
            content: Text('Қате орын алды: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  String _formatDateDisplay() {
    if (_selectedDate == null) return 'Күнді таңдау';
    final d = _selectedDate!;
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day.$month.${d.year}';
  }

  String _formatTimeDisplay() {
    if (_selectedTime == null) return 'Уақыт';
    final hour = _selectedTime!.hour.toString().padLeft(2, '0');
    final minute = _selectedTime!.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit =
        widget.taskToEdit != null && widget.taskToEdit!.id.isNotEmpty;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? 'Тапсырманы өңдеу' : 'Тапсырма жасау',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'Тапсырма атауы',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                enabled: !_isSubmitting,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: 'Тапсырма атауын енгізіңіз',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                  ),
                  filled: true,
                  fillColor:
                      isDark ? const Color(0xFF1E293B) : Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: Color(0xFF4F46E5), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Subject selection
              Text(
                'Пән',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 8),
              _isLoadingSubjects
                  ? const Center(
                      child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(
                          color: Color(0xFF4F46E5)),
                    ))
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color:
                            isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Subject>(
                          value: _selectedSubject,
                          isExpanded: true,
                          hint: const Text('Пәнді таңдаңыз'),
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                          items: _subjects.map((sub) {
                            return DropdownMenuItem<Subject>(
                              value: sub,
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: sub.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    sub.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: _isSubmitting
                              ? null
                              : (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedSubject = val;
                                    });
                                  }
                                },
                        ),
                      ),
                    ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _isSubmitting ? null : _showAddSubjectDialog,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    '+ Жаңа пән',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Date & Time Row
              Row(
                children: [
                  // Date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Күні',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _isSubmitting ? null : _pickDate,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            height: 48,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDateDisplay(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _selectedDate == null
                                        ? (isDark
                                            ? const Color(0xFF64748B)
                                            : const Color(0xFF94A3B8))
                                        : (isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A)),
                                  ),
                                ),
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 16,
                                  color: isDark
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF94A3B8),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Уақыты',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _isSubmitting ? null : _pickTime,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            height: 48,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatTimeDisplay(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _selectedTime == null
                                        ? (isDark
                                            ? const Color(0xFF64748B)
                                            : const Color(0xFF94A3B8))
                                        : (isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A)),
                                  ),
                                ),
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 16,
                                  color: isDark
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF94A3B8),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Priority
              Text(
                'Басымдық',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _buildPrioritySegment(
                        TaskPriority.high, 'Жоғары', isDark),
                    _buildPrioritySegment(
                        TaskPriority.medium, 'Орташа', isDark),
                    _buildPrioritySegment(TaskPriority.low, 'Төмен', isDark),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                'Сипаттама',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                enabled: !_isSubmitting,
                maxLines: 3,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: 'Тапсырма туралы қосымша мәлімет...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                  ),
                  filled: true,
                  fillColor:
                      isDark ? const Color(0xFF1E293B) : Colors.white,
                  contentPadding: const EdgeInsets.all(14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: Color(0xFF4F46E5), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          isEdit ? 'Өзгерістерді сақтау' : 'Сақтау',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrioritySegment(
      TaskPriority priority, String label, bool isDark) {
    final isSelected = _selectedPriority == priority;
    return Expanded(
      child: GestureDetector(
        onTap: _isSubmitting
            ? null
            : () {
                setState(() {
                  _selectedPriority = priority;
                });
              },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF334155) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected && !isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected) ...[
                const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: Color(0xFF4F46E5),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF4F46E5)
                      : (isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
