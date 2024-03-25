import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_timelines/controller/follower_counter.dart';
import 'package:flutter_timelines/controller/following_counter.dart';
import 'package:flutter_timelines/helper/helper_methods.dart';
import 'package:flutter_timelines/view/components/follow_button.dart';
import 'package:flutter_timelines/view/components/text_box.dart';
import 'package:flutter_timelines/view/components/user_chat_button.dart';
import 'package:flutter_timelines/view/components/wall_post.dart';
import 'package:flutter_timelines/view/components/post_form.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_timelines/view/components/chat_page.dart';

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
  bool isFollowing = false;
  String postid = "";
  //textController
  final textController = TextEditingController();
  // user
  final currentUser = FirebaseAuth.instance.currentUser!;
  //all users
  final usersCollection = FirebaseFirestore.instance.collection('Users');
  final usersCollectionUpdateName =
      FirebaseFirestore.instance.collection('UserPosts');
  int followerCount = 0;
  int followingCount = 0;
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

  @override
  void initState() {
    super.initState();
    checkFollowing();
    fetchFollowerCount();
    fetchFollowingCount();
  }

  void checkFollowing() async {
    DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
        .instance
        .collection('Users')
        .doc(currentUser.uid)
        .get();
    var userData = snapshot.data();
    if (userData != null && userData['Following'] != null) {
      setState(() {
        isFollowing =
            (userData['Following'] as List<dynamic>).contains(widget.email);
      });
    }
  }

// フォロワー数を取得するメソッド
  void fetchFollowerCount() async {
    try {
      // FollowerCounter クラスのインスタンスを作成
      FollowerCounter followerCounter = FollowerCounter();
      // FollowerCounter クラスの getFollowersCount メソッドを使用してフォロワー数を取得
      int count = await followerCounter.getFollowersCount(widget.uid);
      // 取得したフォロワー数を followerCount 変数に代入
      setState(() {
        followerCount = count;
      });
    } catch (error) {
      // エラーが発生した場合の処理
      print('Error fetching followers count: $error');
    }
  }

// フォロー中を取得するメソッド
  void fetchFollowingCount() async {
    try {
      // FollowerCounter クラスのインスタンスを作成
      FollowingCounter followerCounter = FollowingCounter();
      // FollowerCounter クラスの getFollowersCount メソッドを使用してフォロワー数を取得
      int count = await followerCounter.getFollowingCount(widget.uid);
      // 取得したフォロワー数を followerCount 変数に代入
      setState(() {
        followingCount = count;
      });
    } catch (error) {
      // エラーが発生した場合の処理
      print('Error fetching followers count: $error');
    }
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

  void followButton() {
    setState(() {
      isFollowing = !isFollowing;
    });
    DocumentReference followRef =
        FirebaseFirestore.instance.collection('Users').doc(currentUser.uid);
    if (isFollowing) {
      followRef.update({
        'Following': FieldValue.arrayUnion([widget.email])
      });
    } else {
      followRef.update({
        'Following': FieldValue.arrayRemove([widget.email])
      });
    }
    DocumentReference followerRef =
        FirebaseFirestore.instance.collection('Users').doc(widget.uid);
    if (isFollowing) {
      followerRef.update({
        'Followers': FieldValue.arrayUnion([currentUser.email])
      }).then((value) {
        // フォロワー数を再取得して更新
        fetchFollowerCount();
      });
    } else {
      followerRef.update({
        'Followers': FieldValue.arrayRemove([currentUser.email])
      }).then((value) {
        // フォロワー数を再取得して更新
        fetchFollowerCount();
      });
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

                      Padding(
                        padding: const EdgeInsets.only(
                            left: 30, top: 15, bottom: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: 10, right: 10),
                              child: Text(
                                "${followingCount} フォロー", // ここにフォロワー数を表示
                                style: TextStyle(
                                  fontSize: 15,
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 10, right: 10),
                              child: Text(
                                "$followerCount フォロワー", // ここにフォロワー数を表示
                                style: TextStyle(
                                  fontSize: 15,
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (currentUser.uid != widget.uid)
                        Container(
                          height: 50,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              UserChatButton(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (BuildContext context) =>
                                          ChatPage(
                                        uid: widget.uid,
                                        username: widget.user,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              SizedBox(
                                width: 140,
                                child: FollowButton(
                                  isFollow: isFollowing,
                                  onTap: followButton,
                                ),
                              ),
                            ],
                          ),
                        ),
                      //user posts
                      Padding(
                        padding: const EdgeInsets.only(left: 25.0),
                        child: Text(
                          "Posts",
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
