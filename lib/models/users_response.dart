import 'package:chat_app/models/user.dart';

class UsersResponse {
  final String msg;
  final List<User> users;

  const UsersResponse({
    required this.msg,
    required this.users,
  });
   
  factory UsersResponse.fromJson(Map<String, dynamic> json) => UsersResponse(
    msg: json["msg"],
    users: List<User>.from(json["users"].map((user) => User.fromJson(user))),
  );
}
