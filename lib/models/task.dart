import 'package:flutter/material.dart';
import 'subtask.dart';

export 'subtask.dart';

typedef SubTask = Subtask;

enum TaskPriority {
  low,
  medium,
  high;

  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Төмен';
      case TaskPriority.medium:
        return 'Орташа';
      case TaskPriority.high:
        return 'Жоғары';
    }
  }

  static TaskPriority fromString(String val) {
    switch (val) {
      case 'Жоғары':
        return TaskPriority.high;
      case 'Төмен':
        return TaskPriority.low;
      case 'Орташа':
      default:
        return TaskPriority.medium;
    }
  }

  Color get color {
    switch (this) {
      case TaskPriority.low:
        return const Color(0xFF10B981); // Emerald Green
      case TaskPriority.medium:
        return const Color(0xFFD97706); // Amber/Orange
      case TaskPriority.high:
        return const Color(0xFFEF4444); // Red
    }
  }

  Color get backgroundColor {
    switch (this) {
      case TaskPriority.low:
        return const Color(0xFFDCFCE7);
      case TaskPriority.medium:
        return const Color(0xFFFEF3C7);
      case TaskPriority.high:
        return const Color(0xFFFEE2E2);
    }
  }

  IconData get icon {
    switch (this) {
      case TaskPriority.low:
        return Icons.arrow_downward_rounded;
      case TaskPriority.medium:
        return Icons.remove_rounded;
      case TaskPriority.high:
        return Icons.priority_high_rounded;
    }
  }
}

class Task {
  final String id;
  final String title;
  final String subject;
  final String deadline;
  final String priority;
  final bool isCompleted;

  // Additional optional fields for compatibility with UI and SQLite
  final String? description;
  final int? subjectId;
  final String? subjectTitle;
  final bool isFavorite;
  final List<Subtask> subtasks;

  const Task({
    this.id = '',
    required this.title,
    this.subject = '',
    this.description,
    this.subjectId,
    this.subjectTitle,
    required this.deadline,
    this.priority = 'Орташа',
    this.isCompleted = false,
    this.isFavorite = false,
    this.subtasks = const [],
  });

  DateTime get deadlineDateTime {
    return DateTime.tryParse(deadline) ?? DateTime.now();
  }

  TaskPriority get priorityEnum => TaskPriority.fromString(priority);

  /// Десериализация из JSON (MockAPI / REST API)
  factory Task.fromJson(Map<String, dynamic> json) {
    final sub = json['subject'] as String? ?? json['subject_title'] as String? ?? '';
    final completed = json['isCompleted'] is bool
        ? json['isCompleted'] as bool
        : (json['is_completed'] == 1 ||
            json['is_completed'] == true ||
            json['isCompleted'] == 'true' ||
            json['isCompleted'] == 1);

    return Task(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      subject: sub,
      description: json['description'] as String?,
      subjectId: json['subject_id'] is int
          ? json['subject_id'] as int
          : int.tryParse(json['subject_id']?.toString() ?? ''),
      subjectTitle: sub.isNotEmpty ? sub : json['subject_title'] as String?,
      deadline: json['deadline'] as String? ?? '',
      priority: json['priority'] as String? ?? 'Орташа',
      isCompleted: completed,
      isFavorite: json['is_favorite'] == 1 ||
          json['is_favorite'] == true ||
          json['isFavorite'] == true,
      subtasks: (json['subtasks'] as List<dynamic>?)
              ?.map((s) => Subtask.fromMap(s as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  /// Сериализация в JSON (MockAPI / REST API)
  Map<String, dynamic> toJson() {
    final effectiveSubject = subject.isNotEmpty ? subject : (subjectTitle ?? '');
    final map = <String, dynamic>{
      'title': title,
      'subject': effectiveSubject,
      'deadline': deadline,
      'priority': priority,
      'isCompleted': isCompleted,
    };
    if (id.isNotEmpty) {
      map['id'] = id;
    }
    if (description != null && description!.isNotEmpty) {
      map['description'] = description;
    }
    return map;
  }

  /// Для совместимости со SQLite
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'description': description,
      'subject_id': subjectId,
      'deadline': deadline,
      'priority': priority,
      'is_completed': isCompleted ? 1 : 0,
      'is_favorite': isFavorite ? 1 : 0,
    };
    final intId = int.tryParse(id);
    if (intId != null) {
      map['id'] = intId;
    }
    return map;
  }

  /// Для совместимости со SQLite
  factory Task.fromMap(Map<String, dynamic> map) => Task.fromJson(map);

  Task copyWith({
    String? id,
    String? title,
    String? subject,
    String? description,
    int? subjectId,
    String? subjectTitle,
    String? deadline,
    String? priority,
    bool? isCompleted,
    bool? isFavorite,
    List<Subtask>? subtasks,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      subjectId: subjectId ?? this.subjectId,
      subjectTitle: subjectTitle ?? this.subjectTitle,
      deadline: deadline ?? this.deadline,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      isFavorite: isFavorite ?? this.isFavorite,
      subtasks: subtasks ?? this.subtasks,
    );
  }

  static List<String> get availableSubjects => const [
        'Мобильді әзірлеу',
        'Деректер қоры',
        'Ағылшын тілі',
      ];

  static List<Task> get sampleTasks => [
        Task(
          id: '1',
          title: 'Зертханалық жұмыс №4',
          description:
              'PostgreSQL деректер қорында индекстер құру және транзакцияларды оңтайландыру.',
          subject: 'Деректер қоры',
          subjectId: 2,
          subjectTitle: 'Деректер қоры',
          deadline:
              DateTime.now().add(const Duration(days: 2)).toIso8601String(),
          priority: 'Орташа',
          isCompleted: false,
          isFavorite: true,
          subtasks: const [
            Subtask(
                id: 1, taskId: 1, title: 'ER диаграммасын құру', isCompleted: true),
            Subtask(
                id: 2, taskId: 1, title: 'SQL сұраныстар жазу', isCompleted: false),
          ],
        ),
        Task(
          id: '2',
          title: 'Мобильді қосымша ТТ',
          description: 'UniTask қосымшасының техникалық тапсырмасын дайындау.',
          subject: 'Мобильді әзірлеу',
          subjectId: 1,
          subjectTitle: 'Мобильді әзірлеу',
          deadline:
              DateTime.now().add(const Duration(days: 1)).toIso8601String(),
          priority: 'Жоғары',
          isCompleted: false,
          isFavorite: true,
          subtasks: const [
            Subtask(
                id: 3, taskId: 2, title: 'Талаптарды анықтау', isCompleted: true),
            Subtask(
                id: 4, taskId: 2, title: 'Экрандар құрылымын жазу', isCompleted: false),
          ],
        ),
      ];
}
