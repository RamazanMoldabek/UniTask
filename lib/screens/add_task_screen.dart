import 'package:flutter/material.dart';
import '../models/task.dart';

class AddTaskScreen extends StatefulWidget {
  final Task? taskToEdit;

  const AddTaskScreen({super.key, this.taskToEdit});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  final TextEditingController _subtaskController = TextEditingController();

  late String _selectedSubject;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late TaskPriority _selectedPriority;
  late List<SubTask> _subtasks;

  @override
  void initState() {
    super.initState();
    final edit = widget.taskToEdit;
    if (edit != null) {
      _titleController = TextEditingController(text: edit.title);
      _descriptionController = TextEditingController(text: edit.description);
      _selectedSubject = edit.subject;
      _selectedDate = edit.deadline;
      _selectedTime = TimeOfDay.fromDateTime(edit.deadline);
      _selectedPriority = edit.priority;
      _subtasks = edit.subtasks.map((s) => s.copyWith()).toList();
    } else {
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();
      _selectedSubject = Task.availableSubjects.first;
      final now = DateTime.now();
      _selectedDate = DateTime(now.year, now.month, now.day + 1);
      _selectedTime = const TimeOfDay(hour: 18, minute: 0);
      _selectedPriority = TaskPriority.medium;
      _subtasks = [];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Дедлайн күнін таңдаңыз',
      cancelText: 'Болдырмау',
      confirmText: 'Таңдау',
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      helpText: 'Уақытты таңдаңыз',
      cancelText: 'Болдырмау',
      confirmText: 'Таңдау',
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _addSubtask() {
    final text = _subtaskController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _subtasks.add(
          SubTask(
            id: 'st-${DateTime.now().millisecondsSinceEpoch}',
            title: text,
            isDone: false,
          ),
        );
        _subtaskController.clear();
      });
    }
  }

  void _removeSubtask(int index) {
    setState(() {
      _subtasks.removeAt(index);
    });
  }

  void _saveTask() {
    if (!_formKey.currentState!.validate()) return;

    final combinedDeadline = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final task = Task(
      id: widget.taskToEdit?.id ?? 'task-${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      subject: _selectedSubject,
      deadline: combinedDeadline,
      priority: _selectedPriority,
      isCompleted: widget.taskToEdit?.isCompleted ?? false,
      description: _descriptionController.text.trim(),
      subtasks: _subtasks,
    );

    Navigator.of(context).pop(task);
  }

  String _formatDate(DateTime dt) {
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
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEditing = widget.taskToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Тапсырманы өңдеу' : 'Жаңа тапсырма қосу',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: FilledButton.icon(
            onPressed: _saveTask,
            icon: const Icon(Icons.check_circle_rounded),
            label: Text(
              isEditing ? 'Өзгерістерді сақтау' : 'Сақтау',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Task Title Field
              Text(
                'Тапсырма атауы',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Мысалы: Мобильді қосымшаны қорғау',
                  prefixIcon: const Icon(Icons.edit_note_rounded),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: colorScheme.primary, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Тапсырма атауын енгізу міндетті';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 2. Subject Selection
              Text(
                'Пән / Сала',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: Task.availableSubjects.contains(_selectedSubject)
                        ? _selectedSubject
                        : Task.availableSubjects.first,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    items: Task.availableSubjects.map((sub) {
                      return DropdownMenuItem<String>(
                        value: sub,
                        child: Row(
                          children: [
                            Icon(Icons.school_rounded, size: 20, color: colorScheme.primary),
                            const SizedBox(width: 12),
                            Text(sub, style: const TextStyle(fontWeight: FontWeight.w500)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedSubject = val;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 3. Priority Selection
              Text(
                'Басымдық деңгейі',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<TaskPriority>(
                  segments: [
                    ButtonSegment<TaskPriority>(
                      value: TaskPriority.low,
                      label: Text(TaskPriority.low.label),
                      icon: Icon(TaskPriority.low.icon, color: TaskPriority.low.color),
                    ),
                    ButtonSegment<TaskPriority>(
                      value: TaskPriority.medium,
                      label: Text(TaskPriority.medium.label),
                      icon: Icon(TaskPriority.medium.icon, color: TaskPriority.medium.color),
                    ),
                    ButtonSegment<TaskPriority>(
                      value: TaskPriority.high,
                      label: Text(TaskPriority.high.label),
                      icon: Icon(TaskPriority.high.icon, color: TaskPriority.high.color),
                    ),
                  ],
                  selected: {_selectedPriority},
                  onSelectionChanged: (Set<TaskPriority> newSelection) {
                    setState(() {
                      _selectedPriority = newSelection.first;
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),

              // 4. Deadline Date & Time Pickers
              Text(
                'Мерзімі (Дедлайн)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 20, color: colorScheme.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _formatDate(_selectedDate),
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _pickTime,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.access_time_rounded, size: 20, color: colorScheme.primary),
                            const SizedBox(width: 10),
                            Text(
                              _formatTime(_selectedTime),
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 5. Description / Notes Field
              Text(
                'Сипаттама мен қосымша жазбалар',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Тапсырмаға қатысты нұсқаулықтар, сілтемелер немесе ескертулер...',
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: colorScheme.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 6. Subtasks / Checklist
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ішкі қадамдар (Чек-лист)',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${_subtasks.length} қадам',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _subtaskController,
                      decoration: InputDecoration(
                        hintText: 'Жаңа қадам қосу...',
                        isDense: true,
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _addSubtask(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: _addSubtask,
                    icon: const Icon(Icons.add_rounded),
                    tooltip: 'Қадам қосу',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_subtasks.isNotEmpty)
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _subtasks.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final item = _subtasks[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.title,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            color: colorScheme.error,
                            onPressed: () => _removeSubtask(index),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
