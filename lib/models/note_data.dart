import 'package:hive/hive.dart';

part 'note_data.g.dart';

// ★ PageDataクラスを新たに追加
@HiveType(typeId: 3) // ★ typeIdが他のクラスと被らないようにする
class PageData extends HiveObject {
  @HiveField(0)
  late List<StrokeData> strokes;

  PageData({required this.strokes});
}

// トップレベルのNoteDataクラス
@HiveType(typeId: 0)
class NoteData extends HiveObject {
  // ★ List<StrokeData> から List<PageData> に変更
  @HiveField(0)
  late List<PageData> pages;

  @HiveField(1)
  DateTime createdAt;

  // ★ 最後に開いていたページのインデックスを保存
  @HiveField(2, defaultValue: 0)
  int lastOpenedPageIndex;

  // ★ タイトルを追加
  @HiveField(3)
  String? title;

  NoteData({
    required this.pages,
    required this.createdAt,
    this.lastOpenedPageIndex = 0,
    this.title
  });
}

// StrokeDataクラス (変更なし)
@HiveType(typeId: 1)
class StrokeData extends HiveObject {
  @HiveField(0)
  late List<NotePointData> points;

  // strokeWidthフィールドを完全に削除
  StrokeData({required this.points});
}

// NotePointDataクラス (★ pressureフィールドを削除)
@HiveType(typeId: 2)
class NotePointData extends HiveObject {
  @HiveField(0)
  double? x;
  @HiveField(1)
  double? y;

  NotePointData({this.x, this.y});
}