// ignore_for_file: non_constant_identifier_names
import 'dart:io';

import 'enviorement.dart';

//-Otra forma de declarar una clase global
class Api {

  static late final String apiHost;

  static late String login          = '/api/auth/login';
  static late String register       = '/api/users';
  static late String send_token     = '/api/auth/send-reset-token';
  static late String reset_password = '/api/auth/reset-password';
  static late String renew_token    = '/api/auth/renew';
  static late String get_users      = '/api/users/connected';
  static late String get_messages   = '/api/users/messages';
  static late String upload_file    = '/api/uploads/chat';

  Api(Env environment){
    switch (environment) {
      case Env.DEV:
        apiHost = Platform.isAndroid ? 'http://192.168.1.19:8080' : 'http://localhost:8080';
        break;
      case Env.PROD:
        apiHost = 'https://flutter-chat-back.herokuapp.com';
        break;
    }

    login          = apiHost + '/api/auth/login';
    register       = apiHost + '/api/users';
    send_token     = apiHost + '/api/auth/send-reset-token';
    reset_password = apiHost + '/api/auth/reset-password';
    renew_token    = apiHost + '/api/auth/renew';
    get_users      = apiHost + '/api/users/connected';
    get_messages   = apiHost + '/api/users/messages';
    upload_file    = apiHost + '/api/uploads/chat';
  }
}