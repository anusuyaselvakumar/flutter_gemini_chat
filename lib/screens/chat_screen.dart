import 'package:flutter/material.dart';
import 'package:flutter_gemini_chat/providers/chat_provider.dart';
import 'package:flutter_gemini_chat/widgets/bottom_chat_field.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  //controller
  final TextEditingController _messageController = TextEditingController();
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder:
          (BuildContext context, ChatProvider chatProvider, Widget? child) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            title: const Text('Chat with Gemini'),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Expanded(
                    child: chatProvider.inChatMessages.isEmpty
                        ? const Center(
                            child: Text('No message yet'),
                          )
                        : ListView.builder(
                            itemCount: chatProvider.inChatMessages.length,
                            itemBuilder: (context, index) {
                              final message =
                                  chatProvider.inChatMessages[index];
                              return ListTile(
                                title: Text(message.message.toString()),
                              );
                            },
                          ),
                  ),
                  //input field
                  BottomChatField(
                    chatProvider: chatProvider,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
