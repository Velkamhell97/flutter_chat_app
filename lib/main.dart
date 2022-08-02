import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageRoute;
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_persistent_keyboard_height/flutter_persistent_keyboard_height.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

import 'src/global/enviorement.dart';
import 'src/services/services.dart';
import 'src/singlentons/singlentons.dart';
import 'src/models/models.dart';
import 'src/providers/providers.dart';
import 'src/pages/auth/auth.dart';
import 'src/pages/chat/chat.dart';

/// Notificaciones en background, solo usuarios autenticados
Future<void> onBackgroundTerminated(RemoteMessage message) async {
  final token = await const FlutterSecureStorage().read(key: 'token');

  if(token != null){
    final payload = jsonDecode(message.data["payload"]);
    final tiles = List<NotificationTile>.from(payload.map((tile) => NotificationTile.fromJson(tile)));
    await NotificationsService().showChatNotification(tiles);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: Environment.getFileName(EnvironmentMode.production));

  await Firebase.initializeApp();

  /// Si la app se abre por medio de una notificacion
  final notificationAppLaunchDetails = await FlutterLocalNotificationsPlugin().getNotificationAppLaunchDetails();

  // Util para abrir una pantalla inicial o pasar data a una named route
  String? payload;

  if(notificationAppLaunchDetails?.didNotificationLaunchApp ?? false){
    payload = notificationAppLaunchDetails!.notificationResponse!.payload;
  }

  await NotificationsService().init();

  /// Se debe pensar en cuando se abra otra cuaenta, no guardara 
  debugPrint(await FirebaseMessaging.instance.getToken());

  FirebaseMessaging.onBackgroundMessage(onBackgroundTerminated);

  await SP().init();
  
  await LocalesService().init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      // statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.dark
    ),
  );

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(AppState(payload: payload));
}

class AppState extends StatelessWidget {
  final String? payload;

  const AppState({Key? key, this.payload}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
          dispose: (_, model) => model.dispose(),
        ),

        Provider<FilesService>(
          create: (_) => FilesService(),
          dispose: (_, model) => model.dispose(),
        ),

        Provider<SocketsService>(
          create: (_) => SocketsService(),
          dispose: (_, model) => model.dispose(),
        ),

        Provider<UsersService>(
          create: (_) => UsersService(),
          dispose: (_, model) => model.dispose(),
        ),

        Provider<DialogsService>(
          create: (_) => DialogsService(),
          // dispose: (_, model) => model.dispose(),
        ),

        Provider<PermissionsService>(
          create: (_) => PermissionsService(),
          // dispose: (_, model) => model.dispose(),
        ),

        /// No se sabe si sea buena practica inyectar tantas dependencias
        Provider<MessagesService>(
          create: (context) => MessagesService(
            context.read<SocketsService>(),
            context.read<AuthService>(),
            context.read<FilesService>(),
            context.read<UsersService>(),
          ),
          dispose: (_, model) => model.dispose(),
        ),

        ChangeNotifierProvider(create: (_) => MessageProvider())
      ],
      child: MyApp(payload: payload),
    );
  }
}

class MyApp extends StatefulWidget {
  final String? payload;

  const MyApp({Key? key, this.payload}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final DialogsService _dialogs;

  /// Se almacena la varaible, no se sabe si sea mejor utilizarlo como clase
  final _notification = NotificationsService();

  @override
  void initState() {
    super.initState();

    _dialogs = Provider.of<DialogsService>(context, listen: false);

    /// Mesajes en foreground, solo autencticados
    FirebaseMessaging.onMessage.listen(_onMessage);

    /// Manejador para notificaciones foreground y background (no terminada)
    _notification.stream.listen(_onTapNotification);
  }

  void _onMessage(RemoteMessage event) {
    final payload = jsonDecode(event.data["payload"]);
    final tiles = List<NotificationTile>.from(payload.map((tile) => NotificationTile.fromJson(tile)));
    _notification.showChatNotification(tiles);
  }

  void _onTapNotification(Map<String, dynamic> event) {
    /// Se crea aqui para no almacenar en memoria (como variable), no se sabe si
    /// sea mas practico asi o declarandolos todos como late
    final auth = Provider.of<AuthService>(context, listen: false);
    final users = Provider.of<UsersService>(context, listen: false);
    final sockets = Provider.of<SocketsService>(context, listen: false);
    final chat = Provider.of<MessageProvider>(context, listen: false);

    final to = chat.message["to"];

    ///Mismo chat, limpia mensajes, no navega
    if(to == event["uid"]) {
      final data = {"from": to, "to": auth.user!.uid};

      /// Podria actualizarse el unreads fuera, pero para mantener sincronizado
      sockets.emitWithAck('messages-read', data, ack: (_) {
        auth.user!.unreads[to] = 0;
        users.refresh();
      });

      return;
    }

    /// Creamos un usuario con el payload (tambien se podria buscar por id)
    final user = User.fromJson(event);
    final route = CupertinoPageRoute(builder: (_) => ChatPage(receiver: user));

    /// Si esta en el home hace push, si esta en otro chat un pushReplacement
    if(to == null){
      _dialogs.navigatorKey.currentState!.push(route);
    } else {
      _dialogs.navigatorKey.currentState!.pushReplacement(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
  
      scaffoldMessengerKey: _dialogs.messengerKey,
      navigatorKey: _dialogs.navigatorKey,
      // navigatorObservers: [_dialogs.routeObserver],
  
      theme: ThemeData(
        fontFamily: 'ProximaNova',
        appBarTheme: const AppBarTheme(
          foregroundColor: Colors.black,
          backgroundColor: Colors.white,
          elevation: 0.0,
          // systemOverlayStyle: SystemUiOverlayStyle(
          //   statusBarIconBrightness: Brightness.dark,
          //   statusBarBrightness: Brightness.dark,
          // )
        ),
      ),
  
      builder: (context, child) {
        return PersistentKeyboardHeightProvider(
          child: child!
        );
      },
  
      // restorationScopeId: 'app',
      /// De esta forma se puede programa cada transicion con el Navigator.push, el problema es que no
      /// podemos pasar propiedades directas a un widget de una ruta, como por ejemplo el appLaunchPayload
      // home: AuthPage(payload: widget.payload),
  
      /// Si seteamos las rutas unicamente con nombres no podremos escoger el tipo de transicion entre 
      /// pantallas pues tendran siempre la de MaterialPageRoute
      initialRoute: '/auth',
      routes: {
        /// Se ejecuta primero para obtener el usuario y validar autenticacion, aun
        /// si se abre la app por notificacion se necesita para iniciar los sockets
        '/auth'              : (_) => AuthPage(payload: widget.payload),
      
        '/login'             : (_) => const LoginPage(),
        '/register'          : (_) => const RegisterPage(),
        '/reset-password'    : (_) => const ResetPasswordPage(),
        '/phone-signin'      : (_) => const PhoneSigninPage(),
        /// Podemos declarar algunas rutas que no reciben parametros para utiliza el popUntilRoute
        /// si quisieramos usar esta que recibe un parametro nombrada, utilizar el onGenerateRoute
        // '/code-confirmation' : (_) => const CodeConfirmPage(),
        '/new-user'          : (_) => const NewUserPage(),
      
        /// Si se abrio con una notificacion se le pasa el payload, no se utiliza como initial
        /// route, porque sin el auth no se inicializa el token y por ende los sockets
        '/users'             : (_) => UsersPage(appLaunchPayload: widget.payload),
      
        /// Igual que el anterior, se puede pasar el payload como receiver pero igualmente
        /// si se salta el auth no iniciliza el token y el user no inicializa sockets
        
        /// la unica para que sea la ruta inicial seria que en esta pantalla se inicialice
        /// los servicios de auth y se inicialice los sockets, luego se hace el pushReplace
        /// a el UserPage, pero creando mucha redundancia de codigo
      //  '/chat'              : (_) => ChatPage(receiver: receiver);
      },
  
      /// Con el generate route podemos controlar un poco mas las transiciones a cada ruta con nombre, pero
      /// no podemos manejar correctamente las transiciones de salida del widget saliente, ya que si utilizamos
      /// los animations en una ruta para la transicion de entrada o salida, se aplicara la misma transicion
      /// independiente desde donde se llegue a esa pestaña, lo cual puede que sea lo ideal en la mayoria de casos
      /// pero aqui se haran transiciones personalizadas de entrada y salida
      //onGenerateRoute: (settings) {
        //switch (settings.name) {
          // case '/auth':
          //   return MaterialPageRoute(builder: (_) => const AuthPage());
          // case '/login':
          //   return CupertinoPageRoute(builder: (_) => const LoginPage());
          // case '/register':
          //   final email = settings.arguments as String?;
          //   return CupertinoPageRoute(builder: (_) => RegisterPage(email: email));
          // case '/reset-password':
          //   final email = settings.arguments as String?;
          //   return SlideInRouteBuilder(child: ResetPasswordPage(email: email));
          // case '/phone-signin':
          //   const child = PhoneSigninPage();
          //   return PageRouteBuilder(pageBuilder: (_, opacity, __) => FadeTransition(opacity: opacity, child: child));
          // case '/code-confirmation':
          //   final form = settings.arguments as AuthFormProvider;
          //   return CupertinoPageRoute(builder: (_) => CodeConfirmPage(form: form));
          // case '/new-user':
          //   return CupertinoPageRoute(builder: (_) => const NewUserPage());
          // case '/users':
          //   return MaterialPageRoute(builder: (_) => UsersPage(appLaunchPayload: widget.payload));
          // default:
          //   return MaterialPageRoute(builder: (_) => const AuthPage());
        //}
      //},
    );
  }
}

