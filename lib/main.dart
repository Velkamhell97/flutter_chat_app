import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:chat_app/global/enviorement.dart';
import 'package:chat_app/providers/auth_form_provider.dart';
import 'package:chat_app/services/auth_services.dart';
import 'package:chat_app/src/pages/pages.dart';

void main() async {
  // WidgetsFlutterBinding.ensureInitialized();

  final String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: Env.DEV.name
  );

  Environment().initConfig(Env.values.byName(environment));

  runApp(const AppState());
}

class AppState extends StatelessWidget {
  const AppState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => AuthService()),
        //-Se ponde aqui para no perder el estado entre el login y el register (opcional)
        ChangeNotifierProvider(create: (_) => AuthFormProvider()),
      ],
      child: const MyApp(),
    );
  }
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
        fontFamily: 'ProximaNova',
        appBarTheme: const AppBarTheme(
          foregroundColor: Colors.black,
        ),
      ),
      // restorationScopeId: 'app',
      initialRoute: '/auth',
      routes: {
        '/auth'           : (_) => const AuthPage(),
              
        '/login'          : (_) => const LoginPage(),
        '/register'       : (_) => const RegisterPage(),
        '/reset-password' : (_) => const ResetPasswordPage(),

        '/users'          : (_) => const UsersPage(),
        '/chat'           : (_) => const ChatPage(),
      },
    );
  }
}

