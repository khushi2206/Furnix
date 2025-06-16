import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderID;
  final String senderEmail;
  final String receiverID;
  final String message;
  final Timestamp timestamp;

  Message({
    required this.senderID,
    required this.senderEmail,
    required this.receiverID,
    required this.message,
    required this.timestamp,
  });

  // Convert to map
  Map<String, dynamic> toMap() {
    return {
      'senderID': senderID,
      'senderEmail': senderEmail,
      'receiverID': receiverID,
      'message': message,
      'timestamp': timestamp,
    };
  }

  // Convert Firestore document to Message object
  factory Message.fromMap(Map<String, dynamic> map) {
    try {
      if (map['timestamp'] is Timestamp) {
        return Message(
          senderID: map['senderID'] ?? '',
          senderEmail: map['senderEmail'] ?? '',
          receiverID: map['receiverID'] ?? '',
          message: map['message'] ?? '',
          timestamp: map['timestamp'],
        );
      } else {
        // If the timestamp is not in the expected format, throw an error
        throw FormatException("Invalid format for 'timestamp'. Expected 'Timestamp'.");
      }
    } catch (e) {
      print("Error converting map to Message: $e");
      throw FormatException("Error parsing the message data: $e");
    }
  }
}
