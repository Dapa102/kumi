import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumi/core/models/models.dart';
import 'package:kumi/shared/widgets/achievement_tile.dart';
import 'package:kumi/shared/widgets/daily_progress_bar.dart';
import 'package:kumi/shared/widgets/task_card.dart';

void main() {
  testWidgets('TaskCard shows strikethrough when completed', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskCard(
            task: TaskItem(
              id: 1,
              title: 'Belajar',
              dueTime: DateTime.now().add(const Duration(hours: 2)),
              isCompleted: true,
            ),
            onToggle: () {},
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('Belajar'));
    expect(text.style?.decoration, TextDecoration.lineThrough);
  });

  testWidgets('TaskCard toggle button fires callback', (tester) async {
    var toggled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskCard(
            task: TaskItem(
              id: 2,
              title: 'Olahraga',
              dueTime: DateTime.now().add(const Duration(hours: 1)),
              isCompleted: false,
            ),
            onToggle: () => toggled = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Selesai'));
    expect(toggled, isTrue);
  });

  testWidgets('DailyProgressBar shows completed over total', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DailyProgressBar(completed: 2, total: 5)),
      ),
    );

    expect(find.text('2 / 5'), findsOneWidget);
    await tester.pumpAndSettle();
    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, closeTo(0.4, 0.001));
  });

  testWidgets('AchievementTile shows lock when not earned', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AchievementTile(
            achievement: Achievement(
              id: 1,
              code: 'streak_7',
              name: 'Seminggu Konsisten',
              description: 'Streak 7 hari',
              icon: 'badge_fire7',
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
  });
}
