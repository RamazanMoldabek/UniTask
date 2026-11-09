import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/subject.dart';
import '../models/task.dart';
import '../models/user_profile.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('unitask.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite is not supported on web.');
    }
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onConfigure: _onConfigure,
      onCreate: _createDB,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON;');
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Subjects table
    await db.execute('''
      CREATE TABLE subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        color_hex TEXT NOT NULL
      )
    ''');

    // 2. Tasks table
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        subject_id INTEGER,
        deadline TEXT NOT NULL,
        priority TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE SET NULL
      )
    ''');

    // 3. Subtasks table
    await db.execute('''
      CREATE TABLE subtasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE CASCADE
      )
    ''');

    // 4. User profile table
    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        university TEXT NOT NULL,
        email TEXT NOT NULL
      )
    ''');

    // Seed Data
    await _seedData(db);
  }

  Future<void> _seedData(Database db) async {
    // Insert initial subjects
    final sub1Id = await db.insert('subjects', {
      'title': 'Мобильді әзірлеу',
      'color_hex': '#4F46E5',
    });
    final sub2Id = await db.insert('subjects', {
      'title': 'Деректер қоры',
      'color_hex': '#0EA5E9',
    });
    final sub3Id = await db.insert('subjects', {
      'title': 'Ағылшын тілі',
      'color_hex': '#10B981',
    });

    final now = DateTime.now();

    // Task 1: Деректер қоры
    final task1Id = await db.insert('tasks', {
      'title': 'Зертханалық жұмыс №4',
      'description':
          'PostgreSQL деректер қорында индекстер құру және транзакцияларды оңтайландыру.',
      'subject_id': sub2Id,
      'deadline':
          DateTime(now.year, now.month, now.day + 2, 12, 0).toIso8601String(),
      'priority': 'Орташа',
      'is_completed': 0,
      'is_favorite': 1,
    });
    await db.insert('subtasks', {
      'task_id': task1Id,
      'title': 'ER диаграммасын құру',
      'is_completed': 1,
    });
    await db.insert('subtasks', {
      'task_id': task1Id,
      'title': 'SQL сұраныстар жазу',
      'is_completed': 0,
    });

    // Task 2: Мобильді әзірлеу
    final task2Id = await db.insert('tasks', {
      'title': 'Мобильді қосымша ТТ',
      'description':
          'UniTask қосымшасының техникалық тапсырмасын дайындау. Негізгі экрандар мен қолданушы талаптарын сипаттау.',
      'subject_id': sub1Id,
      'deadline':
          DateTime(now.year, now.month, now.day + 1, 18, 0).toIso8601String(),
      'priority': 'Жоғары',
      'is_completed': 0,
      'is_favorite': 1,
    });
    await db.insert('subtasks', {
      'task_id': task2Id,
      'title': 'Талаптарды анықтау',
      'is_completed': 1,
    });
    await db.insert('subtasks', {
      'task_id': task2Id,
      'title': 'Экрандар құрылымын жазу',
      'is_completed': 0,
    });
    await db.insert('subtasks', {
      'task_id': task2Id,
      'title': 'ТТ құжатын тапсыру',
      'is_completed': 0,
    });

    // Task 3: Ағылшын тілі
    final task3Id = await db.insert('tasks', {
      'title': 'Academic Writing эссе',
      'description': 'Academic Writing тақырыбы бойынша 250 сөзден тұратын эссе жазу.',
      'subject_id': sub3Id,
      'deadline':
          DateTime(now.year, now.month, now.day - 1, 15, 0).toIso8601String(),
      'priority': 'Төмен',
      'is_completed': 1,
      'is_favorite': 0,
    });
    await db.insert('subtasks', {
      'task_id': task3Id,
      'title': 'Тезисті таңдау',
      'is_completed': 1,
    });
    await db.insert('subtasks', {
      'task_id': task3Id,
      'title': 'Грамматикасын тексеру',
      'is_completed': 1,
    });

    // Seed User Profile
    await db.insert('user_profile', {
      'full_name': 'Рамазан Молдабек',
      'university': 'AITU',
      'email': 'ramazan@unitask.kz',
    });
  }

  // ================= SUBJECTS CRUD =================
  Future<int> insertSubject(Subject subject) async {
    final db = await database;
    return await db.insert(
      'subjects',
      subject.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Subject>> getSubjects() async {
    if (kIsWeb) {
      return const [
        Subject(id: 1, title: 'Мобильді әзірлеу', colorHex: '#6366F1'),
        Subject(id: 2, title: 'Деректер қоры', colorHex: '#0EA5E9'),
        Subject(id: 3, title: 'Ағылшын тілі', colorHex: '#10B981'),
      ];
    }
    try {
      final db = await database;
      final maps = await db.query('subjects', orderBy: 'title ASC');
      return maps.map((m) => Subject.fromMap(m)).toList();
    } catch (_) {
      return const [
        Subject(id: 1, title: 'Мобильді әзірлеу', colorHex: '#6366F1'),
        Subject(id: 2, title: 'Деректер қоры', colorHex: '#0EA5E9'),
        Subject(id: 3, title: 'Ағылшын тілі', colorHex: '#10B981'),
      ];
    }
  }

  Future<Subject?> getSubjectById(int id) async {
    final db = await database;
    final maps = await db.query(
      'subjects',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Subject.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateSubject(Subject subject) async {
    final db = await database;
    return await db.update(
      'subjects',
      subject.toMap(),
      where: 'id = ?',
      whereArgs: [subject.id],
    );
  }

  Future<int> deleteSubject(int id) async {
    final db = await database;
    return await db.delete(
      'subjects',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ================= TASKS CRUD =================
  Future<int> insertTask(Task task) async {
    final db = await database;
    final taskId = await db.insert('tasks', task.toMap());

    // Insert subtasks if any
    if (task.subtasks.isNotEmpty) {
      final batch = db.batch();
      for (final st in task.subtasks) {
        batch.insert('subtasks', {
          'task_id': taskId,
          'title': st.title,
          'is_completed': st.isCompleted ? 1 : 0,
        });
      }
      await batch.commit(noResult: true);
    }

    return taskId;
  }

  Future<List<Task>> getTasks({
    String? priority,
    bool? isCompleted,
    String? sortBy,
    String? subjectTitle,
  }) async {
    final db = await database;

    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (priority != null && priority.isNotEmpty) {
      whereClauses.add('tasks.priority = ?');
      whereArgs.add(priority);
    }

    if (isCompleted != null) {
      whereClauses.add('tasks.is_completed = ?');
      whereArgs.add(isCompleted ? 1 : 0);
    }

    if (subjectTitle != null && subjectTitle.isNotEmpty) {
      whereClauses.add('subjects.title = ?');
      whereArgs.add(subjectTitle);
    }

    String orderByClause;
    if (sortBy == 'priority') {
      orderByClause = '''
        CASE tasks.priority 
          WHEN 'Жоғары' THEN 1 
          WHEN 'Орташа' THEN 2 
          WHEN 'Төмен' THEN 3 
          ELSE 4 
        END ASC, tasks.deadline ASC
      ''';
    } else if (sortBy == 'deadline') {
      orderByClause = 'tasks.deadline ASC';
    } else {
      orderByClause = 'tasks.is_completed ASC, tasks.deadline ASC';
    }

    final whereString =
        whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';

    final query = '''
      SELECT 
        tasks.id,
        tasks.title,
        tasks.description,
        tasks.subject_id,
        subjects.title AS subject_title,
        subjects.color_hex AS subject_color_hex,
        tasks.deadline,
        tasks.priority,
        tasks.is_completed,
        tasks.is_favorite
      FROM tasks
      LEFT JOIN subjects ON tasks.subject_id = subjects.id
      $whereString
      ORDER BY $orderByClause
    ''';

    final result = await db.rawQuery(query, whereArgs);

    final tasks = <Task>[];
    for (final map in result) {
      final taskId = map['id'] as int;
      final subtasks = await getSubtasks(taskId);
      final task = Task.fromMap(map).copyWith(subtasks: subtasks);
      tasks.add(task);
    }

    return tasks;
  }

  Future<Task?> getTaskById(int id) async {
    final db = await database;
    final query = '''
      SELECT 
        tasks.id,
        tasks.title,
        tasks.description,
        tasks.subject_id,
        subjects.title AS subject_title,
        subjects.color_hex AS subject_color_hex,
        tasks.deadline,
        tasks.priority,
        tasks.is_completed,
        tasks.is_favorite
      FROM tasks
      LEFT JOIN subjects ON tasks.subject_id = subjects.id
      WHERE tasks.id = ?
      LIMIT 1
    ''';

    final result = await db.rawQuery(query, [id]);
    if (result.isNotEmpty) {
      final subtasks = await getSubtasks(id);
      return Task.fromMap(result.first).copyWith(subtasks: subtasks);
    }
    return null;
  }

  Future<List<Task>> getFavorites() async {
    final db = await database;
    final query = '''
      SELECT 
        tasks.id,
        tasks.title,
        tasks.description,
        tasks.subject_id,
        subjects.title AS subject_title,
        subjects.color_hex AS subject_color_hex,
        tasks.deadline,
        tasks.priority,
        tasks.is_completed,
        tasks.is_favorite
      FROM tasks
      LEFT JOIN subjects ON tasks.subject_id = subjects.id
      WHERE tasks.is_favorite = 1
      ORDER BY tasks.is_completed ASC, tasks.deadline ASC
    ''';

    final result = await db.rawQuery(query);
    final tasks = <Task>[];
    for (final map in result) {
      final taskId = map['id'] as int;
      final subtasks = await getSubtasks(taskId);
      tasks.add(Task.fromMap(map).copyWith(subtasks: subtasks));
    }
    return tasks;
  }

  Future<int> updateTask(Task task) async {
    final db = await database;
    final rowsAffected = await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );

    // Synchronize subtasks
    if (task.id.isNotEmpty) {
      await db.delete(
        'subtasks',
        where: 'task_id = ?',
        whereArgs: [task.id],
      );
      if (task.subtasks.isNotEmpty) {
        final batch = db.batch();
        for (final st in task.subtasks) {
          batch.insert('subtasks', {
            'task_id': task.id,
            'title': st.title,
            'is_completed': st.isCompleted ? 1 : 0,
          });
        }
        await batch.commit(noResult: true);
      }
    }

    return rowsAffected;
  }

  Future<int> toggleTaskCompletion(int id, bool isCompleted) async {
    final db = await database;
    return await db.update(
      'tasks',
      {'is_completed': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> toggleFavorite(int id, bool isFavorite) async {
    final db = await database;
    return await db.update(
      'tasks',
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ================= SEARCH & FILTER =================
  Future<List<Task>> searchTasks(
    String query, {
    String? priority,
    bool? isCompleted,
  }) async {
    if (kIsWeb) return [];
    try {
      final db = await database;
      final trimmed = query.trim();

      final whereClauses = <String>[];
      final whereArgs = <dynamic>[];

      if (trimmed.isNotEmpty) {
        whereClauses.add(
          '(tasks.title LIKE ? OR tasks.description LIKE ? OR subjects.title LIKE ?)',
        );
        final pattern = '%$trimmed%';
        whereArgs.addAll([pattern, pattern, pattern]);
      }

      if (priority != null && priority.isNotEmpty) {
        whereClauses.add('tasks.priority = ?');
        whereArgs.add(priority);
      }

      if (isCompleted != null) {
        whereClauses.add('tasks.is_completed = ?');
        whereArgs.add(isCompleted ? 1 : 0);
      }

      final whereString =
          whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';

      final sql = '''
        SELECT 
          tasks.id,
          tasks.title,
          tasks.description,
          tasks.subject_id,
          subjects.title AS subject_title,
          subjects.color_hex AS subject_color_hex,
          tasks.deadline,
          tasks.priority,
          tasks.is_completed,
          tasks.is_favorite
        FROM tasks
        LEFT JOIN subjects ON tasks.subject_id = subjects.id
        $whereString
        ORDER BY tasks.is_completed ASC, tasks.deadline ASC
      ''';

      final result = await db.rawQuery(sql, whereArgs);
      final tasks = <Task>[];
      for (final map in result) {
        final taskId = map['id'] as int;
        final subtasks = await getSubtasks(taskId);
        tasks.add(Task.fromMap(map).copyWith(subtasks: subtasks));
      }
      return tasks;
    } catch (_) {
      return [];
    }
  }

  // ================= SUBTASKS CRUD =================
  Future<List<Subtask>> getSubtasks(int taskId) async {
    final db = await database;
    final maps = await db.query(
      'subtasks',
      where: 'task_id = ?',
      whereArgs: [taskId],
      orderBy: 'id ASC',
    );
    return maps.map((m) => Subtask.fromMap(m)).toList();
  }

  Future<int> insertSubtask(Subtask subtask) async {
    final db = await database;
    return await db.insert('subtasks', subtask.toMap());
  }

  Future<int> updateSubtask(Subtask subtask) async {
    final db = await database;
    return await db.update(
      'subtasks',
      subtask.toMap(),
      where: 'id = ?',
      whereArgs: [subtask.id],
    );
  }

  Future<int> toggleSubtaskCompletion(int id, bool isCompleted) async {
    final db = await database;
    return await db.update(
      'subtasks',
      {'is_completed': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteSubtask(int id) async {
    final db = await database;
    return await db.delete(
      'subtasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ================= USER PROFILE CRUD =================
  Future<UserProfile?> getUserProfile() async {
    final db = await database;
    final maps = await db.query('user_profile', limit: 1);
    if (maps.isNotEmpty) {
      return UserProfile.fromMap(maps.first);
    }
    return null;
  }

  Future<int> saveUserProfile(UserProfile profile) async {
    final db = await database;
    final existing = await getUserProfile();
    if (existing == null) {
      return await db.insert('user_profile', profile.toMap());
    } else {
      return await db.update(
        'user_profile',
        profile.toMap(),
        where: 'id = ?',
        whereArgs: [existing.id],
      );
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
