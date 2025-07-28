import 'package:logos_app/widgets/drawing_canvas.dart';
import 'dart:ui';

// perfect_freehandのPointの代わりに、FlutterのOffsetを使用
class Stroke {
  final List<Offset> points;
  Rect? _boundingBox; // バウンディングボックスのキャッシュ

  Stroke(this.points);

  /// ストロークのバウンディングボックス（境界矩形）を計算します。
  /// パフォーマンス向上のため、一度計算した値はキャッシュされます。
  Rect get boundingBox {
    if (_boundingBox != null) return _boundingBox!;
    if (points.isEmpty) return Rect.zero;

    double left = points.first.dx;
    double top = points.first.dy;
    double right = points.first.dx;
    double bottom = points.first.dy;

    for (final point in points) {
      if (point.dx < left) left = point.dx;
      if (point.dx > right) right = point.dx;
      if (point.dy < top) top = point.dy;
      if (point.dy > bottom) bottom = point.dy;
    }

    // ストロークの太さを考慮して、当たり判定を少し広げます。
    const padding = DrawingPainter.kDefaultPenSize;
    return _boundingBox = Rect.fromLTRB(left - padding, top - padding, right + padding, bottom + padding);
  }
}