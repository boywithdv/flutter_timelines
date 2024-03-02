import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timelines/helper/helper_methods.dart';
import 'package:flutter_timelines/view/components/custom_text_field.dart';
import 'package:flutter_timelines/view/components/custom_drawer.dart';
import 'package:flutter_timelines/view/components/wall_post.dart';
import 'package:flutter_timelines/view/pages/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String postid = "";
  final currentUser = FirebaseAuth.instance.currentUser!;
  //textController
  final textController = TextEditingController();
  //sign user logout
  void signOut() {
    FirebaseAuth.instance.signOut();
  }

  void postMessage() async {
    // textFieldに何かがある場合のみ投稿する
    if (textController.text.isNotEmpty) {
      // Firebaseに保存
      String username = '';
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser.email)
          .get();
      if (userSnapshot.exists) {
        username = userSnapshot.get('username');
      }

      FirebaseFirestore.instance.collection('UserPosts').add({
        'UserEmail': currentUser.email,
        'Username': username,
        'Message': textController.text,
        'TimeStamp': Timestamp.now(),
        'Likes': [],
      });
    }
    // textfieldをクリアする
    setState(() {
      textController.clear();
    });
  }

  //プロフィールページに遷移
  void goToProfilePage() {
    //navigatorを戻す
    Navigator.pop(context);
    //プロフィルページ遷移
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(
          postId: postid,
        ),
      ),
    );
  }

  Future<void> getLoading() async {
    // 新しい情報を取得する処理をここに追加する
    // 例: データベースから最新の投稿内容を取得する

    // データベースから最新の投稿内容を取得する場合の例
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('UserPosts')
        .orderBy("TimeStamp", descending: false)
        .get();

    // 新しい情報を反映させるためにStateを更新する
    setState(() {
      // ここで新しい情報を反映させる処理を追加する
      // 例: 新しい投稿内容を変数に保存するなど
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        title: const Text(
          "The Wall",
        ),
        actions: [
          IconButton(
            onPressed: signOut,
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      drawer: CustomDrawer(
        onProfileTap: goToProfilePage,
        onSignOut: signOut,
      ),
      body: RefreshIndicator(
        edgeOffset: 0,
        color: Theme.of(context).colorScheme.primary,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        onRefresh: () async {
          // RefreshIndicatorが引っ張られたときの処理を定義する
          await getLoading();
          // ここでは新しい投稿内容を取得するために、一度Stateをリセットしてから再度投稿内容を取得する
        },
        child: Center(
          child: Column(
            children: [
              // 投稿
              Expanded(
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('UserPosts')
                      .orderBy("TimeStamp", descending: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return ListView.builder(
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            // メッセージ取得
                            final post = snapshot.data!.docs[index];
                            postid = post.id;
                            return WallPost(
                              message: post['Message'],
                              user: post['UserEmail'],
                              username: post['Username'],
                              postId: post.id,
                              likes: List<String>.from(post['Likes'] ?? []),
                              time: formatDate(post['TimeStamp']),
                              commentCount: [],
                            );
                          });
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ' + snapshot.error.toString()),
                      );
                    }
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                ),
              ),
              // 投稿メッセージ
              Padding(
                padding: const EdgeInsets.all(25.0),
                child: Row(
                  children: [
                    //textField
                    Expanded(
                      child: CustomTextField(
                        controller: textController,
                        hintText: 'Write something on the wall... ',
                        obscureText: false,
                      ),
                    ),
                    //post Button
                    IconButton(
                      onPressed: () {
                        postMessage();
                      },
                      icon: const Icon(Icons.arrow_circle_up),
                    )
                  ],
                ),
              ),
              // logged in as
              Text(
                "Logged in as: " + currentUser.email!,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(
                height: 50,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
