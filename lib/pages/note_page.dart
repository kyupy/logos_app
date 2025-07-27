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

class _NotePageState extends State<NotePage> {
  // --- 状態管理 (サイズ管理の変数を削除) ---
  DrawingTool _currentTool = DrawingTool.pen;
  final Box<NoteData> _notesBox = Hive.box<NoteData>('notes_box');
  NoteData? _currentNote;
  int _currentPageIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  // --- データ操作 ---
  Future<void> _loadNote() async {
    final note = _notesBox.get(widget.noteKey);
    if (mounted) {
      setState(() {
        _currentNote = note;
        if (_currentNote != null) {
          _currentPageIndex = _currentNote!.lastOpenedPageIndex;
          if (_currentPageIndex >= _currentNote!.pages.length || _currentPageIndex < 0) {
            _currentPageIndex = 0;
          }
        }
        _isLoading = false;
      });
    }
  }

  void _saveNote() {
    if (_currentNote != null) {
      _currentNote!.lastOpenedPageIndex = _currentPageIndex;
      _currentNote!.save();
    }
  }

  // --- ページ操作 ---
  void _addNewPage() {
    if (_currentNote == null) return;
    setState(() {
      _currentNote!.pages.add(PageData(strokes: []));
      _currentPageIndex = _currentNote!.pages.length - 1;
    });
    _saveNote();
  }

  void _goToPreviousPage() {
    if (_currentPageIndex > 0) {
      setState(() => _currentPageIndex--);
      _saveNote();
    }
  }

  void _goToNextPage() {
    if (_currentNote != null && _currentPageIndex < _currentNote!.pages.length - 1) {
      setState(() => _currentPageIndex++);
      _saveNote();
    }
  }

  // --- データ変換ヘルパー (strokeWidthの処理を削除) ---
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
      child: Column(
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.topCenter,
              child: AspectRatio(
                aspectRatio: 1 / 1.414,
                child: Container(
                  margin: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: DrawingCanvas(
                    currentTool: _currentTool,
                    initialStrokes: _convertPageDataToStrokes(_currentNote!.pages[_currentPageIndex]),
                    onStrokesUpdated: (updatedStrokes) {
                      if (_currentNote == null) return;
                      _currentNote!.pages[_currentPageIndex].strokes = _convertStrokesToStrokeData(updatedStrokes);
                      _saveNote();
                      if (mounted) setState(() {});
                    },
                  ),
                ),
              ),
            ),
          ),
          _buildPageControlBar(),
        ],
      ),
    );
  }

  Widget _buildPageControlBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: CupertinoTheme.of(context).barBackgroundColor.withOpacity(0.8),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CupertinoButton(
              onPressed: _goToPreviousPage,
              child: const Icon(CupertinoIcons.chevron_back),
            ),
            if (_currentNote != null)
              Text(
                '${_currentPageIndex + 1} / ${_currentNote!.pages.length}',
                style: CupertinoTheme.of(context).textTheme.textStyle,
              ),
            CupertinoButton(
              onPressed: _goToNextPage,
              child: const Icon(CupertinoIcons.chevron_forward),
            ),
            const Spacer(),
            CupertinoButton(
              onPressed: _addNewPage,
              child: const Icon(CupertinoIcons.plus_square),
            ),
          ],
        ),
      ),
    );
  }
}