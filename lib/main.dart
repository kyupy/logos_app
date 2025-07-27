import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logos_app/models/note_data.dart';
import 'package:logos_app/pages/home_page.dart';

Future<void> main() async {
  // Flutterアプリが実行される前に、ウィジェットの初期化を保証します
  WidgetsFlutterBinding.ensureInitialized();

  // アプリがサポートする画面の向きを設定
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Hiveを初期化
  await Hive.initFlutter();

  // 作成したモデルクラスのアダプターを登録
  Hive.registerAdapter(NoteDataAdapter());
  Hive.registerAdapter(StrokeDataAdapter());
  Hive.registerAdapter(NotePointDataAdapter());
  Hive.registerAdapter(PageDataAdapter());

  // データベース（Box）を開く
  await Hive.openBox<NoteData>('notes_box');
  await Hive.openBox('settings_box');

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