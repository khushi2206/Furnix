import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get user stream
  Stream<List<Map<String, dynamic>>> getUsersStream(String currentUserID) {
    return _firestore.collection("users").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final user = doc.data();
        user['uid'] = doc.id; // Add UID to the user data
        return user;
      }).toList();
    });
  }

  // Fetch receiver's UID based on email
  Future<String?> fetchReceiverUID(String receiverEmail) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: receiverEmail)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id; // UID is the document ID
      } else {
        print('Receiver not found!');
        return null;
      }
    } catch (e) {
      print('Error fetching receiver UID: $e');
      return null;
    }
  }

  // Send message to the receiver
  Future<void> sendMessage(String receiverID, String message) async {
    try {
      final String currentUserID = _auth.currentUser!.uid; // Sender's UID
      final String currentUserEmail = _auth.currentUser!.email!; // Sender's Email

      final Timestamp timestamp = Timestamp.now();

      List<String> ids = [currentUserID, receiverID];
      ids.sort();
      String chatRoomId = ids.join('_');

      // Create or update the chat room metadata (last message, last message time)
      await _firestore.collection("chat_rooms").doc(chatRoomId).set({
        "users": [currentUserID, receiverID],
        "lastMessage": message,
        "lastMessageTime": timestamp,
        "lastMessageSender": currentUserID,
        "unreadCount_$receiverID": FieldValue.increment(1),  // Increment unread count for receiver
      }, SetOptions(merge: true));

      // Add the new message to the messages sub-collection
      await _firestore
          .collection("chat_rooms")
          .doc(chatRoomId)
          .collection("messages")
          .add({
        "senderID": currentUserID,
        "senderEmail": currentUserEmail,
        "receiverID": receiverID,
        "message": message,
        "timestamp": timestamp,
        "isRead": false, // Initially mark as unread
      });
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  // Get messages between two users
  Stream<QuerySnapshot> getMessages(String userID, String otherUserID) {
    List<String> ids = [userID, otherUserID];
    ids.sort();
    String chatRoomID = ids.join('_');

    return _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .orderBy("timestamp", descending: false)
        .snapshots();
  }

  // Mark all messages as read for a specific user
  Future<void> markMessagesAsRead(String chatRoomId, String currentUserID) async {
    try {
      QuerySnapshot messagesSnapshot = await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .where('receiverID', isEqualTo: currentUserID)
          .where('isRead', isEqualTo: false)
          .get();

      // Mark all messages as read
      for (var message in messagesSnapshot.docs) {
        await message.reference.update({'isRead': true});
      }

      // Reset unread count
      await _firestore.collection("chat_rooms").doc(chatRoomId).update({
        "unreadCount_$currentUserID": 0, // Reset unread count
      });
    } catch (e) {
      print("Error marking messages as read: $e");
    }
  }
}
