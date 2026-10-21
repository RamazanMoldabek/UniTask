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
        return 'Шұғыл';
    }
  }

  Color get color {
    switch (this) {
      case TaskPriority.low:
        return const Color(0xFF10B981); // Emerald Green
      case TaskPriority.medium:
        return const Color(0xFFF59E0B); // Amber Orange
      case TaskPriority.high:
        return const Color(0xFFEF4444); // Rose Red
    }
  }

  Color get backgroundColor {
    switch (this) {
      case TaskPriority.low:
        return const Color(0xFFECFDF5);
      case TaskPriority.medium:
        return const Color(0xFFFFFBEB);
      case TaskPriority.high:
        return const Color(0xFFFEF2F2);
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
        'Жоғары математика',
        'Алгоритмдер мен құрылымдар',
        'Компьютерлік желілер',
        'Жасанды интеллект',
        'Ағылшын тілі',
      ];

  static List<Task> get sampleTasks {
    final now = DateTime.now();
    return [
      Task(
        id: 'task-1',
        title: 'Flutter қосымшасының UI интерфейсін тапсыру',
        subject: 'Мобильді әзірлеу',
        deadline: DateTime(now.year, now.month, now.day, 18, 0),
        priority: TaskPriority.high,
        isCompleted: false,
        description:
            'UniTask қосымшасының басты экраны, күнтізбесі мен тапсырма қосу беттерін толық әзірлеп, репозиторийге жүктеу.',
        subtasks: [
          SubTask(id: 'st-1', title: 'Figma макеті бойынша компоненттер жасау', isDone: true),
          SubTask(id: 'st-2', title: 'Material 3 тақырыбын баптау', isDone: true),
          SubTask(id: 'st-3', title: 'Фильтрлер мен іздеуді тестілеу', isDone: false),
        ],
      ),
      Task(
        id: 'task-2',
        title: 'SQL күрделі сұраныстары бойынша зертханалық жұмыс',
        subject: 'Деректер қоры',
        deadline: DateTime(now.year, now.month, now.day + 1, 23, 59),
        priority: TaskPriority.medium,
        isCompleted: false,
        description:
            'PostgreSQL-де JOIN, GROUP BY және Indexing қолданып, үлкен кестелерге оңтайландырылған сұраныстар жазу.',
        subtasks: [
          SubTask(id: 'st-4', title: 'ER диаграммасын тексеру', isDone: true),
          SubTask(id: 'st-5', title: 'EXPLAIN ANALYZE арқылы жылдамдықты тексеру', isDone: false),
        ],
      ),
      Task(
        id: 'task-3',
        title: 'Дифференциалдық теңдеулер есептерін шығару',
        subject: 'Жоғары математика',
        deadline: DateTime(now.year, now.month, now.day + 2, 14, 30),
        priority: TaskPriority.low,
        isCompleted: false,
        description:
            'Коши есебі және 2-ретті сызықты біртектес емес теңдеулерді Лагранж әдісімен шығару (№14 нұсқа).',
        subtasks: [
          SubTask(id: 'st-6', title: '1-5 есептерді шығару', isDone: false),
          SubTask(id: 'st-7', title: 'Таза дәптерге көшіру', isDone: false),
        ],
      ),
      Task(
        id: 'task-4',
        title: 'Ағаштар мен графтар бойынша Midterm емтиханы',
        subject: 'Алгоритмдер мен құрылымдар',
        deadline: DateTime(now.year, now.month, now.day, 10, 0),
        priority: TaskPriority.high,
        isCompleted: true,
        description:
            'DFS, BFS, Дейкстра алгоритмдері және қызыл-қара ағаштарды баланстау сұрақтарына дайындық.',
        subtasks: [
          SubTask(id: 'st-8', title: 'Дәріс конспектілерін қайталау', isDone: true),
          SubTask(id: 'st-9', title: 'LeetCode-та 5 есеп талдау', isDone: true),
        ],
      ),
      Task(
        id: 'task-5',
        title: 'Cisco Packet Tracer желі топологиясын құру',
        subject: 'Компьютерлік желілер',
        deadline: DateTime(now.year, now.month, now.day + 3, 20, 0),
        priority: TaskPriority.medium,
        isCompleted: true,
        description:
            'VLAN, OSPF бағыттау хаттамасын және DHCP серверін баптап, жұмыс есебін PDF ретінде өткізу.',
        subtasks: [
          SubTask(id: 'st-10', title: 'IP адресация кестесін құру', isDone: true),
          SubTask(id: 'st-11', title: 'Маршрутизаторларды баптау', isDone: true),
        ],
      ),
    ];
  }
}
