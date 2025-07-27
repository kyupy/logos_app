// lib/widgets/drawing_canvas.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:logos_app/models/drawing_tool.dart';
import 'package:logos_app/models/stroke.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

class DrawingPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Offset? eraserPosition;

  DrawingPainter({required this.strokes, this.eraserPosition});

  static const double kDefaultPenSize = 2.0;
  static const double kDefaultEraserRadius = 8.0;

  void _paintRuledAndDots(Canvas canvas, Size size) {
    final linePaint = Paint()..color = Colors.grey.shade300..strokeWidth = 0.5;
    final dotPaint = Paint()..color = Colors.grey.shade400..strokeWidth = 1.0..strokeCap = StrokeCap.round;
    const double mmToLogicalPixels = 3.78;
    const double lineSpacing = 6.0 * mmToLogicalPixels;
    const double dotSpacing = 6.0 * mmToLogicalPixels;
    const double topMargin = 10.0 * mmToLogicalPixels;

    for (double y = topMargin; y < size.height; y += lineSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
    final List<Offset> pointsToDraw = [];
    for (double y = topMargin; y < size.height; y += lineSpacing) {
      for (double x = dotSpacing; x < size.width; x += dotSpacing) {
        pointsToDraw.add(Offset(x, y));
      }
    }
    canvas.drawPoints(PointMode.points, pointsToDraw, dotPaint);
  }

  void _paintStrokes(Canvas canvas) {
    final paint = Paint()..color = Colors.black..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    final strokeOptions = StrokeOptions(
      size: kDefaultPenSize,
      thinning: 0.65,
      smoothing: 0.5,
      streamline: 0.6,
      simulatePressure: false,
      start: StrokeEndOptions.start(taperEnabled: false, cap: true),
      end: StrokeEndOptions.end(taperEnabled: false, cap: true),
    );

    for (final stroke in strokes) {
      if (stroke.points.length < 2) continue;
      final strokeOutline = getStroke(stroke.points, options: strokeOptions);
      final path = Path()..addPolygon(strokeOutline, false);
      canvas.drawPath(path, paint);
    }
  }

  void _paintEraserCursor(Canvas canvas) {
    if (eraserPosition == null) return;
    final paint = Paint()..color = Colors.grey.withOpacity(0.5)..style = PaintingStyle.fill;
    canvas.drawCircle(eraserPosition!, kDefaultEraserRadius, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _paintRuledAndDots(canvas, size);
    _paintStrokes(canvas);
    _paintEraserCursor(canvas);
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) {
    return true;
  }
}

class DrawingCanvas extends StatefulWidget {
  final DrawingTool currentTool;
  final Function(List<Stroke>) onStrokesUpdated;
  final List<Stroke> initialStrokes;

  const DrawingCanvas({
    super.key,
    required this.currentTool,
    required this.onStrokesUpdated,
    required this.initialStrokes,
  });

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  late List<Stroke> _finishedStrokes;
  Stroke? _currentStroke;
  Offset? _eraserPosition;

  @override
  void initState() {
    super.initState();
    _finishedStrokes = List<Stroke>.from(widget.initialStrokes);
  }

  @override
  void didUpdateWidget(covariant DrawingCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialStrokes != oldWidget.initialStrokes) {
      _finishedStrokes = List<Stroke>.from(widget.initialStrokes);
    }
  }

  Point _mapOffsetToPoint(Offset offset) {
    return Point(offset.dx, offset.dy, 0.5);
  }

  void _handleErase(Offset currentPosition) {
    const double eraserRadius = DrawingPainter.kDefaultEraserRadius;
    final List<Stroke> strokesToRemove = [];
    for (final stroke in _finishedStrokes) {
      for (final point in stroke.points) {
        final distance = (Offset(point.x, point.y) - currentPosition).distance;
        if (distance < eraserRadius) {
          strokesToRemove.add(stroke);
          break;
        }
      }
    }
    if (strokesToRemove.isNotEmpty) {
      _finishedStrokes.removeWhere((stroke) => strokesToRemove.contains(stroke));
      widget.onStrokesUpdated(List<Stroke>.from(_finishedStrokes));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentTool == DrawingTool.pen) {
      return _buildPenDetector();
    } else {
      return _buildEraserDetector();
    }
  }

  Widget _buildPenDetector() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (details) {
        final points = [_mapOffsetToPoint(details.localPosition)];
        setState(() => _currentStroke = Stroke(points));
      },
      onPanUpdate: (details) {
        if (_currentStroke == null) return;
        final points = List<Point>.from(_currentStroke!.points)..add(_mapOffsetToPoint(details.localPosition));
        setState(() => _currentStroke = Stroke(points));
      },
      onPanEnd: (details) {
        if (_currentStroke != null) {
          _finishedStrokes.add(_currentStroke!);
          _currentStroke = null;
          widget.onStrokesUpdated(List<Stroke>.from(_finishedStrokes));
          setState(() {});
        }
      },
      child: CustomPaint(
        painter: DrawingPainter(
          strokes: [..._finishedStrokes, if (_currentStroke != null) _currentStroke!],
        ),
        size: Size.infinite,
      ),
    );
  }

  Widget _buildEraserDetector() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (details) {
        setState(() => _eraserPosition = details.localPosition);
        _handleErase(details.localPosition);
      },
      onPanUpdate: (details) {
        setState(() => _eraserPosition = details.localPosition);
        _handleErase(details.localPosition);
      },
      onPanEnd: (details) {
        setState(() => _eraserPosition = null);
      },
      child: CustomPaint(
        painter: DrawingPainter(
          strokes: _finishedStrokes,
          eraserPosition: _eraserPosition,
        ),
        size: Size.infinite,
      ),
    );
  }
}