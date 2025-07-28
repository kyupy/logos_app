import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

// 自身のプロジェクトのパスに合わせてください
import 'package:logos_app/models/note_data.dart';
import 'package:logos_app/pages/note_page.dart';
import 'package:logos_app/pages/settings_page.dart';
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
      CupertinoPageRoute(builder: (context) => NotePage(noteKey: key)),
    );
  }

  Future<bool?> _showDeleteConfirmationDialog(BuildContext context) async {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('ノートを削除'),
          content: const Text('このノートを本当に削除しますか？この操作は取り消せません。'),
          actions: <CupertinoDialogAction>[
            CupertinoDialogAction(
              child: const Text('キャンセル'),
              onPressed: () => Navigator.pop(dialogContext, false),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('削除'),
              onPressed: () => Navigator.pop(dialogContext, true),
            ),
          ],
        );
      },
    );
  }

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
        _textController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _textController.text.length,
        );
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
            if (_editingNoteKey != null || _isCreatingNewNote) {
              _submitEditing();
            }
          },
          child: ValueListenableBuilder(
            valueListenable: _notesBox.listenable(),
            builder: (context, Box<NoteData> box, _) {
              final noteCount = box.length;

              if (noteCount == 0 && !_isCreatingNewNote) {
                return const Center(child: Text("ノートがありません"));
              }

              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: noteCount + (_isCreatingNewNote ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isCreatingNewNote && index == 0) {
                    return _buildEditingTile(isCreating: true);
                  }

                  // ★★★ パフォーマンス改善: toList().reversedを避け、インデックスで直接アクセス ★★★
                  final noteIndexInBox = noteCount - 1 - (_isCreatingNewNote ? index - 1 : index);
                  final key = box.keyAt(noteIndexInBox) as int;
                  final note = box.getAt(noteIndexInBox)!;
                  
                  final isEditingThisNote = _editingNoteKey == key;

                  if (isEditingThisNote) {
                    return _buildEditingTile(isCreating: false);
                  }

                  return Dismissible(
                    key: ValueKey(key),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: CupertinoColors.destructiveRed,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      alignment: Alignment.centerRight,
                      child: const Icon(
                        CupertinoIcons.delete,
                        color: Colors.white,
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      return await _showDeleteConfirmationDialog(context);
                    },
                    onDismissed: (direction) {
                        _notesBox.delete(key);
                    },
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
                color: CupertinoTheme.of(
                  context,
                ).primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CupertinoTextField.borderless(
                controller: _textController,
                focusNode: _focusNode,
                placeholder: 'ノートのタイトル',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
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
              child: const Text(
                'やめる',
                style: TextStyle(color: CupertinoColors.systemGrey),
              ),
              onPressed: _cancelEditing,
            ),
        ],
      ),
    );
  }
}