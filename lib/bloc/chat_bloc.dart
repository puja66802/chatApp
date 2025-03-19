import 'package:flutter_bloc/flutter_bloc.dart';
import 'chat_event.dart';
import 'chat_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc() : super(ChatInitial()) {
    on<FetchChats>(_onFetchChats);
    on<SendMessage>(_onSendMessage);
  }

  Future<void> _onFetchChats(FetchChats event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    try {
      final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

      FirebaseFirestore.instance
          .collection('chats')
          .where('users', arrayContains: currentUserId)
          .orderBy('lastMessageTime', descending: true)
          .snapshots()
          .listen((querySnapshot) {
        emit(ChatLoaded(querySnapshot.docs)); // 🔥 Real-time updates!
      });
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }


  // Future<void> _onSendMessage(SendMessage event, Emitter<ChatState> emit) async {
  //   try {
  //     final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  //     final String chatId = currentUserId.compareTo(event.receiverId) < 0
  //         ? '$currentUserId-${event.receiverId}'
  //         : '${event.receiverId}-$currentUserId';
  //
  //     final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
  //     final chatSnapshot = await chatRef.get();
  //
  //     if (chatSnapshot.exists) {
  //       Map<String, dynamic> chatData = chatSnapshot.data()!;
  //
  //       // Increase unread count for receiver
  //       int unreadCount = chatData['unreadCount']?[event.receiverId] ?? 0;
  //
  //       await chatRef.set({
  //         'users': [currentUserId, event.receiverId],
  //         'lastMessage': event.message,
  //         'lastMessageTime': FieldValue.serverTimestamp(),
  //         'unreadCount.${event.receiverId}': unreadCount + 1, // 🔥 Increment unread count
  //       }, SetOptions(merge: true));
  //     }
  //
  //     await FirebaseFirestore.instance
  //         .collection('chats')
  //         .doc(chatId)
  //         .collection('messages')
  //         .add({
  //       'senderId': currentUserId,
  //       'receiverId': event.receiverId,
  //       'message': event.message,
  //       'timestamp': FieldValue.serverTimestamp(),
  //     });
  //
  //     if (!emit.isDone) {
  //       emit(MessageSent());
  //     }
  //   } catch (e) {
  //     if (!emit.isDone) {
  //       emit(ChatError(e.toString()));
  //     }
  //   }
  // }

  // Future<void> _onSendMessage(SendMessage event, Emitter<ChatState> emit) async {
  //   try {
  //     final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  //     final String chatId = currentUserId.compareTo(event.receiverId) < 0
  //         ? '$currentUserId-${event.receiverId}'
  //         : '${event.receiverId}-$currentUserId';
  //
  //     final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
  //
  //     // 🔹 Create or update chat metadata
  //     // await chatRef.set({
  //     //   'users': [currentUserId, event.receiverId],
  //     //   'lastMessage': event.message,
  //     //   'lastMessageTime': FieldValue.serverTimestamp(),
  //     //   'unreadCount.${event.receiverId}': FieldValue.increment(1), // ✅ Use FieldValue.increment(1)
  //     // }, SetOptions(merge: true));
  //
  //     await chatRef.update({
  //       'lastMessage': event.message,
  //       'lastMessageTime': FieldValue.serverTimestamp(),
  //       'unreadCount.${event.receiverId}': FieldValue.increment(1), // ✅ Fix: Increment unread count correctly
  //     });
  //
  //
  //
  //
  //     // 🔹 Add the new message to the messages subcollection
  //     await chatRef.collection('messages').add({
  //       'senderId': currentUserId,
  //       'receiverId': event.receiverId,
  //       'message': event.message,
  //       'timestamp': FieldValue.serverTimestamp(),
  //     });
  //
  //     if (!emit.isDone) {
  //       emit(MessageSent());
  //     }
  //   } catch (e) {
  //     if (!emit.isDone) {
  //       emit(ChatError(e.toString()));
  //     }
  //   }
  // }

  Future<void> _onSendMessage(SendMessage event, Emitter<ChatState> emit) async {
    try {
      final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
      final String chatId = currentUserId.compareTo(event.receiverId) < 0
          ? '$currentUserId-${event.receiverId}'
          : '${event.receiverId}-$currentUserId';

      final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);

      // 🔹 Check if the chat document exists
      DocumentSnapshot chatDoc = await chatRef.get();

      if (!chatDoc.exists) {
        // ✅ If chat document does NOT exist, create it first
        await chatRef.set({
          'users': [currentUserId, event.receiverId],
          'lastMessage': event.message,
          'lastMessageTime': FieldValue.serverTimestamp(),
          'unreadCount': {event.receiverId: 1}, // ✅ Initialize unread count
        });
      } else {
        // ✅ If chat document exists, update it
        await chatRef.update({
          'lastMessage': event.message,
          'lastMessageTime': FieldValue.serverTimestamp(),
          'unreadCount.${event.receiverId}': FieldValue.increment(1),
        });
      }

      // 🔹 Add the new message to the "messages" subcollection
      await chatRef.collection('messages').add({
        'senderId': currentUserId,
        'receiverId': event.receiverId,
        'message': event.message,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!emit.isDone) {
        emit(MessageSent());
      }
    } catch (e) {
      if (!emit.isDone) {
        emit(ChatError(e.toString()));
      }
    }
  }

}
