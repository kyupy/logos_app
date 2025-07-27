// lib/main.dart

import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Hiveをインポート
import 'package:logos_app/models/note_data.dart'; // 作成したモデルをインポート
import 'package:logos_app/pages/home_page.dart';

// main関数をFutureに変更し、async/awaitを使えるようにします
Future<void> main() async {
  // Flutterアプリが実行される前に、ウィジェットの初期化を保証します
  WidgetsFlutterBinding.ensureInitialized();

  // Hiveを初期化します
  await Hive.initFlutter();

  // ステップ2で作成したモデルクラスのアダプターを登録します
  Hive.registerAdapter(NoteDataAdapter());
  Hive.registerAdapter(StrokeDataAdapter());
  Hive.registerAdapter(NotePointDataAdapter());
  Hive.registerAdapter(PageDataAdapter());

  // データを保存するためのBoxを開きます。
  // これでアプリのどこからでも 'notes_box' という名前でアクセスできます。
  await Hive.openBox<NoteData>('notes_box');

  runApp(const LogosApp());
}

class LogosApp extends StatelessWidget {
  const LogosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'logos',
      theme: CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: CupertinoColors.systemBlue,
        scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
      ),
      home: HomePage(),
    );
  }
}