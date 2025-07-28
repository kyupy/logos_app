// lib/pages/home_page.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

// ★ flutter_slidableをインポート
import 'package:flutter_slidable/flutter_slidable.dart';

// 自身のプロジェクトのパスに合わせてください
import 'package:logos_app/models/note_data.dart';
import 'package:logos_app/pages/note_page.dart';
import 'package:logos_app/pages/settings_page.dart';

// ★ custom_slidable.dartのインポートは不要なので削除
import 'package:logos_app/widgets/my_custom_list_tile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Box<NoteData> _notesBox = Hive.box<NoteData>('notes_box');

  int? _editingNoteKey;
  bool _isCreatingNewNote = false;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // ★ 自作ウィジェット用の状態管理だったので、不要になり削除
  // Key? _openedSlidableKey;

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _openSettings() {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => const SettingsPage()),
    );
  }

  void _openNote(int key, NoteData note) {
    if (_editingNoteKey != null || _isCreatingNewNote) return;
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => NotePage(noteKey: key),
      ),
    );
  }

  Future<void> _deleteNote(BuildContext context, int key) async {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('ノートを削除'),
          content: const Text('このノートを本当に削除しますか？この操作は取り消せません。'),
          actions: <CupertinoDialogAction>[
            CupertinoDialogAction(
              child: const Text('キャンセル'),
              onPressed: () => Navigator.pop(dialogContext),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('削除'),
              onPressed: () {
                _notesBox.delete(key);
                Navigator.pop(dialogContext);
              },
            ),
          ],
        );
      },
    );
  }

  // ★ 自作ウィジェット用のメソッドだったので、不要になり削除
  // void _handleSlidableOpen(Key key) { ... }
  // void _closeOpenedSlidable() { ... }

  void _startCreating() {
    if (_editingNoteKey != null || _isCreatingNewNote) return;
    setState(() {
      _isCreatingNewNote = true;
      _textController.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    });
  }

  void _startEditing(int key, NoteData note) {
    if (_editingNoteKey != null || _isCreatingNewNote) return;
    setState(() {
      _editingNoteKey = key;
      _textController.text = note.title ?? '';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
        _textController.selection =
            TextSelection(baseOffset: 0, extentOffset: _textController.text.length);
      });
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingNoteKey = null;
      _isCreatingNewNote = false;
      _textController.clear();
      _focusNode.unfocus();
    });
  }

  void _submitEditing() {
    if (_isCreatingNewNote) {
      final title = _textController.text.trim();
      final noteTitle = title.isNotEmpty ? title : '無題のノート';
      final firstPage = PageData(strokes: []);
      final newNote = NoteData(
        title: noteTitle,
        pages: [firstPage],
        createdAt: DateTime.now(),
        lastOpenedPageIndex: 0,
      );
      _notesBox.add(newNote);
    } else if (_editingNoteKey != null) {
      final note = _notesBox.get(_editingNoteKey!);
      if (note != null) {
        final title = _textController.text.trim();
        note.title = title.isNotEmpty ? title : '無題のノート';
        note.save();
      }
    }
    _cancelEditing();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _openSettings,
          child: const Icon(CupertinoIcons.settings),
        ),
        middle: const Text('logos'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _startCreating,
          child: const Icon(CupertinoIcons.add),
        ),
      ),
      child: SafeArea(
        child: GestureDetector(
          onTap: () {
            // ★ スライドを閉じるロジックは不要になり、編集中の処理のみに
            if (_editingNoteKey != null || _isCreatingNewNote) {
              _submitEditing();
            }
          },
          child: ValueListenableBuilder(
            valueListenable: _notesBox.listenable(),
            builder: (context, Box<NoteData> box, _) {
              final notes = box.values.toList().reversed.toList();
              final noteKeys = box.keys.toList().reversed.toList();

              if (notes.isEmpty && !_isCreatingNewNote) {
                return const Center(child: Text("ノートがありません"));
              }

              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: notes.length + (_isCreatingNewNote ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isCreatingNewNote && index == 0) {
                    return _buildEditingTile(isCreating: true);
                  }

                  final noteIndex = _isCreatingNewNote ? index - 1 : index;
                  final note = notes[noteIndex];
                  final key = noteKeys[noteIndex] as int;
                  final isEditingThisNote = _editingNoteKey == key;

                  if (isEditingThisNote) {
                    return _buildEditingTile(isCreating: false);
                  }

                  // ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
                  // ★ ここをflutter_slidableのSlidableウィジェットに置き換え ★
                  // ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
                  return Slidable(
                    key: ValueKey(key),
                    closeOnScroll: false,
                    groupTag: 'notes-list',
                    endActionPane: ActionPane(
                      // iOS純正メモアプリ風の動き
                      motion: const BehindMotion(),
                      // ボタン幅の40%までスワイプしたら、開いたままにする
                      openThreshold: 0.30,
                      // ボタンの表示領域
                      extentRatio: 0.20,
                      children: [
                        SlidableAction(
                          onPressed: (context) => _deleteNote(context, key),
                          backgroundColor: CupertinoColors.destructiveRed,
                          foregroundColor: Colors.white,
                          icon: CupertinoIcons.delete,
                          label: '削除',
                        ),
                      ],
                    ),
                    child: _buildDisplayTile(key, note),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDisplayTile(int key, NoteData note) {
    return MyCustomListTile(
      title: Text(
        note.title ?? '無題のノート',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '${DateFormat('yyyy/MM/dd HH:mm').format(note.createdAt)}  ${note.pages.length}ページ',
      ),
      onTitleTap: () => _startEditing(key, note),
      // ★ スライドを閉じるロジックが不要になったため、シンプルに
      onTap: () => _openNote(key, note),
    );
  }

  Widget _buildEditingTile({required bool isCreating}) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      height: 78,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: CupertinoTheme.of(context).primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CupertinoTextField.borderless(
                controller: _textController,
                focusNode: _focusNode,
                placeholder: 'ノートのタイトル',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                onSubmitted: (_) => _submitEditing(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            onPressed: _submitEditing,
            child: Text(isCreating ? '作成' : '完了'),
          ),
          if (isCreating)
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: const Text('やめる', style: TextStyle(color: CupertinoColors.systemGrey)),
              onPressed: _cancelEditing,
            ),
        ],
      ),
    );
  }
}