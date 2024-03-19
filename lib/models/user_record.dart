import 'package:cloud_firestore/cloud_firestore.dart';

class UserRecord {
  final String email;
  final String displayName;
  final String photoUrl;
  final String uid;
  final String phoneNumber;
  final List<DocumentReference> followers; // フォロワーのリスト
  final List<DocumentReference> following; // フォローしているユーザーのリスト

  UserRecord({
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.uid,
    required this.phoneNumber,
    required this.followers,
    required this.following,
  });

  factory UserRecord.fromMap(Map<String, dynamic> data) {
    // followersの取得
    List<DocumentReference> followers = [];
    if (data['followers'] != null) {
      List<dynamic> followersData = data['followers'];
      followers = followersData.map(
        (ref) {
          return ref as DocumentReference;
        },
      ).toList();
    }

    // followingの取得
    List<DocumentReference> following = [];
    if (data['following'] != null) {
      List<dynamic> followingData = data['following'];
      following = followingData.map(
        (ref) {
          return ref as DocumentReference;
        },
      ).toList();
    }

    return UserRecord(
      email: data['email'] ?? '',
      displayName: data['username'] ?? '',
      photoUrl: data['photo_url'] ?? '',
      uid: data['uid'] ?? '',
      phoneNumber: data['phone_number'] ?? '',
      followers: followers,
      following: following,
    );
  }
}
