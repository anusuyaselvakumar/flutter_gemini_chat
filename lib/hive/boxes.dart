import 'package:flutter_gemini_chat/constants.dart';
import 'package:flutter_gemini_chat/hive/chat_history.dart';
import 'package:flutter_gemini_chat/hive/settings.dart';
import 'package:flutter_gemini_chat/hive/user_model.dart';
import 'package:hive/hive.dart';

class Boxes {
  //get the chat history box
  static Box<ChatHistory> getChatHistory() =>
      Hive.box<ChatHistory>(Constants.chatHistoryBox);

  //get the user model box
  static Box<UserModel> getUserModel() =>
      Hive.box<UserModel>(Constants.userModelBox);

  //get the settings box
  static Box<Settings> getSettings() =>
      Hive.box<Settings>(Constants.settingsBox);
}
