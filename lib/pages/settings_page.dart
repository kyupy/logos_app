import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final Box _settingsBox = Hive.box('settings_box');
  bool _stylusOnlyDrawing = true;

  @override
  void initState() {
    super.initState();
    // 「スタイラスのみ」設定を読み込む。デフォルトはオン(true)
    _stylusOnlyDrawing = _settingsBox.get('stylusOnlyDrawing', defaultValue: true);
  }

  void _onSwitchChanged(bool value) {
    setState(() {
      _stylusOnlyDrawing = value;
    });
    // スイッチの状態をHiveに保存する
    _settingsBox.put('stylusOnlyDrawing', value);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        previousPageTitle: 'ノート一覧',
        middle: Text('設定'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            CupertinoListSection.insetGrouped(
              header: const Text('描画設定'),
              children: [
                CupertinoListTile(
                  title: const Text('スタイラスのみで描画する'),
                  subtitle: const Text('オン: 指で移動、ペンで描画\nオフ: 2本指で移動、1本指とペンで描画'),
                  trailing: CupertinoSwitch(
                    value: _stylusOnlyDrawing,
                    onChanged: _onSwitchChanged,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}