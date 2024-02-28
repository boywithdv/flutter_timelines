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
  final currentUser = FirebaseAuth.instance.currentUser!;
  //textController
  final textController = TextEditingController();
  //sign user logout
  void signOut() {
    FirebaseAuth.instance.signOut();
  }

  void postMessage() {
    //only post if there is something in the textfield
    if (textController.text.isNotEmpty) {
      //store in firebase
      FirebaseFirestore.instance.collection('UserPosts').add({
        'UserEmail': currentUser.email,
        'Message': textController.text,
        'TimeStamp': Timestamp.now(),
        'Likes': [],
      });
    }
    //clear the textField
    setState(() {
      textController.clear();
    });
  }

  //navigate to profile page
  void goToProfilePage() {
    //pop menu drawer
    Navigator.pop(context);
    //go to profile page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfilePage(),
      ),
    );
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
      body: Center(
        child: Column(
          children: [
            // the wall
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
                        final post = snapshot.data!.docs[index];
                        final commentsRef = FirebaseFirestore.instance
                            .collection("UserPosts")
                            .doc(post.id)
                            .collection("Comments");

                        return StreamBuilder(
                          stream: commentsRef.snapshots(),
                          builder: (context, commentsSnapshot) {
                            if (commentsSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            }
                            if (commentsSnapshot.hasError) {
                              return Text('Error: ${commentsSnapshot.error}');
                            }
                            final List<String> comments = List<String>.from(
                                commentsSnapshot.data!.docs.map((doc) =>
                                    (doc.data()['comment'] ?? '') as String));

                            return WallPost(
                              message: post['Message'],
                              user: post['UserEmail'],
                              postId: post.id,
                              likes: List<String>.from(post['Likes'] ?? []),
                              time: formatDate(post['TimeStamp']),
                              commentCount: comments,
                            );
                          },
                        );
                      },
                    );
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
            //post message
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
                      onPressed: postMessage,
                      icon: const Icon(Icons.arrow_circle_up))
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
    );
  }
}
