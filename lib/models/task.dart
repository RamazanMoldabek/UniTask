import 'package:flutter/material.dart';

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

class SubTask {
  final String id;
  String title;
  bool isDone;

  SubTask({
    required this.id,
    required this.title,
    this.isDone = false,
  });

  SubTask copyWith({
    String? id,
    String? title,
    bool? isDone,
  }) {
    return SubTask(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
    );
  }
}

class Task {
  final String id;
  final String title;
  final String subject;
  final DateTime deadline;
  final TaskPriority priority;
  final bool isCompleted;
  final String description;
  final List<SubTask> subtasks;

  Task({
    required this.id,
    required this.title,
    required this.subject,
    required this.deadline,
    required this.priority,
    this.isCompleted = false,
    this.description = '',
    List<SubTask>? subtasks,
  }) : subtasks = subtasks ?? [];

  Task copyWith({
    String? id,
    String? title,
    String? subject,
    DateTime? deadline,
    TaskPriority? priority,
    bool? isCompleted,
    String? description,
    List<SubTask>? subtasks,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      deadline: deadline ?? this.deadline,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      description: description ?? this.description,
      subtasks: subtasks ?? this.subtasks.map((s) => s.copyWith()).toList(),
    );
  }

  static List<String> get availableSubjects => const [
        'Мобильді әзірлеу',
        'Деректер қоры',
        'Дискретті математика',
        'Ағылшын тілі',
        'Жоғары математика',
        'Алгоритмдер мен құрылымдар',
      ];

  static List<Task> get sampleTasks {
    return [
      Task(
        id: 'task-1',
        title: 'Зертханалық жұмыс №4',
        subject: 'Деректер қоры',
        deadline: DateTime(2026, 10, 23, 12, 0),
        priority: TaskPriority.medium,
        isCompleted: false,
        description: 'PostgreSQL деректер қорында индекстер құру және транзакцияларды оңтайландыру.',
        subtasks: [
          SubTask(id: 'st-1', title: 'ER диаграммасын құру', isDone: true),
          SubTask(id: 'st-2', title: 'SQL сұраныстар жазу', isDone: false),
        ],
      ),
      Task(
        id: 'task-2',
        title: 'Мобильді қосымша ТТ',
        subject: 'Мобильді әзірлеу',
        deadline: DateTime(2026, 10, 22, 18, 0),
        priority: TaskPriority.high,
        isCompleted: false,
        description:
            'UniTask қосымшасының техникалық тапсырмасын дайындау. Негізгі экрандар мен қолданушы талаптарын сипаттау.',
        subtasks: [
          SubTask(id: 'st-3', title: 'Талаптарды анықтау', isDone: true),
          SubTask(id: 'st-4', title: 'Экрандар құрылымын жазу', isDone: false),
          SubTask(id: 'st-5', title: 'ТТ құжатын тапсыру', isDone: false),
        ],
      ),
      Task(
        id: 'task-3',
        title: 'Эссе жазу',
        subject: 'Ағылшын тілі',
        deadline: DateTime(2026, 10, 20, 15, 0),
        priority: TaskPriority.low,
        isCompleted: true,
        description: 'Academic Writing тақырыбы бойынша 250 сөзден тұратын эссе жазу.',
        subtasks: [
          SubTask(id: 'st-6', title: 'Тезисті таңдау', isDone: true),
          SubTask(id: 'st-7', title: 'Грамматикасын тексеру', isDone: true),
        ],
      ),
      Task(
        id: 'task-4',
        title: 'Есептер жинағы',
        subject: 'Дискретті математика',
        deadline: DateTime(2026, 10, 21, 10, 0),
        priority: TaskPriority.medium,
        isCompleted: true,
        description: 'Графтар теориясы және комбинаторика есептерін шығару.',
        subtasks: [
          SubTask(id: 'st-8', title: '1-10 есептерді шығару', isDone: true),
        ],
      ),
      Task(
        id: 'task-5',
        title: 'Дәріс конспектісі',
        subject: 'Мобильді әзірлеу',
        deadline: DateTime(2026, 10, 19, 14, 0),
        priority: TaskPriority.low,
        isCompleted: true,
        description: 'Flutter Widget lifecycle және State management тақырыптары бойынша конспект.',
        subtasks: [
          SubTask(id: 'st-9', title: 'Негізгі ұғымдарды жазу', isDone: true),
        ],
      ),
    ];
  }
}
