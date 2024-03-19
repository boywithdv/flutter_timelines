import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_timelines/helper/helper_methods.dart';
import 'package:flutter_timelines/view/components/text_box.dart';
import 'package:flutter_timelines/view/components/wall_post.dart';
import 'package:flutter_timelines/view/pages/post_form.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfilePage extends StatefulWidget {
  final String message;
  final String uid;
  final String email;
  final String user;
  List<String>? likes;

  UserProfilePage(
      {super.key,
      required this.message,
      required this.email,
      required this.user,
      this.likes,
      required this.uid});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  String postid = "";
  //textController
  final textController = TextEditingController();
  // user
  final currentUser = FirebaseAuth.instance.currentUser!;
  //all users
  final usersCollection = FirebaseFirestore.instance.collection('Users');
  final usersCollectionUpdateName =
      FirebaseFirestore.instance.collection('UserPosts');
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
                await usersCollectionUpdateName
                    .where('UserId', isEqualTo: widget.uid)
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
                    .doc(widget.uid)
                    .update({'username': newValue});
                updateCommentsWithNewUsername(newValue);
              } else if (field == 'bio') {
                await FirebaseFirestore.instance
                    .collection('Users')
                    .doc(widget.uid)
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
        title: Text(
          widget.user,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Users')
                  .doc(widget.uid)
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
                        widget.email,
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
                        email: widget.email,
                      ),
                      //bio
                      CustomTextBox(
                        text: userData['bio'],
                        sectionName: '自己紹介',
                        onPressed: () => editField('bio'),
                        email: widget.email,
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
                            .where('UserEmail', isEqualTo: widget.email)
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
                                  user: post['UserEmail'],
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
