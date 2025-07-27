// lib/models/stroke.dart

import 'package:perfect_freehand/perfect_freehand.dart';

class Stroke {
  final List<Point> points;

  // strokeWidthを削除し、一番シンプルなコンストラクタに戻す
  Stroke(this.points);
}