import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_timelines/test/chat_service.dart';
import 'package:flutter_timelines/test/message_tile.dart';
import 'package:flutter_timelines/view/components/chat_text_field.dart';

class ChatPage extends StatefulWidget {
  final String uid;
  final String username;
  const ChatPage({
    Key? key,
    required this.uid,
    required this.username,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  void sendMessage() async {
    // only send message if there is something to send
    if (_messageController.text.isNotEmpty) {
      await _chatService.sendMessage(widget.uid, _messageController.text);
      // clear the text controller after sending the message
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.username),
      ),
      body: Column(
        children: [
          //message
          Expanded(
            child: _buildMessageList(),
          ),
          //user input
          _buildMessageInput(),
          const SizedBox(
            height: 30,
          )
        ],
      ),
    );
  }

  // build message list
  Widget _buildMessageList() {
    return StreamBuilder(
        stream: _chatService.getMessages(
            widget.uid, _firebaseAuth.currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text("Error${snapshot.error}");
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Text("Loading...");
          }
          return ListView(
            children: snapshot.data!.docs
                .map((document) => _buildmessageItem(document))
                .toList(),
          );
        });
  }

  // build message item
  Widget _buildmessageItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
    return MessageTile(
      message: data["message"],
      sender: data['senderEmail'],
      sentByMe: data['senderId'] == _firebaseAuth.currentUser!.uid,
    );
  }

  // build message input
  Widget _buildMessageInput() {
    return Container(
      width: 370,
      child: Row(
        children: [
          // textfield
          Expanded(
            child: ChatTextField(
              controller: _messageController,
              hintText: '入力',
              obscureText: false,
            ),
          ),
          //send button
          IconButton(
            onPressed: sendMessage,
            icon: Container(
              width: 50,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Colors.deepPurple, Colors.blue], // グラデーションの色のリスト
                  begin: Alignment.centerLeft, // グラデーションの開始位置
                  end: Alignment.centerRight, // グラデーションの終了位置
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.send,
                  size: 25,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
