import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veliq/features/capture/selection_overlay.dart';

void main() {
  group('RegionSelectionOverlay Widget Tests', () {
    testWidgets('renders RegionSelectionOverlay widget', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: RegionSelectionOverlay(onRectSelected: (_) {})),
        ),
      );

      expect(find.byType(RegionSelectionOverlay), findsOneWidget);
    });

    testWidgets('dragging triggers onRectSelected with correct Rect', (
      WidgetTester tester,
    ) async {
      Rect? selectedRect;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: RegionSelectionOverlay(
                onRectSelected: (rect) {
                  selectedRect = rect;
                },
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(const Offset(100, 100));
      await tester.pump();

      await gesture.moveTo(const Offset(300, 200));
      await tester.pump();

      await gesture.up();
      await tester.pump();

      expect(selectedRect, isNotNull);
      expect(selectedRect, equals(const Rect.fromLTRB(100, 100, 300, 200)));
    });

    testWidgets('pressing ESC key triggers onCancelled callback', (
      WidgetTester tester,
    ) async {
      bool cancelled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RegionSelectionOverlay(
              onRectSelected: (_) {},
              onCancelled: () {
                cancelled = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(cancelled, isTrue);
    });
  });
}
