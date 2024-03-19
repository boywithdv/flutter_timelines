import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timelines/view/components/delete_button.dart';
import 'package:flutter_timelines/view/components/like_button.dart';

class Comment extends StatefulWidget {
  final String text;
  final String wallPostId;
  final String commentedPostId;
  final String user;
  final String time;
  final String commentUserEmail;
  final void Function()? onTap;
  List<String> likes;

  final void Function()? resetCommentCounter;

  Comment({
    super.key,
    required this.text,
    required this.user,
    required this.time,
    required this.commentedPostId,
    required this.commentUserEmail,
    required this.wallPostId,
    this.resetCommentCounter,
    required this.likes,
    this.onTap,
  });

  @override
  State<Comment> createState() => _CommentState();
}

class _CommentState extends State<Comment> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  int commentCount = 0;
  bool isLiked = false;

  @override
  void initState() {
    super.initState();
    isLiked = widget.likes.contains(currentUser.email);
    fetchCommentCount();
  }

  Future<void> fetchCommentCount() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('UserPosts')
        .doc(widget.wallPostId)
        .collection('Comments')
        .get();
    commentCount = querySnapshot.size;
  }

  void toggleLike() {
    setState(() {
      isLiked = !isLiked;
    });
    //access the document is Firebase
    DocumentReference postRef = FirebaseFirestore.instance
        .collection('UserPosts')
        .doc(widget.wallPostId)
        .collection('Comments')
        .doc(widget.commentedPostId);
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
              //then delete the post
              try {
                // コメントを削除
                await FirebaseFirestore.instance
                    .collection("UserPosts")
                    .doc(widget.wallPostId)
                    .collection("Comments")
                    .doc(widget.commentedPostId)
                    .delete();

                // コメントの削除後、対応する投稿のコメント件数を更新
                widget.resetCommentCounter
                    ?.call(); // resetCommentCounterメソッドを呼び出し
                fetchCommentCount(); // コメント件数を更新する処理

                // ダイアログを閉じる処理...
              } catch (error) {
                print("Failed to delete comment: $error");
              }
              //dissmiss the dialog
              Navigator.pop(context, true);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            blurRadius: 5,
            color: Color(0x3416202A),
            offset: Offset(0, 3),
          ),
        ],
      ),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: widget.onTap,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user,
                        style: TextStyle(
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        widget.time,
                        style: TextStyle(color: Colors.grey[400], fontSize: 10),
                      ),
                    ],
                  ),
                ),
                //comment
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Text(
                    widget.text,
                    softWrap: true,
                  ),
                ),
                Divider(
                  height: 8,
                  thickness: 1,
                  indent: 4,
                  endIndent: 4,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      LikeButton(isLiked: isLiked, onTap: toggleLike),
                      Text(
                        widget.likes.length.toString(),
                        style: TextStyle(
                          color: Colors.grey[500],
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          //delete button
          if (widget.commentUserEmail == currentUser.email)
            DeleteButton(
              onTap: deletePost,
            ),
        ],
      ),
    );
  }
}
