import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flashcard_quiz_app/main.dart';

void main() {
  setUp(() {});

  testWidgets(
    '1. Home screen displays question, reveals answer, hides answer, and navigates',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const FlashcardApp());
      await tester.pumpAndSettle();

      // Check title and first card
      expect(find.text('FLASHCARD QUIZ'), findsWidgets);
      expect(find.text('What is Flutter?'), findsOneWidget);
      expect(find.text('Show Answer'), findsOneWidget);
      expect(find.text('Card 1 of 7'), findsOneWidget);

      // Answer text is not visible initially
      expect(
        find.textContaining("Flutter is Google's UI toolkit"),
        findsNothing,
      );

      // Reveal answer
      await tester.tap(find.text('Show Answer'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining("Flutter is Google's UI toolkit"),
        findsOneWidget,
      );
      expect(find.text('Hide Answer'), findsOneWidget);
      expect(find.text('Did you recall this correctly?'), findsOneWidget);

      // Hide answer
      await tester.ensureVisible(find.text('Hide Answer'));
      await tester.tap(find.text('Hide Answer'));
      await tester.pumpAndSettle();

      expect(find.text('Show Answer'), findsOneWidget);

      // Navigate Next
      await tester.ensureVisible(find.text('Next'));
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(
        find.text('What is the purpose of StatefulWidget in Flutter?'),
        findsOneWidget,
      );
      expect(find.text('Card 2 of 7'), findsOneWidget);

      // Navigate Previous
      await tester.ensureVisible(find.text('Previous'));
      await tester.tap(find.text('Previous'));
      await tester.pumpAndSettle();

      expect(find.text('What is Flutter?'), findsOneWidget);
      expect(find.text('Card 1 of 7'), findsOneWidget);
    },
  );

  testWidgets(
    '2. Form validation prevents empty question and answer submission',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const FlashcardApp());
      await tester.pumpAndSettle();

      // Tap FAB to open Add Flashcard screen
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Create Flashcard'), findsOneWidget);
      expect(find.text('Save Flashcard'), findsOneWidget);

      // Attempt to save empty form
      await tester.tap(find.text('Save Flashcard'));
      await tester.pumpAndSettle();

      // Validation errors should appear
      expect(find.text('Question cannot be empty'), findsOneWidget);
      expect(find.text('Answer cannot be empty'), findsOneWidget);

      // Type question and answer
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'What is Dart?');
      await tester.enterText(
        textFields.at(1),
        'Dart is an object-oriented programming language.',
      );
      await tester.pumpAndSettle();

      // Save valid flashcard
      await tester.tap(find.text('Save Flashcard'));
      await tester.pumpAndSettle();

      // Returned to home screen with 8 cards now
      expect(find.text('Create Flashcard'), findsNothing);
      expect(find.text('Card 1 of 8'), findsOneWidget);
    },
  );

  testWidgets('3. Edit existing flashcard updates the card data', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const FlashcardApp());
    await tester.pumpAndSettle();

    // Tap Edit button on card 1
    await tester.tap(find.byTooltip('Edit Flashcard'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Flashcard'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);

    // Update question text
    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), 'What is Flutter Framework?');
    await tester.pumpAndSettle();

    // Tap Save Changes
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    // Returned to Home screen, updated question displayed
    expect(find.text('What is Flutter Framework?'), findsOneWidget);
  });

  testWidgets('4. Delete card shows confirmation dialog and safe deletion', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const FlashcardApp());
    await tester.pumpAndSettle();

    // Initial card count is 7
    expect(find.text('Card 1 of 7'), findsOneWidget);

    // Tap Delete button
    await tester.tap(find.byTooltip('Delete Flashcard'));
    await tester.pumpAndSettle();

    // Confirmation dialog appears
    expect(find.text('Delete Flashcard?'), findsOneWidget);
    expect(
      find.text(
        'Are you sure you want to delete this flashcard? This action cannot be undone.',
      ),
      findsOneWidget,
    );
    expect(find.text('TARGET ITEM'), findsOneWidget);

    // Test Cancel button dismisses dialog without deleting
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Card 1 of 7'), findsOneWidget);

    // Open delete dialog again
    await tester.tap(find.byTooltip('Delete Flashcard'));
    await tester.pumpAndSettle();

    // Confirm delete
    await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
    await tester.pumpAndSettle();

    // Card is deleted, deck now has 6 cards
    expect(find.text('Card 1 of 6'), findsOneWidget);
    expect(find.text('Flashcard deleted successfully'), findsOneWidget);
  });
}
