import 'package:cloud_firestore/cloud_firestore.dart';

class FollowingCounter {
  final db = FirebaseFirestore.instance;
  Future<int> getFollowingCount(String userId) async {
    try {
      // ユーザーのドキュメントを取得
      DocumentSnapshot<Map<String, dynamic>> userSnapshot =
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(userId)
              .get();

      // ユーザーのデータが存在するか確認
      if (userSnapshot.exists) {
        // ユーザーのデータから'followers'フィールドのリストを取得し、その長さを返す
        List<dynamic> followers = userSnapshot.get('Following');
        return followers.length;
      } else {
        // ユーザーのデータが存在しない場合は0を返す
        return 0;
      }
    } catch (error) {
      // エラーが発生した場合は例外をスロー
      throw ('Error fetching followers count: $error');
    }
  }
}
