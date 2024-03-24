import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final String? uid;
  DatabaseService({this.uid});
  final currentUser = FirebaseAuth.instance.currentUser!;
  // reference for our collections
  final CollectionReference userCollection =
      FirebaseFirestore.instance.collection('Users');
  final CollectionReference chatCollection =
      FirebaseFirestore.instance.collection("Chats");
  Future gettingUserData(String uid) async {
    QuerySnapshot snapshot =
        await userCollection.where('uid', isEqualTo: currentUser.uid).get();
    return snapshot;
  }

  createChat(String userName, String id, String chatName) async {
    DocumentReference chatDocumentReferences = await chatCollection.add({
      'chatName': chatName,
      'chatIcons': "",
      'admin': "${id}_$userName",
      'chatId': "",
    });
    await chatDocumentReferences.update({
      "members": FieldValue.arrayUnion(["${uid}_$userName"]),
      "chatId": chatDocumentReferences.id,
    });
    DocumentReference userDocumentReferences = userCollection.doc(uid);
    return await userDocumentReferences.update({
      "chat": FieldValue.arrayUnion(["${userDocumentReferences.id}_$chatName"])
    });
  }

  sendMessage(String uid, String username, String email,
      Map<String, dynamic> chatMessageData) async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('Chats').get();

    chatCollection.doc().collection("messages").add(chatMessageData);
    chatCollection.doc().update(
      {
        'recentMessage': chatMessageData['message'],
        'recentMessageSender': chatMessageData['sender'],
        'recentMessageTime': chatMessageData['time'].toString()
      },
    );
  }
}
