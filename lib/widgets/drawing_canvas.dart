// lib/widgets/drawing_canvas.dart

import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:logos_app/models/drawing_tool.dart';
import 'package:logos_app/models/stroke.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

class DrawingPainter extends CustomPainter {
  final ValueNotifier<List<Stroke>> strokesNotifier;
  final ValueNotifier<Offset?> eraserPositionNotifier;

  DrawingPainter({required this.strokesNotifier, required this.eraserPositionNotifier})
      : super(repaint: Listenable.merge([strokesNotifier, eraserPositionNotifier]));

  static const double kDefaultPenSize = 1.8;
  static const double kDefaultEraserRadius = 5.0;

  void _paintRuledAndDots(Canvas canvas, Size size) {
    final linePaint = Paint()..color = Colors.grey.shade300..strokeWidth = 0.5;
    // ★ ここで 'dotPaint' と定義
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
    // ★★★ エラー箇所を 'dPaint' から 'dotPaint' に修正 ★★★
    canvas.drawPoints(PointMode.points, pointsToDraw, dotPaint);
  }

  void _paintStrokes(Canvas canvas, List<Stroke> strokes) {
    final paint = Paint()..color = Colors.black;

    final strokeOptions = StrokeOptions(
      size: kDefaultPenSize,
      thinning: 0,
      smoothing: 0.65,
      streamline: 0.6,
      simulatePressure: false,
      start: StrokeEndOptions.start(taperEnabled: false, cap: true),
      end: StrokeEndOptions.end(taperEnabled: false, cap: true),
    );

    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      final outline = getStroke(stroke.points, options: strokeOptions);
      if (outline.isEmpty) continue;
      final path = Path()..addPolygon(outline, false);
      canvas.drawPath(path, paint);
    }
  }

  void _paintEraserCursor(Canvas canvas, Offset? eraserPosition) {
    if (eraserPosition == null) return;
    final paint = Paint()..color = Colors.grey.withOpacity(0.5)..style = PaintingStyle.fill;
    canvas.drawCircle(eraserPosition, kDefaultEraserRadius, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _paintRuledAndDots(canvas, size);
    _paintStrokes(canvas, strokesNotifier.value);
    _paintEraserCursor(canvas, eraserPositionNotifier.value);
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) {
    return false;
  }
}

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
  late final ValueNotifier<List<Stroke>> _strokesNotifier;
  final ValueNotifier<Offset?> _eraserPositionNotifier = ValueNotifier(null);

  late List<Stroke> _finishedStrokes;
  Stroke? _currentStroke;
  
  int _activePointerCount = 0;
  
  static const double kMinPointDistance = 0.4;
  Offset? _lastAddedPoint;

  @override
  void initState() {
    super.initState();
    _finishedStrokes = List<Stroke>.from(widget.initialStrokes);
    _strokesNotifier = ValueNotifier(_finishedStrokes);
  }
  
  @override
  void didUpdateWidget(covariant DrawingCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialStrokes != oldWidget.initialStrokes) {
      _finishedStrokes = List<Stroke>.from(widget.initialStrokes);
      _strokesNotifier.value = _finishedStrokes;
    }
  }
  
  @override
  void dispose() {
    _strokesNotifier.dispose();
    _eraserPositionNotifier.dispose();
    super.dispose();
  }

  Point _mapOffsetToPoint(Offset offset) {
    return Point(offset.dx, offset.dy, 0.5);
  }

  void _handleErase(Offset currentPosition) {
    const double eraserRadius = DrawingPainter.kDefaultEraserRadius;
    bool needsUpdate = false;
    _finishedStrokes.removeWhere((stroke) {
      for (final point in stroke.points) {
        final distance = (Offset(point.x, point.y) - currentPosition).distance;
        if (distance < eraserRadius) {
          needsUpdate = true;
          return true;
        }
      }
      return false;
    });

    if (needsUpdate) {
        widget.onStrokesUpdated(List<Stroke>.from(_finishedStrokes));
        _strokesNotifier.value = List<Stroke>.from(_finishedStrokes);
    }
  }
  
  void _startDrawing(PointerDownEvent details) {
    widget.onDrawingStateChanged(true);
    final point = details.localPosition;
    
    switch (widget.currentTool) {
      case DrawingTool.pen:
        _currentStroke = Stroke([_mapOffsetToPoint(point)]);
        _strokesNotifier.value = [..._finishedStrokes, _currentStroke!];
        _lastAddedPoint = point;
        break;
      case DrawingTool.eraser:
        _eraserPositionNotifier.value = point;
        _handleErase(point);
        break;
    }
  }
  
  void _updateDrawing(PointerMoveEvent details) {
    final point = details.localPosition;

    switch (widget.currentTool) {
      case DrawingTool.pen:
        if (_currentStroke == null || _lastAddedPoint == null) return;

        final distance = (point - _lastAddedPoint!).distance;
        
        if (distance < kMinPointDistance) {
          return;
        }

        _currentStroke!.points.add(_mapOffsetToPoint(point));
        _lastAddedPoint = point;

        _strokesNotifier.value = [..._finishedStrokes, _currentStroke!];
        break;
        
      case DrawingTool.eraser:
        _eraserPositionNotifier.value = point;
        _handleErase(point);
        break;
    }
  }

  void _endDrawing() {
    widget.onDrawingStateChanged(false);

    if (widget.currentTool == DrawingTool.pen && _currentStroke != null) {
      _finishedStrokes.add(_currentStroke!);
      widget.onStrokesUpdated(List<Stroke>.from(_finishedStrokes));
    }
    
    _currentStroke = null;
    _eraserPositionNotifier.value = null;
    _lastAddedPoint = null;
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
          if (_currentStroke != null || _eraserPositionNotifier.value != null) _endDrawing();
          return;
        }
        if (isStylus || canDrawWithTouch) {
          _startDrawing(details);
        }
      },
      onPointerMove: (details) {
        if ((_currentStroke != null || _eraserPositionNotifier.value != null) && _activePointerCount == 1) {
          _updateDrawing(details);
        }
      },
      onPointerUp: (details) {
        if (_activePointerCount > 0) _activePointerCount--;
        if (_currentStroke != null || _eraserPositionNotifier.value != null) _endDrawing();
      },
      onPointerCancel: (details) {
        if (_activePointerCount > 0) _activePointerCount--;
        if (_currentStroke != null || _eraserPositionNotifier.value != null) _endDrawing();
      },
      child: CustomPaint(
        painter: DrawingPainter(
          strokesNotifier: _strokesNotifier,
          eraserPositionNotifier: _eraserPositionNotifier,
        ),
        size: Size.infinite,
      ),
    );
  }
}