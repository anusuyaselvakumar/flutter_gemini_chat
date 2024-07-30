import 'package:hive_flutter/hive_flutter.dart';

part 'settings.g.dart';

@HiveType(typeId: 2)
class Settings extends HiveObject {
  @HiveField(0)
  bool isDarkMode = false;

  @HiveField(1)
  bool shouldSpeak = false;

  Settings({
    required this.isDarkMode,
    required this.shouldSpeak,
  });
}
