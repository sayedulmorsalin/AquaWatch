import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aquawatch/water_quality_detection/fish_water_analysis_report.dart';

void main() {
  testWidgets('FishScoreGaugePainter smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CustomPaint(
              size: const Size(200, 100),
              painter: FishScoreGaugePainter(
                score: 0.85,
                color: const Color(0xFF00E676),
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is FishScoreGaugePainter,
      ),
      findsOneWidget,
    );
  });
}
