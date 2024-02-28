import 'package:cloud_firestore/cloud_firestore.dart';

class CommentCounter {
  final db = FirebaseFirestore.instance;

  Future<List<CommentData>> commentCount(postid) async {
    final snapshot = await db
        .collection('UserPosts')
        .doc(postid)
        .collection('Comments')
        .get();

    // ドキュメントデータをList<TrainingData>として取得
    final List<CommentData> documents = snapshot.docs.map(
      (QueryDocumentSnapshot<Map<String, dynamic>> e) {
        final data = e.data();
        return CommentData(
          commentText: data['CommentText'],
          commentTime: data['CommentTime'].toDate(),
          commentedBy: data['CommentedBy'], // FirestoreのTimestampをDateTimeに変換
        );
      },
    ).toList();
    // documentsを使って何かしらの処理を行う
    for (var doc in documents) {
      print(doc.commentText);
      print(doc.commentTime);
    }
    return documents; // データを返す
  }
}

class CommentData {
  final String commentText;
  final String commentedBy;
  final DateTime commentTime;
  CommentData(
      {required this.commentText,
      required this.commentTime,
      required this.commentedBy});
}
