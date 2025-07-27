// lib/pages/home_page.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logos_app/models/note_data.dart';
import 'package:logos_app/pages/note_page.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Box<NoteData> _notesBox = Hive.box<NoteData>('notes_box');

  void _createNewNote() {
    final firstPage = PageData(strokes: []);
    final newNote = NoteData(
      pages: [firstPage],
      createdAt: DateTime.now(),
      lastOpenedPageIndex: 0,
    );
    _notesBox.add(newNote).then((int key) {
      Navigator.push(
        context,
        CupertinoPageRoute(builder: (context) => NotePage(noteKey: key)),
      );
    });
  }

  void _openNote(int key, NoteData note) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => NotePage(noteKey: key),
      ),
    );
  }

  void _deleteNote(int key) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('ノートを削除'),
          content: const Text('このノートを本当に削除しますか？この操作は取り消せません。'),
          actions: <CupertinoDialogAction>[
            CupertinoDialogAction(
              child: const Text('キャンセル'),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('削除'),
              onPressed: () {
                _notesBox.delete(key);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _renameNote(int key, NoteData note) {
    final TextEditingController textController = TextEditingController(text: note.title);
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('ノートの名前を変更'),
          content: Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: CupertinoTextField(
              controller: textController,
              placeholder: 'ノートのタイトル',
              autofocus: true,
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  note.title = value;
                  note.save();
                  Navigator.pop(context);
                }
              },
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('キャンセル'),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('保存'),
              onPressed: () {
                final newTitle = textController.text;
                if (newTitle.isNotEmpty) {
                  note.title = newTitle;
                  note.save();
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      // ★★★ 省略されていたナビゲーションバーを補完 ★★★
      navigationBar: CupertinoNavigationBar(
        middle: const Text('logos'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _createNewNote,
          child: const Icon(CupertinoIcons.add),
        ),
      ),
      child: SafeArea(
        // ★★★ 省略されていたValueListenableBuilderの中身を補完 ★★★
        child: ValueListenableBuilder(
          valueListenable: _notesBox.listenable(),
          builder: (context, Box<NoteData> box, _) {
            final notes = box.values.toList().reversed.toList();
            final noteKeys = box.keys.toList().reversed.toList();

            if (notes.isEmpty) {
              return const Center(child: Text('右上の「+」ボタンから新しいノートを作成します。'));
            }

            return ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                final key = noteKeys[index] as int;

                return Dismissible(
                  key: Key('note_$key'),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    setState(() {});
                  },
                  confirmDismiss: (direction) async {
                    _deleteNote(key);
                    return false;
                  },
                  background: Container(
                    color: CupertinoColors.destructiveRed,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: const Icon(CupertinoIcons.delete, color: Colors.white),
                  ),
                  child: CupertinoListTile(
                    title: Text(
                      note.title ?? '無題のノート',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${DateFormat('yyyy/MM/dd HH:mm').format(note.createdAt)}  ${note.pages.length}ページ',
                    ),
                    onTitleTap: () => _renameNote(key, note),
                    onTap: () => _openNote(key, note),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class CupertinoListTile extends StatelessWidget {
  final Widget title;
  final Widget subtitle;
  final VoidCallback onTap;
  final VoidCallback? onTitleTap;

  const CupertinoListTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.onTitleTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: CupertinoColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onTitleTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: DefaultTextStyle(
                  style: CupertinoTheme.of(context).textTheme.textStyle,
                  child: title,
                ),
              ),
            ),
            DefaultTextStyle(
              style: CupertinoTheme.of(context).textTheme.tabLabelTextStyle,
              child: subtitle,
            ),
            const Divider(height: 1),
          ],
        ),
      ),
    );
  }
}