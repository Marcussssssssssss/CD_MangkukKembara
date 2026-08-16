import 'package:flutter/material.dart';

import 'journey_animation_coordinates.dart';

class JourneyRoutePainter extends CustomPainter {
  JourneyRoutePainter({required this.progress, required Listenable repaint})
      : super(repaint: repaint);

  final Animation<double> progress;

  @override
  void paint(Canvas canvas, Size size) {
    final metric = buildJourneyPath().computeMetrics().first;
    final routeProgress = clampProgress(progress.value);
    final visibleLength =
        (metric.length * routeProgress).clamp(0.0, metric.length).toDouble();
    const dashLength = 14.0;
    const dashGap = 10.0;
    final shadow = Paint()
      ..color = const Color(0x55023E3E)
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final gold = Paint()
      ..color = const Color(0xFFE3B52C)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var distance = 0.0; distance < visibleLength; distance += dashLength + dashGap) {
      final end =
          (distance + dashLength).clamp(0.0, visibleLength).toDouble();
      final segment = metric.extractPath(distance, end);
      canvas.drawPath(segment, shadow);
      canvas.drawPath(segment, gold);
    }
  }

  @override
  bool shouldRepaint(covariant JourneyRoutePainter oldDelegate) => false;
}
