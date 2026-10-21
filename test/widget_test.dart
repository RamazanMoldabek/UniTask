import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unitask/main.dart';
import 'package:unitask/screens/task_detail_screen.dart';
import 'package:unitask/models/task.dart';

void main() {
  testWidgets('UniTask app smoke test and navigation', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const UniTaskApp());
    await tester.pumpAndSettle();

    // Verify HomeScreen content
    expect(find.text('Сәлем, Рамазан! 👋'), findsOneWidget);
    expect(find.text('Күндік үлгерім'), findsOneWidget);
    expect(find.text('Барлығы'), findsOneWidget);

    // Switch to Calendar tab via NavigationDestination
    await tester.tap(find.widgetWithText(NavigationDestination, 'Күнтізбе'));
    await tester.pumpAndSettle();
    expect(find.text('Күнтізбе мен жоспар'), findsOneWidget);

    // Switch to Profile tab via NavigationDestination
    await tester.tap(find.widgetWithText(NavigationDestination, 'Профиль'));
    await tester.pumpAndSettle();
    expect(find.text('Рамазан Серік'), findsOneWidget);
    expect(find.text('Оқу үлгерімі мен статистика'), findsOneWidget);

    // Toggle dark mode switch
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    // Switch back to Home tab
    await tester.tap(find.widgetWithText(NavigationDestination, 'Тапсырмалар'));
    await tester.pumpAndSettle();

    // Tap on FAB to open AddTaskScreen
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Жаңа тапсырма қосу'), findsOneWidget);
    expect(find.text('Тапсырма атауы'), findsOneWidget);
    expect(find.text('Сақтау'), findsOneWidget);

    // Go back
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Сәлем, Рамазан! 👋'), findsOneWidget);
  });

  testWidgets('TaskDetailScreen smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    final sampleTask = Task.sampleTasks.first;
    await tester.pumpWidget(
      MaterialApp(
        home: TaskDetailScreen(
          task: sampleTask,
          onUpdate: (_) {},
          onDelete: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Тапсырма мәліметі'), findsOneWidget);
    expect(find.text(sampleTask.title), findsOneWidget);
    expect(find.text('Мерзімі (Дедлайн)'), findsOneWidget);
    expect(find.text('Ішкі тапсырмалар (Чек-лист)'), findsOneWidget);
  });
}
