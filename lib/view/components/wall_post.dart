import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
/*
import 'package:flutter_timelines/helper/helper_methods.dart';
import 'package:flutter_timelines/view/components/comment.dart';
*/
import 'package:flutter_timelines/view/components/comment_button.dart';
import 'package:flutter_timelines/view/components/delete_button.dart';
import 'package:flutter_timelines/view/components/like_button.dart';
import 'package:flutter_timelines/view/pages/test_page.dart';

class WallPost extends StatefulWidget {
  final String message;
  final String user;
  final String username;
  final String time;
  final String postId;
  List<String> likes;
  final List<String> commentCount;
  WallPost({
    super.key,
    required this.message,
    required this.user,
    required this.postId,
    required this.likes,
    required this.time,
    required this.commentCount,
    required this.username,
  });

  @override
  State<WallPost> createState() => _WallPostState();
}

class _WallPostState extends State<WallPost> {
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

  // toggle like
  void toggleLike() {
    setState(() {
      isLiked = !isLiked;
    });
    //access the document is Firebase
    DocumentReference postRef =
        FirebaseFirestore.instance.collection('UserPosts').doc(widget.postId);
    if (isLiked) {
      //if the post is now liked, add the user's email to the 'Likes' field
      postRef.update({
        'Likes': FieldValue.arrayUnion([currentUser.email])
      });
    } else {
      //if the post is now unliked, remove the user's email from the 'Likes' field
      postRef.update({
        'Likes': FieldValue.arrayRemove([currentUser.email])
      });
    }
  }

  // add a comment
  void addComment(String commentText) {
    //get the user's email address
    String email = currentUser.email!;
    String userEmailAddressisFirst = email.split("@")[0];
    //write the comment to firestore under the comments collection for this post
    FirebaseFirestore.instance
        .collection('UserPosts')
        .doc(widget.postId)
        .collection('Comments')
        .add({
      "CommentText": commentText,
      "CommentedBy": userEmailAddressisFirst,
      "CommentTime": Timestamp.now() //remember to format this when displaying
    });
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
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  void openTestPage() async {
    // データを更新したい場合はNavigator.push()を非同期で実行する

    final updatedData = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TestPage(
          message: widget.message,
          user: widget.username,
          email: widget.user,
          time: widget.time,
          postId: widget.postId,
          likes: widget.likes,
          commentCount: widget.commentCount,
        ),
      ),
    );
    // データを更新
    if (updatedData != null) {
      setState(() {
        // TestPageから戻ってきたlikesのデータを反映
        widget.likes = updatedData;
      });
    }
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
                    .delete();
              }
              //then delete the post
              FirebaseFirestore.instance
                  .collection("UserPosts")
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
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: openTestPage,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              blurRadius: 5,
              color: Color(0x3416202A),
              offset: Offset(0, 3),
            )
          ],
        ),
        margin: EdgeInsets.only(top: 25, left: 25, right: 25),
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // タイムラインの投稿
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // group of text (message + user email )
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.username,
                            style: TextStyle(color: Colors.grey[900]),
                          ),
                          Text(
                            widget.time,
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          // メッセージ
                          Padding(
                            padding: EdgeInsets.only(left: 10),
                            child: Text(
                              widget.message,
                              softWrap: true,
                            ),
                          )
                        ],
                      ),
                    ),
                    //delete button
                    if (widget.user == currentUser.email)
                      DeleteButton(
                        onTap: deletePost,
                      )
                  ],
                ),
                const SizedBox(
                  height: 25,
                ),
                Divider(
                  height: 8,
                  thickness: 1,
                  indent: 4,
                  endIndent: 4,
                  color: Theme.of(context).colorScheme.secondary,
                ),

                //buttons
                Padding(
                  padding: EdgeInsets.only(left: 15, right: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // LIKE
                      Row(
                        children: [
                          //like button
                          LikeButton(isLiked: isLiked, onTap: toggleLike),
                          const SizedBox(
                            height: 5,
                          ),
                          // like count
                          Text(
                            widget.likes.length.toString(),
                            style: TextStyle(color: Colors.grey),
                          )
                        ],
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      // コメント
                      Row(
                        children: [
                          //comment button
                          CommentButton(
                            onTap: showCommentDialog,
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          // comment count
                          Text(
                            "",
                            style: TextStyle(color: Colors.grey),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/**

          //profile pic
          Container(
            decoration:
                BoxDecoration(shape: BoxShape.circle, color: Colors.grey[400]),
            padding: EdgeInsets.all(10),
            child: const Icon(Icons.person),
          ),
 */
