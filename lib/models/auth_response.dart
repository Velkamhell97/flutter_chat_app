import 'package:chat_app/models/user.dart';

class AuthResponse {
  //-Tampoco cambian
  final String msg;
  final User user;
  final String token;

  const AuthResponse({
    required this.msg,
    required this.user,
    required this.token,
  });
   
  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    msg: json["msg"],
    user: User.fromJson(json["user"]),
    token: json["token"],
  );

  //-El metodo toJSON, generalmente sirve para enviar el objeto datos a la api, por ejemplo para un update
}
