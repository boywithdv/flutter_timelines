import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_timelines/helper/helper_methods.dart';
import 'package:flutter_timelines/view/components/comment.dart';
import 'package:flutter_timelines/view/components/comment_button.dart';
import 'package:flutter_timelines/view/components/delete_button.dart';
import 'package:flutter_timelines/view/components/like_button.dart';
import 'package:flutter_timelines/view/pages/home_page.dart';

class PostPage extends StatefulWidget {
  final String message;
  final String user;
  final String email;
  final String time;
  final String postId;
  List<String> likes;
  final List<String> commentCount;
  PostPage(
      {super.key,
      required this.message,
      required this.user,
      required this.time,
      required this.postId,
      required this.likes,
      required this.commentCount,
      required this.email});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  //user
  final currentUser = FirebaseAuth.instance.currentUser!;
  bool isLiked = false;
  //comment text controller
  final TextEditingController _commentTextController = TextEditingController();
  @override
  void initState() {
    super.initState();
    isLiked = widget.likes.contains(currentUser.email);
  }

// PostPageのStateクラス内
// backToHomePageメソッドを追加
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

// いいねボタンのtoggleLikeメソッドを修正
  void toggleLike() {
    setState(() {
      isLiked = !isLiked;
    });
    DocumentReference postRef =
        FirebaseFirestore.instance.collection('UserPosts').doc(widget.postId);
    if (isLiked) {
      postRef.update({
        'Likes': FieldValue.arrayUnion([currentUser.email])
      }).then((value) {
        setState(() {
          widget.likes.add(currentUser.email!);
        });
      });
    } else {
      postRef.update({
        'Likes': FieldValue.arrayRemove([currentUser.email])
      }).then((value) {
        setState(() {
          widget.likes.remove(currentUser.email);
        });
      });
    }
  }

  // add a comment
  void addComment(String commentText) async {
    //get the user's email address
    final userDataSnapshot = await FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUser.email)
        .get();
    // ユーザ名を取得
    final userData = userDataSnapshot.data() as Map<String, dynamic>;
    final username = userData['username'] as String;

    //write the comment to firestore under the comments collection for this post
    FirebaseFirestore.instance
        .collection('UserPosts')
        .doc(widget.postId)
        .collection('Comments')
        .add(
      {
        "CommentText": commentText,
        "CommentedBy": username,
        "CommentedUserEmail": currentUser.email,
        "CommentTime": Timestamp.now()
      },
    );
  }

  // show a dialog box for adding comment
  void showCommentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add Comment"),
        content: TextField(
          controller: _commentTextController,
          decoration: InputDecoration(hintText: 'Write a comment..'),
        ),
        actions: [
          // post button
          TextButton(
            onPressed: () {
              //add comment
              addComment(_commentTextController.text);
              //pop box
              Navigator.pop(context);
              //clear controller
              _commentTextController.clear();
            },
            child: Text("Post"),
          ),
          // cancel button
          TextButton(
            onPressed: () {
              //pop box
              Navigator.pop(context);
              //clear controller
              _commentTextController.clear();
            },
            child: Text("Cancel"),
          ),
        ],
      ),
    );
  }

  //delete a post
  void deletePost() {
    //show a dialog box asking for confirmation before deleting the post
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Post"),
        content: const Text("Are you sure you want to delete this post?"),
        actions: [
          //cancel button
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          //delete button
          TextButton(
            onPressed: () async {
              //delete the comments from firestore first
              //(if you only delete the post, the comments will still be stored in firestore)
              final commentDocs = await FirebaseFirestore.instance
                  .collection("UserPosts")
                  .doc(widget.postId)
                  .collection("Comments")
                  .get();
              for (var doc in commentDocs.docs) {
                await FirebaseFirestore.instance
                    .collection("UserPosts")
                    .doc(widget.postId)
                    .collection("Comments")
                    .doc(widget.postId)
                    .delete();
              }
              //then delete the post
              FirebaseFirestore.instance
                  .collection("UserPosts")
                  .doc(widget.postId)
                  .collection("Comments")
                  .doc(widget.postId)
                  .delete()
                  .then(
                    (value) => print("post deleted"),
                  )
                  .catchError(
                    (error) => print("failed to delete post: $error"),
                  );
              //dissmiss the dialog
              Navigator.pop(context);
              // 戻る際にNavigator.pop()の引数として更新されたデータを渡す
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      HomePage(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    var begin = Offset(-1.0, 0.0);
                    var end = Offset.zero;
                    var curve = Curves.ease;

                    var tween = Tween(begin: begin, end: end)
                        .chain(CurveTween(curve: curve));

                    return SlideTransition(
                      position: animation.drive(tween),
                      child: child,
                    );
                  },
                ),
              );
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: // 戻るボタンを追加
          AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: backToHomePage,
        ),
        title: const Text("ポスト"),
      ),
      body: Column(
        children: [
          // 投稿内容
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 10),
            child: Container(
              margin: const EdgeInsets.only(left: 15, right: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // group of text (message + user email )
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.user,
                          style: TextStyle(color: Colors.grey[900]),
                        ),

                        Text(
                          widget.time,
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        // message
                        Text(widget.message),
                        const SizedBox(
                          height: 5,
                        ),
                      ],
                    ),
                  ),
                  //delete button
                  if (widget.email == currentUser.email)
                    DeleteButton(
                      onTap: deletePost,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Divider(
            color: Theme.of(context).colorScheme.primary,
          ),
          // buttons
          Padding(
            padding: const EdgeInsets.only(left: 25, right: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // LIKE
                //like button
                LikeButton(isLiked: isLiked, onTap: toggleLike),
                const SizedBox(
                  height: 5,
                ),
                // like count
                Text(
                  widget.likes.length.toString(),
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(
                  width: 10,
                ),
                // COMMNET
                // comment button
                CommentButton(
                  onTap: showCommentDialog,
                ),
                const SizedBox(
                  height: 5,
                ),
                // comment count
                const Text(
                  "",
                  style: TextStyle(color: Colors.grey),
                )
              ],
            ),
          ),
          Divider(
            color: Theme.of(context).colorScheme.secondary,
          ),
          Text(
            "comments",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          // これいかがコメント
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('UserPosts')
                  .doc(widget.postId)
                  .collection('Comments')
                  .orderBy("CommentTime", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      // メッセージ取得
                      final post = snapshot.data!.docs[index];
                      String postid = post.id;
                      return Comment(
                        // Keyを追加することでいいねの崩れを修正することができる
                        key: Key(post.id),
                        text: post['CommentText'],
                        user: post['CommentedBy'], commentedPostId: postid,
                        wallPostId: widget.postId,

                        time: formatDate(
                          post['CommentTime'],
                        ),
                        commentUserEmail: post['CommentedUserEmail'],
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
        ],
      ),
    );
  }
}