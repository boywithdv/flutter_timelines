import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timelines/helper/helper_methods.dart';
import 'package:flutter_timelines/view/components/text_box.dart';
import 'package:flutter_timelines/view/components/wall_post.dart';
import 'package:flutter_timelines/view/components/post_form.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String postid = "";
  List<WallPost> posts = []; //textController
  final textController = TextEditingController();
  // user
  final currentUser = FirebaseAuth.instance.currentUser!;
  //all users
  final usersCollection = FirebaseFirestore.instance.collection('Users');
  final usersCollectionUpdateName =
      FirebaseFirestore.instance.collection('UserPosts');
  @override
  void initState() {
    super.initState();
    getLoading(); // 初期表示時にデータを取得
  }

  // edit field
  Future<void> editField(String field) async {
    String newValue = "";
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Edit $field',
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          autofocus: true,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter new $field',
            hintStyle: TextStyle(color: Colors.grey),
          ),
          onChanged: (value) {
            newValue = value;
          },
        ),
        actions: [
          //cancel button
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                return;
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              )),
          //save button
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(newValue);
              // update firestore
              if (field == 'username') {
                FirebaseAuth.instance.currentUser!.updateDisplayName(newValue);
                await usersCollectionUpdateName
                    .where('UserId', isEqualTo: currentUser.uid)
                    .get()
                    .then(
                  (querySnapshot) {
                    querySnapshot.docs.forEach(
                      (doc) {
                        doc.reference.update({'Username': newValue});
                      },
                    );
                  },
                );
                await FirebaseFirestore.instance
                    .collection('Users')
                    .doc(currentUser.uid)
                    .update({'username': newValue});
                updateCommentsWithNewUsername(newValue);
              } else if (field == 'bio') {
                await FirebaseFirestore.instance
                    .collection('Users')
                    .doc(currentUser.uid)
                    .update({'bio': newValue});
              }
            },
            child: Text(
              'Save',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // プロフィール名を変更した後に呼び出される関数
  void updateCommentsWithNewUsername(String newUsername) async {
    // 現在のユーザーがログインしているか確認
    if (currentUser != null) {
      // 自身が投稿したコメントを取得
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collectionGroup('Comments')
          .where('CommentedUserEmail', isEqualTo: currentUser.email)
          .get();

      // 取得したコメントを更新
      for (QueryDocumentSnapshot commentDoc in querySnapshot.docs) {
        // コメントのドキュメントを更新
        await commentDoc.reference.update({
          'CommentedBy': newUsername, // 新しいユーザ名で更新
        });
      }
    }
  }

  Future<void> getLoading() async {
    // 新しい情報を取得する処理をここに追加する
    // 例: データベースから最新の投稿内容を取得する

    // データベースから最新の投稿内容を取得する場合の例
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('UserPosts')
        .where('UserId', isEqualTo: currentUser.uid)
        .get();

    // 新しい情報を反映させるためにStateを更新する
    setState(
      () {
        // snapshotのデータを使ってUIを更新する
        // ここでは新しい投稿内容をStateにセットしてUIを再構築する
        // snapshotから投稿データを取得し、Stateにセットする
        posts = snapshot.docs
            .map(
              (doc) => WallPost(
                key: Key(doc.id),
                message: doc['Message'],
                user: doc['UserEmail'],
                username: doc['Username'],
                postId: doc.id,
                likes: List<String>.from(doc['Likes'] ?? []),
                time: formatDate(
                  doc['TimeStamp'],
                ),
                uid: doc['UserId'],
              ),
            )
            .toList();
      },
    );
  }

  void backToHomePage() {
    // 戻る際にNavigator.pop()の引数として更新されたデータを渡す
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: backToHomePage,
        ),
        title: const Text(
          'ProfilePage',
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Users')
                  .doc(currentUser.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final userData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  return ListView(
                    children: [
                      const SizedBox(
                        height: 50,
                      ),
                      //profile pic
                      const Icon(
                        Icons.person,
                        size: 72,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      //user email
                      Text(
                        currentUser.email!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      //user details
                      Padding(
                        padding: const EdgeInsets.only(left: 25.0),
                        child: Text(
                          "ユーザー情報",
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      //username
                      CustomTextBox(
                        text: userData['username'],
                        sectionName: 'ニックネーム',
                        onPressed: () => editField('username'),
                        email: currentUser.email,
                      ),
                      //bio
                      CustomTextBox(
                        text: userData['bio'],
                        sectionName: '自己紹介',
                        onPressed: () => editField('bio'),
                        email: currentUser.email,
                      ),
                      const SizedBox(
                        height: 50,
                      ),
                      //user posts
                      Padding(
                        padding: const EdgeInsets.only(left: 25.0),
                        child: Text(
                          "My Posts",
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      StreamBuilder(
                        stream: FirebaseFirestore.instance
                            .collection('UserPosts')
                            .where('UserId', isEqualTo: currentUser.uid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: snapshot.data!.docs.length,
                              itemBuilder: (context, index) {
                                // メッセージ取得
                                final post = snapshot.data!.docs[index];
                                postid = post.id;

                                return WallPost(
                                  key: Key(post.id),
                                  message: post['Message'],
                                  user: post['UserId'],
                                  username: post['Username'],
                                  postId: post.id,
                                  likes: List<String>.from(post['Likes'] ?? []),
                                  time: formatDate(post['TimeStamp']),
                                  uid: post['UserId'],
                                );
                              },
                            );
                          } else if (snapshot.hasError) {
                            return Center(
                              child:
                                  Text('Error: ' + snapshot.error.toString()),
                            );
                          }
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                      ),
                    ],
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Error${snapshot.error}'),
                  );
                }
                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
            ),
          ),
        ],
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
