import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unitask/models/task.dart';
import 'package:unitask/utils/validators.dart';
import 'package:unitask/widgets/error_state_view.dart';
import 'package:unitask/widgets/task_card.dart';

void main() {
  group('1. Task.fromJson Parsing Tests', () {
    test('Task.fromJson correctly parses standard incoming JSON from server', () {
      final json = {
        'id': '101',
        'title': 'Flutter Realtime Lab',
        'subject': 'Мобильді әзірлеу',
        'deadline': '2026-11-08T18:00:00.000',
        'priority': 'Жоғары',
        'isCompleted': false,
        'description': 'Implement WebSockets and error views',
      };

      final task = Task.fromJson(json);

      expect(task.id, '101');
      expect(task.title, 'Flutter Realtime Lab');
      expect(task.subject, 'Мобильді әзірлеу');
      expect(task.deadline, '2026-11-08T18:00:00.000');
      expect(task.priority, 'Жоғары');
      expect(task.isCompleted, isFalse);
      expect(task.description, 'Implement WebSockets and error views');
    });

    test('Task.fromJson handles alternate keys and boolean formats (0/1 and strings)', () {
      final jsonWithIntBool = {
        'id': 42,
        'title': 'Alt Task',
        'subject_title': 'Деректер қоры',
        'deadline': '2026-11-09',
        'priority': 'Орташа',
        'is_completed': 1,
      };

      final task = Task.fromJson(jsonWithIntBool);
      expect(task.id, '42');
      expect(task.subject, 'Деректер қоры');
      expect(task.isCompleted, isTrue);
    });
  });

  group('2. Task.toJson Serialization Tests', () {
    test('Task.toJson serializes object to server-ready JSON map', () {
      const task = Task(
        id: '202',
        title: 'Submit Homework',
        subject: 'Ағылшын тілі',
        deadline: '2026-11-10T12:00:00.000',
        priority: 'Төмен',
        isCompleted: true,
        description: 'Upload essay to portal',
      );

      final json = task.toJson();

      expect(json['id'], '202');
      expect(json['title'], 'Submit Homework');
      expect(json['subject'], 'Ағылшын тілі');
      expect(json['deadline'], '2026-11-10T12:00:00.000');
      expect(json['priority'], 'Төмен');
      expect(json['isCompleted'], isTrue);
      expect(json['description'], 'Upload essay to portal');
    });

    test('Task.toJson omits empty id for new task creations', () {
      const newTask = Task(
        title: 'Brand New Task',
        subject: 'Жалпы',
        deadline: '2026-11-11',
        priority: 'Жоғары',
        isCompleted: false,
      );

      final json = newTask.toJson();
      expect(json.containsKey('id'), isFalse);
      expect(json['title'], 'Brand New Task');
      expect(json['isCompleted'], isFalse);
    });
  });

  group('3. Task Priority Filtering Tests', () {
    final sampleTasks = [
      const Task(
        id: '1',
        title: 'Task Urgent 1',
        deadline: '2026-11-09',
        priority: 'Жоғары',
        isCompleted: false,
      ),
      const Task(
        id: '2',
        title: 'Task Medium 2',
        deadline: '2026-11-09',
        priority: 'Орташа',
        isCompleted: false,
      ),
      const Task(
        id: '3',
        title: 'Task Low 3',
        deadline: '2026-11-10',
        priority: 'Төмен',
        isCompleted: true,
      ),
      const Task(
        id: '4',
        title: 'Task Urgent 4',
        deadline: '2026-11-11',
        priority: 'Жоғары',
        isCompleted: true,
      ),
    ];

    test('Filters tasks by "Шұғыл" (Urgent / priority == Жоғары)', () {
      final urgentTasks =
          sampleTasks.where((t) => t.priority == 'Жоғары').toList();
      expect(urgentTasks.length, 2);
      expect(urgentTasks.every((t) => t.priority == 'Жоғары'), isTrue);
      expect(urgentTasks.map((t) => t.id), containsAll(['1', '4']));
    });

    test('Filters active (in-progress) tasks and applies urgent filter', () {
      final activeUrgentTasks = sampleTasks
          .where((t) => !t.isCompleted && t.priority == 'Жоғары')
          .toList();
      expect(activeUrgentTasks.length, 1);
      expect(activeUrgentTasks.first.id, '1');
    });

    test('Returns all tasks when filter is "Барлығы"', () {
      bool filterOnlyUrgent = false;
      List<Task> filterTasks(bool onlyUrgent) {
        return sampleTasks.where((t) {
          if (onlyUrgent) return t.priority == 'Жоғары';
          return true;
        }).toList();
      }

      expect(filterTasks(filterOnlyUrgent).length, 4);
      filterOnlyUrgent = true;
      expect(filterTasks(filterOnlyUrgent).length, 2);
    });
  });

  group('4. Input Validation Tests (Email & Task Title)', () {
    test('Validates email format correctly', () {
      // Valid emails
      expect(Validators.validateEmail('student@aitu.kz'), isNull);
      expect(Validators.validateEmail('ramazan.m@gmail.com'), isNull);
      expect(Validators.validateEmail('test.user+tag@domain.co'), isNull);

      // Invalid emails
      expect(Validators.validateEmail(null), 'Электрондық поштаны енгізіңіз');
      expect(Validators.validateEmail(''), 'Электрондық поштаны енгізіңіз');
      expect(Validators.validateEmail('   '), 'Электрондық поштаны енгізіңіз');
      expect(Validators.validateEmail('plainaddress'),
          'Электрондық пошта пішімі қате (мысалы: user@aitu.kz)');
      expect(Validators.validateEmail('missingatsign.com'),
          'Электрондық пошта пішімі қате (мысалы: user@aitu.kz)');
      expect(Validators.validateEmail('@missingusername.com'),
          'Электрондық пошта пішімі қате (мысалы: user@aitu.kz)');
    });

    test('Validates non-empty task title and minimum length', () {
      // Valid titles
      expect(Validators.validateTaskTitle('Math HW'), isNull);
      expect(Validators.validateTaskTitle('Практикалық жұмыс №6'), isNull);

      // Invalid titles
      expect(Validators.validateTaskTitle(null), 'Тапсырма атауын енгізіңіз');
      expect(Validators.validateTaskTitle(''), 'Тапсырма атауын енгізіңіз');
      expect(Validators.validateTaskTitle('  '), 'Тапсырма атауын енгізіңіз');
      expect(Validators.validateTaskTitle('ab'),
          'Атау кемінде 3 таңбадан тұруы керек');
    });

    test('Validates registration fields (full name, university, password)', () {
      expect(Validators.validateFullName('Рамазан'), isNull);
      expect(Validators.validateFullName(''), 'Аты-жөніңізді енгізіңіз');
      expect(Validators.validateFullName('А'),
          'Аты-жөні кемінде 2 таңбадан тұруы керек');

      expect(Validators.validateUniversity('AITU'), isNull);
      expect(Validators.validateUniversity(''), 'Оқу орнын енгізіңіз');

      expect(Validators.validatePassword('password123'), isNull);
      expect(Validators.validatePassword(''), 'Құпиясөзді енгізіңіз');
      expect(Validators.validatePassword('1234567'),
          'Құпиясөз кемінде 8 таңбадан тұруы керек');
      expect(Validators.validatePassword('12345678'),
          'Құпиясөзде кемінде 1 әріп және 1 цифр болуы керек');
      expect(Validators.validatePassword('abcdefgh'),
          'Құпиясөзде кемінде 1 әріп және 1 цифр болуы керек');
    });
  });

  group('5. Widget Tests for Key UI Elements', () {
    testWidgets('TaskCard renders title, subject, priority tag and triggers toggle',
        (WidgetTester tester) async {
      bool toggled = false;
      bool tapped = false;

      final testTask = Task(
        id: '99',
        title: 'Widget Test Task',
        subject: 'Мобильді әзірлеу',
        deadline: DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        priority: 'Жоғары',
        isCompleted: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskCard(
              task: testTask,
              onToggle: () => toggled = true,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // Verify task details are rendered
      expect(find.text('Widget Test Task'), findsOneWidget);
      expect(find.text('Мобильді әзірлеу'), findsOneWidget);
      expect(find.text('Жоғары'), findsOneWidget);

      // Tap on card
      await tester.tap(find.text('Widget Test Task'));
      expect(tapped, isTrue);

      // Tap on checkbox
      await tester.tap(find.byKey(const Key('task_card_checkbox')));
      expect(toggled, isTrue);
    });

    testWidgets('ErrorStateView renders 404 and Disconnect states with action button',
        (WidgetTester tester) async {
      bool retryClicked = false;

      // 1. Test 404 Not Found view
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorStateView.notFound(
              onRetry: () => retryClicked = true,
            ),
          ),
        ),
      );

      expect(find.text('404 - Бет немесе дерек табылмады'), findsOneWidget);
      expect(find.text('Басты бетке оралу'), findsOneWidget);

      await tester.tap(find.text('Басты бетке оралу'));
      expect(retryClicked, isTrue);

      // 2. Test Disconnect / No Internet view
      bool reconnectClicked = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorStateView.noInternet(
              onRetry: () => reconnectClicked = true,
            ),
          ),
        ),
      );

      expect(find.text('Сервермен байланыс жоқ'), findsOneWidget);
      expect(find.text('Қайталау'), findsOneWidget);

      await tester.tap(find.text('Қайталау'));
      expect(reconnectClicked, isTrue);
    });
  });
}
