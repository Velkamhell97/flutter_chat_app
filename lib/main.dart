import 'package:chat_app/src/pages/auth_page.dart';
import 'package:chat_app/src/pages/chat_page.dart';
import 'package:chat_app/src/pages/login_page.dart';
import 'package:chat_app/src/pages/register_page.dart';
import 'package:chat_app/src/pages/users_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        fontFamily: 'ProximaNova'
      ),
      initialRoute: '/login',
      routes: {
        '/auth'     : (_) => const AuthPage(),
        
        '/login'    : (_) => const LoginPage(),
        '/register' : (_) => const RegisterPage(),

        '/users'    : (_) => const UsersPage(),
        '/chat'     : (_) => const ChatPage(),
      },
    );
  }
}

