import 'user.dart';

class UsersResponse {
  final int status;
  final String message;
  final List<User> users;

  const UsersResponse({
    required this.status,
    required this.message,
    required this.users,
  });
   
  factory UsersResponse.fromJson(Map<String, dynamic> json) {
    return UsersResponse(
    status: json["status"],
    message: json["message"],
    users: List<User>.from(json["payload"]["users"].map((user) => User.fromJson(user))),
  );
  }
}
