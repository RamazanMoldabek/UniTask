import 'package:flutter_test/flutter_test.dart';
import 'package:unitask/models/task.dart';
import 'package:unitask/services/api_service.dart';

void main() {
  group('Task Model JSON serialization', () {
    test('Task converts to and from JSON correctly', () {
      final json = {
        'id': '10',
        'title': 'Test REST Task',
        'subject': 'Мобильді әзірлеу',
        'deadline': '2026-11-04T12:00:00.000',
        'priority': 'Жоғары',
        'isCompleted': true,
      };

      final task = Task.fromJson(json);

      expect(task.id, '10');
      expect(task.title, 'Test REST Task');
      expect(task.subject, 'Мобильді әзірлеу');
      expect(task.deadline, '2026-11-04T12:00:00.000');
      expect(task.priority, 'Жоғары');
      expect(task.isCompleted, true);

      final convertedJson = task.toJson();
      expect(convertedJson['id'], '10');
      expect(convertedJson['title'], 'Test REST Task');
      expect(convertedJson['subject'], 'Мобильді әзірлеу');
      expect(convertedJson['deadline'], '2026-11-04T12:00:00.000');
      expect(convertedJson['priority'], 'Жоғары');
      expect(convertedJson['isCompleted'], true);
    });

    test('Task handles boolean variants and null id gracefully', () {
      final json = {
        'title': 'No ID Task',
        'subject': 'Деректер қоры',
        'deadline': '2026-11-05',
        'priority': 'Орташа',
        'isCompleted': false,
      };

      final task = Task.fromJson(json);
      expect(task.id, '');
      expect(task.isCompleted, false);

      final toJsonResult = task.toJson();
      expect(toJsonResult.containsKey('id'), false); // newly created tasks don't send empty id
      expect(toJsonResult['title'], 'No ID Task');
      expect(toJsonResult['isCompleted'], false);
    });
  });

  group('ApiService Configuration', () {
    test('baseUrl matches production endpoint', () {
      expect(
        ApiService.baseUrl,
        'https://unitask-6er3.onrender.com/tasks',
      );
    });

    test('timeoutDuration is 10 seconds', () {
      expect(ApiService.timeoutDuration.inSeconds, 10);
    });
  });
}

