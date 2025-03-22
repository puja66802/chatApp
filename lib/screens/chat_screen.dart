import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Import for formatting timestamp
import 'package:testapp/screens/push_notification.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  ChatScreen({required this.receiverId, required this.receiverName});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;


  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    String messageText = _messageController.text.trim();

    // Send message via BLoC
    context.read<ChatBloc>().add(SendMessage(
      receiverId: widget.receiverId,
      message: messageText,
    ));

    _messageController.clear();

    // ✅ Fetch recipient's FCM Token from Firestore
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.receiverId).get();

    if (userDoc.exists) {
      String? receiverFcmToken = userDoc['fcmToken'];

      if (receiverFcmToken != null) {
        // ✅ Send Push Notification
        await sendPushNotification(receiverFcmToken, widget.receiverName, messageText);
      }
    }
  }


  // 🔹 Function to format timestamp into "hh:mm a"
  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "";
    return DateFormat('hh:mm a').format(timestamp.toDate());
  }

  // 🔹 Function to show a confirmation dialog and delete the chat
  void _deleteChats() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Chat"),
        content: Text("Are you sure you want to delete this chat? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Close dialog
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _deleteChatFromFirestore();
            },
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 🔹 Function to delete chat from Firebase Firestore
  Future<void> _deleteChatFromFirestore() async {
    try {
      String chatId = currentUserId.compareTo(widget.receiverId) < 0
          ? '$currentUserId-${widget.receiverId}'
          : '${widget.receiverId}-$currentUserId';

      // Reference to the chat messages collection
      CollectionReference chatMessages = FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages');

      // Delete all messages in the chat
      var messagesSnapshot = await chatMessages.get();
      for (var doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete the chat document itself
      await FirebaseFirestore.instance.collection('chats').doc(chatId).delete();

      print("Chat deleted successfully!");
    } catch (e) {
      print("Error deleting chat: $e");
    }
  }

  // 🔹 Placeholder function for calling feature
  void _startCall() {
    print("Calling feature will be implemented later...");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverName),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == "delete") {
                _deleteChats();
              } else if (value == "call") {
                _startCall();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: "delete",
                child: Text("Delete Chats for everyone"),
              ),
              PopupMenuItem(
                value: "call",
                child: Text("Calling"),
              ),
            ],
          ),
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(currentUserId.compareTo(widget.receiverId) < 0
                  ? '$currentUserId-${widget.receiverId}'
                  : '${widget.receiverId}-$currentUserId')
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var messageData = messages[index].data() as Map<String, dynamic>;
                    bool isMe = messageData['senderId'] == currentUserId;

                    // 🔹 Extract timestamp
                    Timestamp? timestamp = messageData['timestamp'];
                    String formattedTime = formatTimestamp(timestamp);

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.blue : Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  messageData['message'],
                                  style: TextStyle(
                                    color: isMe ? Colors.white : Colors.black,
                                  ),
                                ),
                                SizedBox(height: 5), // Space between message and timestamp
                                Text(
                                  formattedTime,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isMe ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}