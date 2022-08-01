import 'user.dart';

class AuthResponse {
  final int status;
  final String message;
  final User user;
  final String? token;

  const AuthResponse({
    required this.status,
    required this.message,
    required this.user,
    this.token
  });
   
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
    status: json["status"],
    message: json["message"],
    user: User.fromJson(json["payload"]["user"]),
    token: json["payload"]["token"],
  );
  }
}
