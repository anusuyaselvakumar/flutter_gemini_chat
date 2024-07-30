import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gemini_chat/api/api_service.dart';
import 'package:flutter_gemini_chat/constants.dart';
import 'package:flutter_gemini_chat/hive/chat_history.dart';
import 'package:flutter_gemini_chat/hive/settings.dart';
import 'package:flutter_gemini_chat/hive/user_model.dart';
import 'package:flutter_gemini_chat/models/message.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart' as path;
import 'package:uuid/uuid.dart';

class ChatProvider extends ChangeNotifier {
  //list of messages
  final List<Message> _inChatMessages = [];

  //page Controller
  final PageController _pageController = PageController();

  //images file list
  List<XFile> _imagesFileList = [];

  //index of the current screen
  int _currentIndex = 0;

  //current chatId
  String _currentChatId = '';

  //initialize generative model
  GenerativeModel? _model;

  //initialize text model
  GenerativeModel? _textModel;

  //initialize vision model
  GenerativeModel? _visionModel;

  //current model
  String _modelType = 'gemini-pro';

  //loading bool
  bool _isLoading = false;

  //getters
  List<Message> get inChatMessages => _inChatMessages;

  PageController get pageController => _pageController;

  List<XFile> get imagesFileList => _imagesFileList;

  int get currentIndex => _currentIndex;

  String get currentChatId => _currentChatId;

  GenerativeModel? get model => _model;

  GenerativeModel? get textModel => _textModel;

  GenerativeModel? get visionModel => _visionModel;

  String get modelType => _modelType;

  bool get isLoading => _isLoading;

  //setters

  //set inChatMessage
  Future<void> setInChatMessages({required String chatId}) async {
    //get messages from Hive database
    final messagesFromDB = await loadMessagesFromDB(chatId: chatId);

    for (var message in messagesFromDB) {
      if (inChatMessages.contains(message)) {
        debugPrint('Message already exists');
        continue;
      }

      _inChatMessages.add(message);
    }
    notifyListeners();
  }

  //load messages from db
  Future<List<Message>> loadMessagesFromDB({required String chatId}) async {
    //open the box of this chatId
    await Hive.openBox('${Constants.chatMessagesBox}$chatId');

    final messageBox = Hive.box('${Constants.chatMessagesBox}$chatId');

    final newData = messageBox.keys.map(
      (e) {
        final message = messageBox.get(e);
        final messageData = Message.fromMap(Map<String, dynamic>.from(message));
        return messageData;
      },
    ).toList();
    notifyListeners();
    return newData;
  }

  //set file list
  void setImagesFileList({required List<XFile> imagesList}) {
    _imagesFileList = imagesList;
    notifyListeners();
  }

  //set the current model
  String setCurrentModel({required String newModel}) {
    _modelType = newModel;
    notifyListeners();
    return newModel;
  }

  //function to set the model based on bool isTextOnly
  Future<void> setModel({required bool isTextOnly}) async {
    if (isTextOnly) {
      _model = _textModel ??
          GenerativeModel(
            model: setCurrentModel(newModel: 'gemini-pro'),
            apiKey: ApiService.apiKey,
          );
    } else {
      _model = _visionModel ??
          GenerativeModel(
            model: setCurrentModel(newModel: 'gemini-pro'),
            apiKey: ApiService.apiKey,
          );
    }
    notifyListeners();
  }

  //set current page index
  void setCurrentIndex({required int newIndex}) {
    _currentIndex = newIndex;
    notifyListeners();
  }

  //set current chat id
  void setCurrentChatId({required String newChatId}) {
    _currentChatId = newChatId;
    notifyListeners();
  }

  //set loading
  void setLoading({required bool value}) {
    _isLoading = value;
    notifyListeners();
  }

  //send message to gemini and get the streamed response
  Future<void> sendMessage(
      {required String message, required bool isTextOnly}) async {
    //set the model
    await setModel(isTextOnly: isTextOnly);

    //set loading
    setLoading(value: true);

    //get chatId
    String chatId = getChatId();

    //list of history messages
    List<Content> history = [];

    //get the chat history
    history = await getHistory(chatId: chatId);

    //get the imagesURLs
    List<String> imagesURLs = getImagesURLs(isTextOnly: isTextOnly);

    //get user message
    final userMessage = Message(
      messageId: '',
      chatId: chatId,
      role: Role.user,
      message: StringBuffer(message),
      imagesURLs: imagesURLs,
      timeSent: DateTime.now(),
    );

    //add this message to the list on inChatMessage
    _inChatMessages.add(userMessage);
    notifyListeners();

    if (currentChatId.isEmpty) {
      setCurrentChatId(newChatId: chatId);
    }

    //send message to model and wait for response
    // await sendMessageAndWaitForResponse(
    //   message: message,
    //   chatId: chatId,
    //   isTextOnly: isTextOnly,
    //   history: history,
    //   userMessage: userMessage,
    // );
  }

  //get the images URLs
  List<String> getImagesURLs({required bool isTextOnly}) {
    List<String> imagesURLs = [];
    if (!isTextOnly) {
      for (var image in imagesFileList) {
        imagesURLs.add(image.path);
      }
    }
    return imagesURLs;
  }

  Future<List<Content>> getHistory({required String chatId}) async {
    List<Content> history = [];
    if (currentChatId.isNotEmpty) {
      await setInChatMessages(chatId: chatId);

      for (var message in inChatMessages) {
        if (message.role == Role.user) {
          history.add(Content.text(message.message.toString()));
        } else {
          history.add(Content.model([TextPart(message.message.toString())]));
        }
      }
    }
    return history;
  }

  String getChatId() {
    if (currentChatId.isEmpty) {
      return const Uuid().v4();
    } else {
      return currentChatId;
    }
  }

  //init Hive box
  static initHive() async {
    final dir = await path.getApplicationDocumentsDirectory();
    Hive.init(dir.path);
    await Hive.initFlutter(Constants.geminiDB);

    //register adaptors
    if (Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ChatHistoryAdapter());
      //open the chat History box
      await Hive.openBox<ChatHistory>(Constants.chatHistoryBox);
    }
    if (Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(UserModelAdapter());
      //open the user model box
      await Hive.openBox<UserModel>(Constants.userModelBox);
    }

    if (Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SettingsAdapter());
      //open the settings box
      await Hive.openBox<Settings>(Constants.settingsBox);
    }
  }
}
