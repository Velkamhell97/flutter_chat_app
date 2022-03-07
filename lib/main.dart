import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'src/global/globals.dart';
import 'src/services/services.dart';
import 'src/pages/pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // FlutterError.onError = (details) {
  //   print('FRAMEWORK ERROR dd');
  //   print(details.exception);
  // };

  final String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: Env.PROD.name
  );

  Environment().initConfig(Env.values.byName(environment));

  final prefs = SP();
  await prefs.initPrefs();

  runApp(const AppState());
}

class AppState extends StatelessWidget {
  const AppState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthServices()),
        Provider(create: (_) => FileServices()),
        Provider(create: (_) => SocketServices(null)),

        ChangeNotifierProvider(create: (_) => ChatServices()),

        // ChangeNotifierProvider(create: (_) => AuthFormProvider()), //->Manejo de los form en un solo (no optimo)

        // ChangeNotifierProxyProvider<ChatServices, SocketServices>( //->Injeccion de un provider en otro
        //   create: (context) => SocketServices(Provider.of<ChatServices>(context, listen: false)), 
        //   update: (context, chat, previousSocket) => previousSocket!,
        // ),
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
      scaffoldMessengerKey: Notifications.messengerKey,

      theme: ThemeData(
        fontFamily: 'ProximaNova',
        appBarTheme: const AppBarTheme(
          foregroundColor: Colors.black,
          backgroundColor: Colors.white,
          elevation: 0.0
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
        // '/chat'           : (_) => const ChatPage(),
      },
      onGenerateRoute: (settings) {
        if(settings.name == '/chat'){
          return CupertinoPageRoute(
            builder: (context) => const ChatState(),
            settings: settings
          );
        }
      },
    );
  }
}

