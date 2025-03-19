import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/chat_bloc.dart';
import 'chat_screen.dart';

class AllUsersScreen extends StatefulWidget {
  @override
  _AllUsersScreenState createState() => _AllUsersScreenState();
}

class _AllUsersScreenState extends State<AllUsersScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final String currentUserName = FirebaseAuth.instance.currentUser!.displayName ?? "You"; // ✅ Fetch current user's name

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Select User")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No users found"));
          }

          var users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index];
              String userId = user.id;
              String username = user['username'];

              // ✅ Add "(self)" if it's the logged-in user
              if (userId == currentUserId) {
                username = "$username (You)";
              }

              return ListTile(
                leading: CircleAvatar(child: Icon(Icons.person)),
                title: Text(username, style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  // Navigate to ChatScreen with selected user's details
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BlocProvider.value(
                        value: BlocProvider.of<ChatBloc>(context), // Provide the existing ChatBloc
                        child: ChatScreen(receiverId: userId, receiverName: username),
                      ),
                    ),
                  );

                },
              );
            },
          );
        },
      ),
    );
  }
}
