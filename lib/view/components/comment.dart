import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timelines/view/components/delete_button.dart';

class Comment extends StatefulWidget {
  final String text;
  final String wallPostId;
  final String commentedPostId;
  final String user;
  final String time;
  final String commentUserEmail;
  const Comment(
      {super.key,
      required this.text,
      required this.user,
      required this.time,
      required this.commentedPostId,
      required this.commentUserEmail,
      required this.wallPostId});

  @override
  State<Comment> createState() => _CommentState();
}

class _CommentState extends State<Comment> {
  final currentUser = FirebaseAuth.instance.currentUser!;
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
              await FirebaseFirestore.instance
                  .collection("UserPosts")
                  .doc(widget.wallPostId)
                  .collection("Comments")
                  .doc(widget.commentedPostId)
                  .delete()
                  .catchError(
                    (error) => print("failed to delete post: $error"),
                  );
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
      padding: const EdgeInsets.all(15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                Text(
                  widget.time,
                  style: TextStyle(color: Colors.grey[400]),
                ),
                //comment
                Text(
                  widget.text,
                  softWrap: true,
                )
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
