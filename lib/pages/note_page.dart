// lib/pages/note_page.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logos_app/models/drawing_tool.dart';
import 'package:logos_app/models/note_data.dart';
import 'package:logos_app/models/stroke.dart';
import 'package:logos_app/widgets/drawing_canvas.dart';
import 'package:perfect_freehand/perfect_freehand.dart' as freehand;

class NotePage extends StatefulWidget {
  final int noteKey;
  const NotePage({super.key, required this.noteKey});

  @override
  State<NotePage> createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> with SingleTickerProviderStateMixin {
  // --- 状態管理 ---
  DrawingTool _currentTool = DrawingTool.pen;
  final Box<NoteData> _notesBox = Hive.box<NoteData>('notes_box');
  NoteData? _currentNote;
  int _currentPageIndex = 0;
  bool _isLoading = true;

  bool _stylusOnlyDrawing = true;
  bool _isDrawingOnCanvas = false;

  late PageController _pageController;
  final TransformationController _transformationController = TransformationController();
  final Box _settingsBox = Hive.box('settings_box');

  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  @override
  void initState() {
    super.initState();
    _stylusOnlyDrawing = _settingsBox.get('stylusOnlyDrawing', defaultValue: true);
    _settingsBox.listenable(keys: ['stylusOnlyDrawing']).addListener(_onSettingsChanged);
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _loadNote().then((_) {
      if (!mounted) return;
      if (_currentNote != null) {
        _pageController = PageController(initialPage: _currentNote!.lastOpenedPageIndex);
      }
      setState(() => _isLoading = false);
    });
  }

  @override
  void dispose() {
    _settingsBox.listenable(keys: ['stylusOnlyDrawing']).removeListener(_onSettingsChanged);
    _animationController.dispose();
    if (mounted) {
      _pageController.dispose();
    }
    _transformationController.dispose();
    super.dispose();
  }
  
  void _onSettingsChanged() {
    if (!mounted) return;
    setState(() {
      _stylusOnlyDrawing = _settingsBox.get('stylusOnlyDrawing', defaultValue: true);
    });
  }
  
  void _onInteractionEnd(ScaleEndDetails details) {
    final Matrix4 matrix = _transformationController.value.clone();
    final double currentScale = matrix.getMaxScaleOnAxis();

    if (currentScale < 1.0) {
      _runAnimation(Matrix4.identity());
      return;
    }
  }

  void _runAnimation(Matrix4 targetMatrix) {
    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: targetMatrix,
    ).animate(
      CurveTween(curve: Curves.easeOut).animate(_animationController),
    );
    _animation!.addListener(() {
      if (mounted) {
        _transformationController.value = _animation!.value;
      }
    });
    _animationController.forward(from: 0);
  }

  Future<void> _loadNote() async {
    final note = _notesBox.get(widget.noteKey);
    if (mounted) {
      _currentNote = note;
      if (_currentNote != null) {
        _currentPageIndex = _currentNote!.lastOpenedPageIndex;
        if (_currentPageIndex >= _currentNote!.pages.length || _currentPageIndex < 0) {
          _currentPageIndex = 0;
        }
      }
    }
  }

  void _saveNote() {
    if (_currentNote != null) {
      _currentNote!.lastOpenedPageIndex = _currentPageIndex;
      _currentNote!.save();
    }
  }

  void _addNewPage() {
    if (_currentNote == null) return;
    final newPageIndex = _currentNote!.pages.length;
    setState(() {
      _currentNote!.pages.add(PageData(strokes: []));
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _pageController.animateToPage(
          newPageIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
    _saveNote();
  }
  
  List<StrokeData> _convertStrokesToStrokeData(List<Stroke> strokes) {
    return strokes.map((stroke) {
      final points = stroke.points.map((point) => NotePointData(x: point.x, y: point.y, pressure: point.pressure)).toList();
      return StrokeData(points: points);
    }).toList();
  }

  List<Stroke> _convertPageDataToStrokes(PageData pageData) {
    return pageData.strokes.map((strokeData) {
      final points = strokeData.points.map((pointData) => freehand.Point(pointData.x ?? 0, pointData.y ?? 0, pointData.pressure ?? 0.5)).toList();
      return Stroke(points);
    }).toList();
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    if (_currentNote == null) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('エラー'),
          leading: const CupertinoNavigationBarBackButton(previousPageTitle: 'Notes'),
        ),
        child: const Center(child: Text('ノートを読み込めませんでした。')),
      );
    }

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        previousPageTitle: 'Notes',
        middle: Text(_currentNote?.title ?? '無題のノート'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: const EdgeInsets.all(8.0),
              child: Icon(CupertinoIcons.pencil, size: 24, color: _currentTool == DrawingTool.pen ? CupertinoColors.activeBlue : CupertinoColors.secondaryLabel),
              onPressed: () => setState(() => _currentTool = DrawingTool.pen),
            ),
            CupertinoButton(
              padding: const EdgeInsets.all(8.0),
              child: Icon(const IconData(0xf39a, fontFamily: 'CupertinoIcons'), size: 24, color: _currentTool == DrawingTool.eraser ? CupertinoColors.activeBlue : CupertinoColors.secondaryLabel),
              onPressed: () => setState(() => _currentTool = DrawingTool.eraser),
            ),
          ],
        ),
      ),
      // ★★★ 必須引数であるchildに戻す ★★★
      child: PageView.builder(
        controller: _pageController,
        physics: _isDrawingOnCanvas ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics(),
        itemCount: _currentNote!.pages.length + 1,
        onPageChanged: (index) {
          if (index == _currentNote!.pages.length) {
            _addNewPage();
          } else {
            setState(() {
              _currentPageIndex = index;
            });
            _transformationController.value = Matrix4.identity();
          }
        },
        itemBuilder: (context, index) {
          if (index == _currentNote!.pages.length) {
             return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.plus_app, size: 50, color: CupertinoColors.secondaryLabel),
                  SizedBox(height: 16),
                  Text('スワイプして新規ページを追加', style: TextStyle(color: CupertinoColors.secondaryLabel)),
                ],
              ),
            );
          }
          
          const double paperWidth = 600.0;
          const double paperHeight = paperWidth * 1.414;

          return InteractiveViewer(
            transformationController: _transformationController,
            boundaryMargin: const EdgeInsets.all(double.infinity),
            minScale: 0.1, 
            maxScale: 4.0,
            panEnabled: !_isDrawingOnCanvas,
            scaleEnabled: !_isDrawingOnCanvas,
            onInteractionEnd: _onInteractionEnd,
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: paperWidth,
                height: paperHeight,
                child: Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: DrawingCanvas(
                    currentTool: _currentTool,
                    stylusOnlyDrawing: _stylusOnlyDrawing,
                    initialStrokes: _convertPageDataToStrokes(_currentNote!.pages[index]),
                    onStrokesUpdated: (updatedStrokes) {
                      if (_currentNote == null || index >= _currentNote!.pages.length) return;
                      _currentNote!.pages[index].strokes = _convertStrokesToStrokeData(updatedStrokes);
                      _saveNote();
                      if (mounted) setState(() {});
                    },
                    onDrawingStateChanged: (isDrawing) {
                      if (_isDrawingOnCanvas != isDrawing) {
                        setState(() {
                          _isDrawingOnCanvas = isDrawing;
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}