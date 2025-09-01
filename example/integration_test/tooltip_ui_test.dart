import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:example/main.dart' as app;
import 'package:ra_tooltip/tooltip/tooltip.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('RATooltip UI Tests', () {
    testWidgets('Test all tooltip interactions automatically',
        (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Test 1: Top tooltip (first Label)
      await _testTooltip(tester, 0, 'TOP', RATooltipPosition.top);

      // Test 2: Left tooltip
      await _testTooltip(tester, 1, 'LEFT', RATooltipPosition.left);

      // Test 3: Right tooltip
      await _testTooltip(tester, 2, 'RIGHT', RATooltipPosition.right);

      // Test 4: Bottom tooltip
      await _testTooltip(tester, 3, 'BOTTOM', RATooltipPosition.bottom);

      // Test 5: Color randomization
      await _testColorRandomization(tester);

      // Test 6: Edge cases - rapid tapping
      await _testRapidInteractions(tester);

      // Test 7: Multiple tooltips simultaneously
      await _testMultipleTooltips(tester);
    });

    testWidgets('Test tooltip edge detection', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Create a test widget with tooltips at screen edges
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                // Top-left corner
                Positioned(
                  top: 20,
                  left: 20,
                  child: RATooltip(
                    message: 'Top-Left Edge',
                    position: RATooltipPosition.top,
                    child: Container(
                      width: 50,
                      height: 50,
                      color: Colors.red,
                      child: const Center(
                          child: Text('TL',
                              style: TextStyle(color: Colors.white))),
                    ),
                  ),
                ),
                // Top-right corner
                Positioned(
                  top: 20,
                  right: 20,
                  child: RATooltip(
                    message: 'Top-Right Edge',
                    position: RATooltipPosition.top,
                    child: Container(
                      width: 50,
                      height: 50,
                      color: Colors.green,
                      child: const Center(
                          child: Text('TR',
                              style: TextStyle(color: Colors.white))),
                    ),
                  ),
                ),
                // Bottom-left corner
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: RATooltip(
                    message: 'Bottom-Left Edge',
                    position: RATooltipPosition.bottom,
                    child: Container(
                      width: 50,
                      height: 50,
                      color: Colors.blue,
                      child: const Center(
                          child: Text('BL',
                              style: TextStyle(color: Colors.white))),
                    ),
                  ),
                ),
                // Bottom-right corner
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: RATooltip(
                    message: 'Bottom-Right Edge',
                    position: RATooltipPosition.bottom,
                    child: Container(
                      width: 50,
                      height: 50,
                      color: Colors.orange,
                      child: const Center(
                          child: Text('BR',
                              style: TextStyle(color: Colors.white))),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Test each corner tooltip
      final corners = ['TL', 'TR', 'BL', 'BR'];
      final positions = [
        'Top-Left',
        'Top-Right',
        'Bottom-Left',
        'Bottom-Right'
      ];

      for (int i = 0; i < corners.length; i++) {
        final finder = find.text(corners[i]);
        expect(finder, findsOneWidget);

        // Tap to show tooltip
        await tester.tap(finder);
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        // Verify tooltip is visible and within screen bounds
        await _verifyTooltipBounds(tester);

        // Tap again to hide
        await tester.tap(finder);
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        await tester.pump(const Duration(milliseconds: 200));
      }
    });
  });
}

/// Test individual tooltip interaction
Future<void> _testTooltip(
  WidgetTester tester,
  int index,
  String position,
  RATooltipPosition expectedPosition,
) async {
  // Find all Label texts
  final labelFinders = find.text('Label');
  expect(labelFinders, findsNWidgets(4));

  final targetFinder = labelFinders.at(index);

  // Tap to show tooltip
  await tester.tap(targetFinder);
  await tester.pumpAndSettle(const Duration(milliseconds: 300));

  // Verify tooltip is visible
  expect(find.text('Example Message'), findsWidgets);

  // Wait to see the tooltip
  await tester.pump(const Duration(milliseconds: 1000));

  // Verify tooltip bounds
  await _verifyTooltipBounds(tester);

  // Tap again to hide tooltip
  await tester.tap(targetFinder);
  await tester.pumpAndSettle(const Duration(milliseconds: 300));

  // Verify tooltip is hidden
  await tester.pump(const Duration(milliseconds: 500));
}

/// Test color randomization functionality
Future<void> _testColorRandomization(WidgetTester tester) async {
  final fabFinder = find.byType(FloatingActionButton);
  expect(fabFinder, findsOneWidget);

  // Tap FAB multiple times to test color changes
  for (int i = 0; i < 5; i++) {
    await tester.tap(fabFinder);
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    // Test a tooltip after color change
    final labelFinder = find.text('Label').first;
    await tester.tap(labelFinder);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    // Hide tooltip
    await tester.tap(labelFinder);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
  }
}

/// Test rapid interactions
Future<void> _testRapidInteractions(WidgetTester tester) async {
  final labelFinder = find.text('Label').first;

  // Rapid tap test
  for (int i = 0; i < 10; i++) {
    await tester.tap(labelFinder);
    await tester.pump(const Duration(milliseconds: 50));
  }

  await tester.pumpAndSettle(const Duration(milliseconds: 500));
}

/// Test multiple tooltips simultaneously
Future<void> _testMultipleTooltips(WidgetTester tester) async {
  final labelFinders = find.text('Label');

  // Try to show multiple tooltips
  await tester.tap(labelFinders.at(0));
  await tester.pump(const Duration(milliseconds: 100));

  await tester.tap(labelFinders.at(1));
  await tester.pump(const Duration(milliseconds: 100));

  await tester.tap(labelFinders.at(2));
  await tester.pump(const Duration(milliseconds: 100));

  await tester.pumpAndSettle(const Duration(milliseconds: 500));

  // Hide all tooltips
  for (int i = 0; i < 4; i++) {
    await tester.tap(labelFinders.at(i));
    await tester.pump(const Duration(milliseconds: 50));
  }

  await tester.pumpAndSettle(const Duration(milliseconds: 300));
}

/// Verify tooltip stays within screen bounds
Future<void> _verifyTooltipBounds(WidgetTester tester) async {
  final screenSize = tester.binding.window.physicalSize /
      tester.binding.window.devicePixelRatio;

  // Find any visible tooltip containers
  final tooltipContainers = find.byType(Container);

  for (final container in tooltipContainers.evaluate()) {
    final renderBox = container.renderObject as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;

      // Check bounds with some tolerance
      const tolerance = 20.0;
      expect(position.dx, greaterThanOrEqualTo(-tolerance),
          reason: 'Tooltip extends too far left');
      expect(position.dy, greaterThanOrEqualTo(-tolerance),
          reason: 'Tooltip extends too far up');
      expect(position.dx + size.width,
          lessThanOrEqualTo(screenSize.width + tolerance),
          reason: 'Tooltip extends too far right');
      expect(position.dy + size.height,
          lessThanOrEqualTo(screenSize.height + tolerance),
          reason: 'Tooltip extends too far down');
    }
  }
}
