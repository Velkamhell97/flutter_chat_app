import 'message.dart';

class MessagesResponse {
  final int status;
  final String message;
  final List<Message> messages;

  const MessagesResponse({
    required this.status,
    required this.message,
    required this.messages,
  });
   
  factory MessagesResponse.fromJson(Map<String, dynamic> json) {
    return MessagesResponse(
      status: json["status"],
      message: json["message"],
      messages: List<Message>.from(json["payload"]["messages"].map((message) => Message.fromJson(message))),
    );
  }
}
