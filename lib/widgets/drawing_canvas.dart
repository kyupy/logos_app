import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:logos_app/models/drawing_tool.dart';
import 'package:logos_app/models/stroke.dart'; // OffsetベースのStrokeモデルをインポート


// -- Painter クラス --

class DrawingPainter extends CustomPainter {
  final List<Stroke> finishedStrokes;
  final Stroke? currentStroke;
  final Offset? eraserPosition;

  DrawingPainter({
    required this.finishedStrokes,
    this.currentStroke,
    this.eraserPosition,
  });

  // -- 定数 --
  static const double kDefaultPenSize = 1.8;
  static const double kDefaultEraserRadius = 5.0;

  // -- Paintオブジェクトを静的フィールドとして保持し、再生成を防ぐ --
  static final _penPaint = Paint()
    ..color = Colors.black
    ..strokeWidth = kDefaultPenSize
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..filterQuality = FilterQuality.high;

  static final _ruledLinePaint = Paint()
    ..color = Colors.grey.shade300
    ..strokeWidth = 0.5;

  static final _dotPaint = Paint()
    ..color = Colors.grey.shade400
    ..strokeWidth = 1.0
    ..strokeCap = StrokeCap.round;
  
  static final _eraserCursorPaint = Paint()
    ..color = Colors.grey.withOpacity(0.5)
    ..style = PaintingStyle.fill;


  void _paintRuledAndDots(Canvas canvas, Size size) {
    const double mmToLogicalPixels = 3.78;
    const double lineSpacing = 6.0 * mmToLogicalPixels;
    const double dotSpacing = 6.0 * mmToLogicalPixels;
    const double topMargin = 10.0 * mmToLogicalPixels;

    for (double y = topMargin; y < size.height; y += lineSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), _ruledLinePaint);
    }

    final List<Offset> pointsToDraw = [];
    for (double y = topMargin; y < size.height; y += lineSpacing) {
      for (double x = dotSpacing; x < size.width; x += dotSpacing) {
        pointsToDraw.add(Offset(x, y));
      }
    }
    canvas.drawPoints(PointMode.points, pointsToDraw, _dotPaint);
  }

  void _paintStrokes(Canvas canvas, List<Stroke> strokes) {
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;

      if (stroke.points.length == 1) {
        canvas.drawPoints(PointMode.points, [stroke.points.first], _penPaint);
        continue;
      }

      final path = Path();
      path.moveTo(stroke.points.first.dx, stroke.points.first.dy);

      for (int i = 1; i < stroke.points.length; i++) {
        final p1 = stroke.points[i - 1];
        final p2 = stroke.points[i];
        path.quadraticBezierTo(p1.dx, p1.dy, (p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
      }
      path.lineTo(stroke.points.last.dx, stroke.points.last.dy);
      canvas.drawPath(path, _penPaint);
    }
  }

  void _paintEraserCursor(Canvas canvas, Offset? position) {
    if (position == null) return;
    canvas.drawCircle(position, kDefaultEraserRadius, _eraserCursorPaint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _paintRuledAndDots(canvas, size);

    // 確定済みのストロークを描画
    _paintStrokes(canvas, finishedStrokes);
    
    // 現在描画中のストロークを描画
    if (currentStroke != null) {
      _paintStrokes(canvas, [currentStroke!]);
    }

    _paintEraserCursor(canvas, eraserPosition);
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) {
    // 描画に関連するプロパティが変更された場合のみ再描画する
    return oldDelegate.finishedStrokes != finishedStrokes ||
           oldDelegate.currentStroke != currentStroke ||
           oldDelegate.eraserPosition != eraserPosition;
  }
}


// -- Widget クラス --

class DrawingCanvas extends StatefulWidget {
  final DrawingTool currentTool;
  final Function(List<Stroke>) onStrokesUpdated;
  final List<Stroke> initialStrokes;
  final bool stylusOnlyDrawing;
  final Function(bool) onDrawingStateChanged;

  const DrawingCanvas({
    super.key,
    required this.currentTool,
    required this.onStrokesUpdated,
    required this.initialStrokes,
    required this.stylusOnlyDrawing,
    required this.onDrawingStateChanged,
  });

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  late List<Stroke> _finishedStrokes;
  Stroke? _currentStroke;
  Offset? _eraserPosition;
  
  int _activePointerCount = 0;
  static const double kMinPointDistance = 0.4;
  Offset? _lastAddedPoint;

  @override
  void initState() {
    super.initState();
    _finishedStrokes = List<Stroke>.from(widget.initialStrokes);
  }
  
  @override
  void didUpdateWidget(covariant DrawingCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    // initialStrokesが外部から変更された場合に同期する
    if (widget.initialStrokes != oldWidget.initialStrokes) {
      setState(() {
        _finishedStrokes = List<Stroke>.from(widget.initialStrokes);
      });
    }
  }

  /// 消しゴム処理（バウンディングボックスで最適化済み）
  void _handleErase(Offset currentPosition) {
    const double eraserRadius = DrawingPainter.kDefaultEraserRadius;
    const double eraserRadiusSq = eraserRadius * eraserRadius; // 平方根の計算を避ける
    final eraserRect = Rect.fromCircle(center: currentPosition, radius: eraserRadius);
    bool needsUpdate = false;

    _finishedStrokes.removeWhere((stroke) {
      // 1. バウンディングボックスで高速に当たり判定
      if (!stroke.boundingBox.overlaps(eraserRect)) {
        return false;
      }

      // 2. バウンディングボックスが重なる場合のみ、詳細な点単位の当たり判定
      for (final point in stroke.points) {
        if ((point - currentPosition).distanceSquared < eraserRadiusSq) {
          needsUpdate = true;
          return true; // ストローク全体を削除
        }
      }
      return false;
    });

    if (needsUpdate) {
      setState(() {});
      widget.onStrokesUpdated(List<Stroke>.from(_finishedStrokes));
    }
  }
  
  void _startDrawing(PointerDownEvent details) {
    widget.onDrawingStateChanged(true);
    final point = details.localPosition;
    
    switch (widget.currentTool) {
      case DrawingTool.pen:
        setState(() {
          _currentStroke = Stroke([point]);
          _lastAddedPoint = point;
        });
        break;
      case DrawingTool.eraser:
        setState(() => _eraserPosition = point);
        _handleErase(point);
        break;
    }
  }
  
  void _updateDrawing(PointerMoveEvent details) {
    final point = details.localPosition;

    switch (widget.currentTool) {
      case DrawingTool.pen:
        if (_currentStroke == null || _lastAddedPoint == null) return;
        if ((point - _lastAddedPoint!).distance < kMinPointDistance) return;
        
        setState(() {
          // ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
          // ★ 修正点: 新しいStrokeオブジェクトを作成して状態の不変性(Immutability)を保つ ★
          // ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
          final updatedPoints = List<Offset>.from(_currentStroke!.points)..add(point);
          _currentStroke = Stroke(updatedPoints);
          _lastAddedPoint = point;
        });
        break;
      case DrawingTool.eraser:
        setState(() => _eraserPosition = point);
        _handleErase(point);
        break;
    }
  }

  void _endDrawing() {
    widget.onDrawingStateChanged(false);

    if (widget.currentTool == DrawingTool.pen && _currentStroke != null) {
      // 描画中のストロークを確定済みリストに追加
      _finishedStrokes.add(_currentStroke!);
      widget.onStrokesUpdated(List<Stroke>.from(_finishedStrokes));
    }
    
    setState(() {
      _currentStroke = null;
      _eraserPosition = null;
      _lastAddedPoint = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (details) {
        final kind = details.kind;
        final bool isStylus = kind == PointerDeviceKind.stylus;
        final bool canDrawWithTouch = !widget.stylusOnlyDrawing && kind == PointerDeviceKind.touch;
        
        _activePointerCount++;
        if (_activePointerCount > 1) {
          if (_currentStroke != null || _eraserPosition != null) _endDrawing();
          return;
        }
        if (isStylus || canDrawWithTouch) {
          _startDrawing(details);
        }
      },
      onPointerMove: (details) {
        if ((_currentStroke != null || _eraserPosition != null) && _activePointerCount == 1) {
          _updateDrawing(details);
        }
      },
      onPointerUp: (details) {
        if (_activePointerCount > 0) _activePointerCount--;
        if (_currentStroke != null || _eraserPosition != null) _endDrawing();
      },
      onPointerCancel: (details) {
        if (_activePointerCount > 0) _activePointerCount--;
        if (_currentStroke != null || _eraserPosition != null) _endDrawing();
      },
      child: CustomPaint(
        painter: DrawingPainter(
          finishedStrokes: _finishedStrokes,
          currentStroke: _currentStroke,
          eraserPosition: _eraserPosition,
        ),
        size: Size.infinite,
      ),
    );
  }
}