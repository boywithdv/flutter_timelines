import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timelines/view/components/follow_button.dart';

class TestUserFollow extends StatefulWidget {
  final String followUserName;
  final String followUserEmail;
  final String followUid;
  List<String> following;

  TestUserFollow({
    Key? key,
    required this.followUserName,
    required this.following,
    required this.followUid,
    required this.followUserEmail,
  }) : super(key: key);

  @override
  State<TestUserFollow> createState() => _TestUserFollowState();
}

class _TestUserFollowState extends State<TestUserFollow> {
  late bool isFollow;
  final currentUser = FirebaseAuth.instance.currentUser!;

  @override
  void initState() {
    super.initState();
    isFollow = widget.following.contains(widget.followUserEmail);
  }

  void toggleFollow() {
    setState(() {
      isFollow = !isFollow;
    });
    DocumentReference postRef =
        FirebaseFirestore.instance.collection('Users').doc(currentUser.uid);
    if (isFollow) {
      postRef.update({
        'Following': FieldValue.arrayUnion([widget.followUserEmail])
      });
    } else {
      postRef.update({
        'Following': FieldValue.arrayRemove([widget.followUserEmail])
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 10),
      child: Container(
        width: 435,
        height: 75,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.followUserEmail,
                ),
              ),
              StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('Users')
                    .doc(currentUser.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    // Firestoreから現在のユーザーのデータを取得する
                    var userData = snapshot.data;

                    // 現在のユーザーがフォローしているかどうかを判定する
                    isFollow =
                        userData!['Following'].contains(widget.followUserEmail);

                    return FollowButton(
                      isFollow: isFollow,
                      onTap: toggleFollow,
                    );
                  }
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
