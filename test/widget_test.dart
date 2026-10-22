import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unitask/main.dart';
import 'package:unitask/screens/task_detail_screen.dart';
import 'package:unitask/models/task.dart';

void main() {
  testWidgets('UniTask app smoke test and 5-tab navigation', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const UniTaskApp());
    // Splash screen runs for 1800ms
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();

    // Verify HomeScreen content
    expect(find.text('Сәлем, Рамазан!'), findsOneWidget);
    expect(find.text('Осы аптадағы жетістік'), findsOneWidget);
    expect(find.text('Барлығы'), findsOneWidget);
    expect(find.text('Шұғыл'), findsOneWidget);

    // Switch to Tasks tab
    await tester.tap(find.text('Тапсырмалар'));
    await tester.pumpAndSettle();
    expect(find.text('Тапсырманы іздеу'), findsOneWidget);

    // Switch to Calendar tab (Kept in bottom navbar as user requested!)
    await tester.tap(find.text('Күнтізбе'));
    await tester.pumpAndSettle();
    expect(find.text('Бүгін'), findsOneWidget);

    // Switch to Search tab
    await tester.tap(find.text('Іздеу'));
    await tester.pumpAndSettle();
    expect(find.text('Соңғы іздеулер'), findsOneWidget);

    // Switch to Profile tab
    await tester.tap(find.text('Профиль'));
    await tester.pumpAndSettle();
    expect(find.text('Рамазан Т.'), findsOneWidget);
    expect(find.text('Қараңғы режим'), findsOneWidget);

    // Toggle dark mode switch
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    // Switch back to Home tab
    await tester.tap(find.text('Басты'));
    await tester.pumpAndSettle();
    expect(find.text('Сәлем, Рамазан!'), findsOneWidget);
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

    expect(find.text('Тапсырма'), findsOneWidget);
    expect(find.text(sampleTask.title), findsOneWidget);
    expect(find.text('Тапсыру мерзімі'), findsOneWidget);
    expect(find.text('Өңдеу'), findsOneWidget);
    expect(find.text('Жою'), findsOneWidget);
  });
}
