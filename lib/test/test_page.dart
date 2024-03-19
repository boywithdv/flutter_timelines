import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_timelines/test/test_user_follow.dart';

class TestPage extends StatefulWidget {
  const TestPage({Key? key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  final currentUser = FirebaseAuth.instance.currentUser;
  List<TestUserFollow> users = [];
  Future<void> getLoading() async {
    // 新しい情報を取得する処理をここに追加する
    // 例: データベースから最新の投稿内容を取得する

    // データベースから最新の投稿内容を取得する場合の例
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('Users')
        .orderBy("username", descending: true)
        .get();

    // 新しい情報を反映させるためにStateを更新する
    setState(() {
      // snapshotのデータを使ってUIを更新する
      // ここでは新しい投稿内容をStateにセットしてUIを再構築する
      // snapshotから投稿データを取得し、Stateにセットする
      users = snapshot.docs
          .map((user) => TestUserFollow(
                key: Key(user.id),
                following: List<String>.from(user['Following'] ?? []),
                followUserName: user["username"],
                followUid: user["uid"],
                followUserEmail: user["email"],
              ))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Follow & Follower"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            // 投稿
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('Users')
                    .orderBy("username", descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    users.clear();
                    for (var user in snapshot.data!.docs) {
                      final usr = TestUserFollow(
                        key: Key(user.id),
                        following: List<String>.from(user['Following'] ?? []),
                        followUserName: user["username"],
                        followUid: user["uid"],
                        followUserEmail: user["email"],
                      );
                      users.add(usr);
                    }
                    return ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        //users[index] --- usersの中にあるuidが入っている
                        return users[index];
                      },
                    );
                  }
                },
              ),
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