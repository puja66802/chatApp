import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class FetchChats extends ChatEvent {}

class SendMessage extends ChatEvent {
  final String receiverId;
  final String message;

  SendMessage({required this.receiverId, required this.message});

  @override
  List<Object> get props => [receiverId, message];
}
