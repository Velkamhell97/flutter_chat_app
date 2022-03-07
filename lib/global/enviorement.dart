// ignore_for_file: constant_identifier_names, non_constant_identifier_names
import 'dart:io';

//-El sentido de las clases abstractas esque no tienen nungin valor por defecto, sino que sus clases
//-que la implementan asignan estos valores
abstract class BaseConfig {
  String get apiHost;
  bool get useHttps;
}

class DevConfig implements BaseConfig {
  //Para que funcione el 10.0.2.2 en android +28 se debe agregar la configuracion al manifest
  @override
  String get apiHost => Platform.isAndroid ? 'http://192.168.1.19:8080' : 'http://localhost:8080';

  @override
  bool get useHttps => false;
}

class ProdConfig implements BaseConfig {
  @override
  String get apiHost => "https://flutter-chat-back.herokuapp.com";

  @override
  bool get useHttps => true;
}

enum Env {
  DEV,
  PROD
}

class Environment {
  //-Constructor privado
  Environment._internal();

  //-Variable estatica privada que mantiene su valor sin importar la instanciacion, genera la unica instancia privada
  static final Environment _singlenton = Environment._internal();

  //-el constructor nombrado crea una instancia de la clase, no recibe parametros, tiene acceso al this
  //-el factory solo retorna una instancia de la clase en tiempo de ejecucion, no tiene acceso al this, almacena en cache
  factory Environment(){
    return _singlenton;
  }

  late BaseConfig config;

  final _ApiRoutes apiRoutes = _ApiRoutes();

  final _AppFolder appFolder = _AppFolder();

  initConfig(Env environment){
    config = _getConfig(environment);
  }

  BaseConfig _getConfig(Env environment){
    switch (environment) {
      case Env.DEV:
        return DevConfig();
      case Env.PROD:
        return ProdConfig();
    }
  }
}

class _ApiRoutes {
  final String login =          '/api/auth/login';
  final String register =       '/api/users';
  final String send_token =     '/api/auth/send-reset-token';
  final String reset_password = '/api/auth/reset-password';
  final String renew_token =    '/api/auth/renew';
  final String get_users =      '/api/users/connected';
  final String get_messages =   '/api/users/messages';
  final String upload_unread =  '/api/users/unread';
  final String upload_file =    '/api/uploads/chat';
}

class _AppFolder {
  final Directory sent =     Directory('storage/emulated/0/FlutterChat/sent');
  final Directory received = Directory('storage/emulated/0/FlutterChat/received');
}

//Extender los enum
// enum ApiRoutes {
//   LOGIN,
//   REGISTER,

//   SEND_TOKEN,
//   RESET_PASSWORD,
  
//   RENEW_TOKEN,

//   GET_USERS,
//   GET_MESSAGES,

//   UPLOAD_FILE,
// }

// extension ApiRoutesExtension on ApiRoutes {
//   static const _apiRoutes = {
//     ApiRoutes.LOGIN:          '/api/auth/login',
//     ApiRoutes.REGISTER:       '/api/users',
//     ApiRoutes.SEND_TOKEN:     '/api/auth/send-reset-token',
//     ApiRoutes.RESET_PASSWORD: '/api/auth/reset-password',
//     ApiRoutes.RENEW_TOKEN:    '/api/auth/renew',
//     ApiRoutes.GET_USERS:      '/api/users/connected',
//     ApiRoutes.GET_MESSAGES:   '/api/users/messages',
//     ApiRoutes.UPLOAD_FILE:    '/api/uploads/chat'
//   };

//   String get route => _apiRoutes[this]!;
// }