import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timelines/helper/helper_methods.dart';
import 'package:flutter_timelines/view/components/text_box.dart';
import 'package:flutter_timelines/view/components/wall_post.dart';
import 'package:flutter_timelines/view/pages/home_page.dart';

class ProfilePage extends StatefulWidget {
  final String postId;
  const ProfilePage({super.key, required this.postId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
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
                    .where('UserEmail', isEqualTo: currentUser.email)
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
                    .doc(currentUser.email)
                    .update({'username': newValue});
              } else if (field == 'bio') {
                await FirebaseFirestore.instance
                    .collection('Users')
                    .doc(currentUser.email)
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

  void backToHomePage() {
    // 戻る際にNavigator.pop()の引数として更新されたデータを渡す
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => HomePage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var begin = Offset(-1.0, 0.0);
          var end = Offset.zero;
          var curve = Curves.ease;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: backToHomePage,
        ),
        title: Text(
          'ProfilePage',
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Users')
                  .doc(currentUser.email)
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
                        sectionName: 'ユーザー名',
                        onPressed: () => editField('username'),
                      ),
                      //bio
                      CustomTextBox(
                        text: userData['bio'],
                        sectionName: 'bio',
                        onPressed: () => editField('bio'),
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
                            .where('UserEmail', isEqualTo: currentUser.email)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
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
    );
  }
}
