import 'package:flutter/material.dart';

const designSize = Size(898, 1751);
const penangPoint = Offset(112, 450);
const kelantanPoint = Offset(358, 472);
const melakaPoint = Offset(297, 740);
const sarawakPoint = Offset(730, 625);

double clampProgress(double value) => value.clamp(0.0, 1.0).toDouble();

Path buildJourneyPath() => Path()
  ..moveTo(penangPoint.dx, penangPoint.dy)
  ..cubicTo(175, 510, 270, 420, kelantanPoint.dx, kelantanPoint.dy)
  ..cubicTo(430, 550, 405, 680, melakaPoint.dx, melakaPoint.dy)
  ..cubicTo(410, 800, 545, 620, sarawakPoint.dx, sarawakPoint.dy);
