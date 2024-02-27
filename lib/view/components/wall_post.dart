import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timelines/view/components/like_button.dart';

class WallPost extends StatefulWidget {
  final String message;
  final String user;
  final String postId;
  final List<String> likes;
  const WallPost({
    super.key,
    required this.message,
    required this.user,
    required this.postId,
    required this.likes,
  });

  @override
  State<WallPost> createState() => _WallPostState();
}

class _WallPostState extends State<WallPost> {
  //user
  final currentuser = FirebaseAuth.instance.currentUser!;
  bool isLiked = false;
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      margin: EdgeInsets.only(top: 25, left: 25, right: 25),
      padding: EdgeInsets.all(10),
      child: Row(
        children: [
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
          SizedBox(
            width: 20,
          ),
          // message and user email
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.user,
                style: TextStyle(color: Colors.grey[500]),
              ),
              const SizedBox(
                height: 10,
              ),
              Text(widget.message)
            ],
          )
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