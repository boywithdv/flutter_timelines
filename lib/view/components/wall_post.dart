import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timelines/helper/helper_methods.dart';
import 'package:flutter_timelines/view/components/comment.dart';
import 'package:flutter_timelines/view/components/comment_button.dart';
import 'package:flutter_timelines/view/components/like_button.dart';

class WallPost extends StatefulWidget {
  final String message;
  final String user;
  final String time;
  final String postId;
  final List<String> likes;
  const WallPost({
    super.key,
    required this.message,
    required this.user,
    required this.postId,
    required this.likes,
    required this.time,
  });

  @override
  State<WallPost> createState() => _WallPostState();
}

class _WallPostState extends State<WallPost> {
  //user
  final currentuser = FirebaseAuth.instance.currentUser!;
  bool isLiked = false;
  //comment text controller
  final TextEditingController _commentTextController = TextEditingController();
  @override
  void initState() {
    super.initState();
    isLiked = widget.likes.contains(currentuser.email);
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
        'Likes': FieldValue.arrayUnion([currentuser.email])
      });
    } else {
      //if the post is now unliked, remove the user's email from the 'Likes' field
      postRef.update({
        'Likes': FieldValue.arrayRemove([currentuser.email])
      });
    }
  }

  // add a comment
  void addComment(String commentText) {
    //write the comment to firestore under the comments collection for this post
    FirebaseFirestore.instance
        .collection('UserPosts')
        .doc(widget.postId)
        .collection('Comments')
        .add({
      "CommentText": commentText,
      "CommentedBy": currentuser.email,
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
                  child: Text("Cancel"),
                ),
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      margin: EdgeInsets.only(top: 25, left: 25, right: 25),
      padding: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // wallpost
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // message
              Text(widget.message),
              const SizedBox(
                height: 5,
              ),
              Row(
                children: [
                  Text(
                    widget.user,
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  Text(
                    '-',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  Text(
                    widget.time,
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          //buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // LIKE
              Column(
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
                width: 10,
              ),
              // COMMNET
              Column(
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
                    '0',
                    style: TextStyle(color: Colors.grey),
                  )
                ],
              ),
            ],
          ),
          //comments under the post
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('UserPosts')
                .doc(widget.postId)
                .collection("Comments")
                .orderBy("CommentTime", descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              //show loading circle if no data yet
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              return ListView(
                shrinkWrap: true, //for nested lists
                physics: const NeverScrollableScrollPhysics(),
                children: snapshot.data!.docs.map((doc) {
                  // get the comment
                  final commentData = doc.data() as Map<String, dynamic>;
                  //return the comment
                  return Comment(
                    text: commentData['CommentText'],
                    user: commentData['CommentedBy'],
                    time: formatDate(commentData['CommentTime']),
                  );
                }).toList(),
              );
            },
          ),
        ],
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
