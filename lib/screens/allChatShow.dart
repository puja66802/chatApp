import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../bloc/chat_bloc.dart';
import 'chat_screen.dart';
import 'all_users.dart';
import 'login_screen.dart';

class AllChatScreen extends StatelessWidget {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

   AllChatScreen({super.key});

  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "";
    return DateFormat('hh:mm a').format(timestamp.toDate());
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Logout"),
          content: Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut(); // Logout user
                Navigator.of(context).pop(); // Close the dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()), // Navigate to login
                );
              },
              child: Text("Logout", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text("Chats"),
      //   actions: [
      //     IconButton(
      //       icon: Icon(Icons.logout, color: Colors.black),
      //       onPressed: () => _logout(context),
      //     ),
      //   ],
      // ),

      appBar: AppBar(
        title: Text("Chats"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.black),
            onPressed: () {
              _logout(context); // Call the logout function
            },
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('users', arrayContains: currentUserId)
            .orderBy('lastMessageTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          print("📡 ///////////////////// StreamBuilder triggered!");

          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var chats = snapshot.data!.docs;
          if (chats.isEmpty) return Center(child: Text("No chats yet"));

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              var chat = chats[index];
              Map<String, dynamic>? chatData = chat.data() as Map<String, dynamic>?;

              if (chatData == null) return SizedBox.shrink();

              List users = List.from(chatData['users']);
              String otherUserId = users.first == currentUserId ? users.last : users.first;

              // ✅ Ignore unread count if user is chatting with themselves
              int unreadCount = 0;
              if (otherUserId != currentUserId) {
                unreadCount = chatData['unreadCount']?[currentUserId] ?? 0;
              }

              print("🔍 Checking unread messages... unreadCount = $unreadCount");

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) return SizedBox.shrink();

                  var userData = userSnapshot.data!;
                  String username = userData['username'];

                  // ✅ Show "You" if chatting with self
                  String displayName = (otherUserId == currentUserId) ? "$username (You)" : username;

                  return ListTile(
                    leading: CircleAvatar(child: Icon(Icons.person)),
                    title: Text(displayName), // ✅ Show "You" for self
                    subtitle: Text(
                      chatData['lastMessage'] ?? "No messages",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(formatTimestamp(chatData['lastMessageTime'])), // ✅ Ensure timestamp is formatted
                        if (unreadCount > 0)
                          Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            child: Text(
                              unreadCount.toString(),
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                    onTap: () async {
                      // ✅ Reset unread count when opening chat (not needed for self-chat)
                      if (otherUserId != currentUserId) {
                        await FirebaseFirestore.instance.collection('chats').doc(chat.id).update({
                          'unreadCount.${FirebaseAuth.instance.currentUser!.uid}': 0
                        });
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BlocProvider.value(
                            value: BlocProvider.of<ChatBloc>(context),
                            child: ChatScreen(receiverId: otherUserId, receiverName: username),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AllUsersScreen())),
        child: Icon(Icons.message, color: Colors.white),
      ),
    );
  }
}
