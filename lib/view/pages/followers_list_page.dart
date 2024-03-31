import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timelines/view/components/follow_list_tile.dart';

class FollowersListPage extends StatefulWidget {
  const FollowersListPage({Key? key});

  @override
  State<FollowersListPage> createState() => _FollowersListPageState();
}

class _FollowersListPageState extends State<FollowersListPage> {
  final currentUser = FirebaseAuth.instance.currentUser;
  List<FollowListTile> users = [];

  @override
  void initState() {
    super.initState();
    fetchFollowingUsers();
  }

  Future<void> fetchFollowingUsers() async {
    var currentUserDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUser!.uid)
        .get();
    List<dynamic> following = currentUserDoc['Followers'];

    List<FollowListTile> followingUsers = [];
    for (String userEmail in following) {
      var userDocSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('email', isEqualTo: userEmail)
          .get();
      if (userDocSnapshot.docs.isNotEmpty) {
        var userDoc = userDocSnapshot.docs.first;
        var userTile = FollowListTile(
          key: Key(userDoc.id),
          following: List<String>.from(currentUserDoc['Followers']),
          followUserName: userDoc['username'],
          followUid: userDoc['uid'],
          followUserEmail: userDoc['email'],
        );
        followingUsers.add(userTile);
      }
    }

    setState(() {
      users = followingUsers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Followers"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  return users[index];
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/**
 Column(
          children: [
            Padding(
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
                          "test@gmail.com",
                        ),
                      ),
                      FollowButton(
                        isFollow: isFollow,
                        followUserName: '',
                      )
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 10, top: 10),
              child: Container(
                width: 435,
                height: 75,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                  ),
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
                          "oootoco@gmail.com",
                        ),
                      ),
                      FollowButton(
                        isFollow: isFollow,
                        followUserName: '',
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
 */