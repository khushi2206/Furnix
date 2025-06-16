import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_page.dart';
import 'chat_service.dart';
import 'firestore_service.dart';

class UserListScreen extends StatelessWidget {
  final ChatService _chatService = ChatService();
  final String uid;

  UserListScreen({required this.uid});

  String formatLastMessageTime(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    DateTime now = DateTime.now();
    String formattedTime = DateFormat('h:mm a').format(dateTime);

    if (now.year == dateTime.year && now.month == dateTime.month &&
        now.day == dateTime.day) {
      return formattedTime;
    }

    DateTime yesterday = now.subtract(Duration(days: 1));
    if (yesterday.year == dateTime.year && yesterday.month == dateTime.month &&
        yesterday.day == dateTime.day) {
      return "Yesterday";
    }

    return DateFormat('MMM dd, yyyy').format(dateTime);
  }

  String _generateChatRoomId(String receiverID) {
    List<String> ids = [uid, receiverID];
    ids.sort();
    return ids.join('_');
  }

  Future<Timestamp?> _fetchLastMessageTime(String chatRoomId) async {
    try {
      DocumentSnapshot chatRoomSnapshot = await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(chatRoomId)
          .get();

      var chatRoomData = chatRoomSnapshot.data() as Map<String, dynamic>?;

      if (chatRoomData != null) {
        return chatRoomData['lastMessageTime'] as Timestamp?;
      }
    } catch (e) {
      print("Error fetching last message time: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chats"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder(
        stream: _chatService.getUsersStream(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text("Error");
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            var users = snapshot.data as List<Map<String, dynamic>>;
            users = users.where((userData) => userData['uid'] != uid).toList();

            List<Future<Map<String, dynamic>>> futureTimestamps = users.map((userData) async {
              String chatRoomId = _generateChatRoomId(userData['uid']);
              Timestamp? lastMessageTime = await _fetchLastMessageTime(chatRoomId);
              return {
                'userData': userData,
                'lastMessageTime': lastMessageTime,
              };
            }).toList();

            return FutureBuilder<List<Map<String, dynamic>>>(
              future: Future.wait(futureTimestamps),
              builder: (context, futureSnapshot) {
                if (futureSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (futureSnapshot.hasError || !futureSnapshot.hasData) {
                  return Center(child: Text("Error fetching chat data"));
                }

                var usersWithTimestamps = futureSnapshot.data!;
                usersWithTimestamps.sort((a, b) {
                  Timestamp? timestampA = a['lastMessageTime'];
                  Timestamp? timestampB = b['lastMessageTime'];

                  if (timestampA == null) return 1;
                  if (timestampB == null) return -1;

                  return timestampB.compareTo(timestampA);
                });

                return ListView(
                  children: usersWithTimestamps.map<Widget>((userData) =>
                      _buildUserListItem(userData['userData'], context)).toList(),
                );
              },
            );
          }

          return Center(child: Text("No users found"));
        },
      ),
    );
  }

  Widget _buildUserListItem(Map<String, dynamic> userData, BuildContext context) {
    String receiverEmail = userData['name'] ?? "";
    String receiverID = userData['uid'] ?? "";
    String profileImageUrl = userData['image'] ?? "";
    String receiverName = userData['name'] ?? "No name";
    String chatRoomId = _generateChatRoomId(receiverID);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('chat_rooms').doc(chatRoomId).snapshots(),
      builder: (context, chatRoomSnapshot) {
        if (chatRoomSnapshot.connectionState == ConnectionState.waiting) {
          return ListTile(
            title: Text(receiverName),
            subtitle: Text("Loading..."),
            leading: CircleAvatar(
              backgroundImage: profileImageUrl.isNotEmpty
                  ? NetworkImage(profileImageUrl)
                  : AssetImage('assets/user.png') as ImageProvider,
            ),
          );
        }

        var chatRoomData = chatRoomSnapshot.data?.data() as Map<String, dynamic>?;
        String lastMessage = chatRoomData?['lastMessage'] ?? "Start messaging";
        Timestamp? lastMessageTimeStamp = chatRoomData?['lastMessageTime'];
        String lastMessageTime = lastMessageTimeStamp != null
            ? formatLastMessageTime(lastMessageTimeStamp)
            : "Start messaging";

        String unreadCountKey = "unreadCount_$uid";
        int unreadCount = chatRoomData?[unreadCountKey] ?? 0;

        return ListTile(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(receiverEmail: receiverEmail, receiverID: receiverID, senderID: '',),
              ),
            );
            await _chatService.markMessagesAsRead(chatRoomId, uid);
          },
          contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          leading: CircleAvatar(
            backgroundImage: profileImageUrl.isNotEmpty
                ? NetworkImage(profileImageUrl)
                : AssetImage('assets/user.png') as ImageProvider,
          ),
          title: Text(receiverName, style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Row(
            children: [
              Text(lastMessage, overflow: TextOverflow.ellipsis),
            ],
          ),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(lastMessageTime, style: TextStyle(fontSize: 12.0, color: Colors.grey)),
              if (unreadCount > 0)
                Container(
                  margin: EdgeInsets.only(top: 4.0),
                  padding: EdgeInsets.all(6.0),
                  decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12.0)),
                  child: Text(unreadCount.toString(), style: TextStyle(color: Colors.white, fontSize: 12.0)),
                ),
            ],
          ),
        );
      },
    );
  }
}
