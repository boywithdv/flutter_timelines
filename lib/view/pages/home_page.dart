import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timelines/helper/helper_methods.dart';
import 'package:flutter_timelines/view/components/custom_drawer.dart';
import 'package:flutter_timelines/view/components/wall_post.dart';
import 'package:flutter_timelines/view/pages/post_form.dart';
import 'package:flutter_timelines/view/pages/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String postid = "";
  List<WallPost> posts = [];

  final currentUser = FirebaseAuth.instance.currentUser!;
  //textController
  final textController = TextEditingController();
  @override
  void initState() {
    super.initState();
    getLoading(); // 初期表示時にデータを取得
  }

  //sign user logout
  void signOut() {
    setState(() {
      FirebaseAuth.instance.signOut();
    });
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

      FirebaseFirestore.instance.collection('UserPosts').add(
        {
          'UserEmail': currentUser.email,
          'Username': username,
          'Message': textController.text,
          'TimeStamp': Timestamp.now(),
          'Likes': [],
        },
      );
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
        .orderBy("TimeStamp", descending: true)
        .get();

    // 新しい情報を反映させるためにStateを更新する
    setState(() {
      // snapshotのデータを使ってUIを更新する
      // ここでは新しい投稿内容をStateにセットしてUIを再構築する
      // 例: 投稿内容を新しいデータで更新する
      // ただし、UIの更新に関する具体的な処理は、UI構築部分で行う必要があります
      // 以下は仮の例ですので、実際のデータ構造に合わせて修正してください。

      // snapshotから投稿データを取得し、Stateにセットする
      posts = snapshot.docs
          .map((doc) => WallPost(
                key: Key(doc.id),
                message: doc['Message'],
                user: doc['UserEmail'],
                username: doc['Username'],
                postId: doc.id,
                likes: List<String>.from(doc['Likes'] ?? []),
                time: formatDate(doc['TimeStamp']),
              ))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        title: const Text(
          "オープン",
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
                // Expandedウィジェットの構築
                child: StreamBuilder(
                  // StreamBuilderの構築
                  stream: FirebaseFirestore.instance
                      .collection('UserPosts')
                      .orderBy("TimeStamp", descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error: ' + snapshot.error.toString());
                    } else {
                      posts.clear(); // リストをクリアして最新のデータを追加
                      for (var doc in snapshot.data!.docs) {
                        final post = WallPost(
                          key: Key(doc.id),
                          message: doc['Message'],
                          user: doc['UserEmail'],
                          username: doc['Username'],
                          postId: doc.id,
                          likes: List<String>.from(doc['Likes'] ?? []),
                          time: formatDate(doc['TimeStamp']),
                        );
                        posts.add(post); // リストに追加
                      }
                      return ListView.builder(
                        // ListView.builderの構築
                        itemCount: posts.length, // リストの要素数を指定
                        itemBuilder: (context, index) {
                          // 投稿データを使ってUIを構築する
                          return posts[index];
                        },
                      );
                    }
                  },
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (BuildContext context) => PostForm(),
          ),
        ),
        label: Icon(
          Icons.add,
          color: Theme.of(context).colorScheme.onSecondary,
        ),
      ),
    );
  }
}
