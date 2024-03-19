import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PostForm extends StatefulWidget {
  @override
  _PostFormState createState() => _PostFormState();
}

class _PostFormState extends State<PostForm> {
  final TextEditingController _textEditingController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser!;
  //textController

  void postMessage() async {
    // textFieldに何かがある場合のみ投稿する
    if (_textEditingController.text.isNotEmpty) {
      // Firebaseに保存
      String username = '';
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser.uid)
          .get();
      if (userSnapshot.exists) {
        username = userSnapshot.get('username');
      }

      FirebaseFirestore.instance.collection('UserPosts').add(
        {
          'UserId': currentUser.uid,
          'UserEmail': currentUser.email,
          'Username': username,
          'Message': _textEditingController.text,
          'TimeStamp': Timestamp.now(),
          'Likes': [],
        },
      );
    }
    Navigator.pop(context, true);
    // textfieldをクリアする
    setState(() {
      _textEditingController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Post'),
        actions: [
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              // 送信処理をここに記述
              postMessage();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 150,
          child: TextField(
            controller: _textEditingController,
            decoration: const InputDecoration(
              hintText: 'どんなデートスポットがあった?',
              border: InputBorder.none, // ボーダーを取り除く
            ),
            maxLines: null, // 複数行の入力を可能にする
          ),
        ),
      ),
    );
  }
}
