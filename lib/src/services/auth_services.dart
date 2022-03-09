// ignore_for_file: body_might_complete_normally_nullable

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/models.dart';
import '../global/globals.dart';

class AuthServices extends ChangeNotifier {
  static final _apiHost = Environment().config.apiHost;
  static final _apiRoutes = Environment().apiRoutes;

  //-Se podrian dejar estaticos esto es algo comun en firebase tener los datos del usuario estatico
  User? user;
  static String? token;

  void updateUnread(String uid, int value){
    user!.unread[uid] = value;
    notifyListeners();
  }

  bool get isAuth => user != null && token != null;

  final _dio = Dio();
  static const _storage = FlutterSecureStorage();

  static const _timeoutDuration = Duration(seconds: 10);

  //-Traemos el token, lo comparamos con el servicio, si esta vencido o no esta devuelve a login, si esta presente
  //-y no esta vencido, solicitamos uno nuevo y actualizamos el usuario logeado y el token (el usuario no se almacena internamente)
  Future<bool> isLogged() async {
    // print('verifing user...');

    final token = await _storage.read(key: 'token');

    if(token != null){
      final error = await renewToken(token);

      if(error != null){ //-Si hay error hace un singout
        await signout();
        return false;
      } else {
        return true;
      }
    } else { 
      return false;
    }
  }


  Future<ErrorResponse?> signin({required Map<String, dynamic> data}) async {
    final url = _apiHost + _apiRoutes.login;

    try {
      //-Este paquete parece tener mejores respuestas para los timeout
      final response = await _dio.post(url, data: data).timeout(_timeoutDuration);

      final authResponse = AuthResponse.fromJson(response.data);

      user = authResponse.user;
      token = authResponse.token;

      await _storage.write(key: 'token', value: token);
    } on DioError catch (e){ //-Con este package los errores se capturan como una excepcion
      if(e.response != null){
        return ErrorResponse.fromJson(e.response!.data);
      }
    } catch (e) {
      return ErrorResponse(
        error: e.toString(), 
        details: Details(code: 500, msg: e.toString(), name: "UNKNOWN ERROR", extra: null)
      );
    }
  }


  Future<ErrorResponse?> signup({required Map<String, dynamic> data}) async {
    final url = _apiHost + _apiRoutes.register;

    final image = data['avatar'];

    if(image != null){
      final ext = data['avatar']!.split('/').last.split('.').last;
      final avatar = await MultipartFile.fromFile(image, filename: 'avatar.$ext');
      data['avatar'] = avatar;
    }    

    try {
      final response = await _dio.post(url, data: FormData.fromMap(data)).timeout(_timeoutDuration);
      final authResponse = AuthResponse.fromJson(response.data);

      user = authResponse.user;
      token = authResponse.token;

      await _storage.write(key: 'token', value: token);
      return null;
    } on DioError catch (e){ //-Con este package los errores se capturan como una excepcion
      if(e.response != null){
        return ErrorResponse.fromJson(e.response!.data);
      }
    } catch (e) {
      return ErrorResponse(
        error: e.toString(), 
        details: Details(code: 500, msg: e.toString(), name: "UNKNOWN ERROR", extra: null)
      );
    }
  }


  Future<ErrorResponse?> sendResetCode({required String email}) async {
    final url = _apiHost + _apiRoutes.send_token;

    try {
      await _dio.post(url, data: {'email': email}).timeout(_timeoutDuration);
      return null;
    } on DioError catch (e){ //-Con este package los errores se capturan como una excepcion
      if(e.response != null){
        return ErrorResponse.fromJson(e.response!.data);
      }
    } catch (e) {
      return ErrorResponse(
        error: e.toString(), 
        details: Details(code: 500, msg: e.toString(), name: "UNKNOWN ERROR", extra: null)
      );
    }
  }


  Future<ErrorResponse?> resetPassword({required Map<String, dynamic> data}) async {
    final url = _apiHost + _apiRoutes.reset_password;

    try {
      await _dio.post(url.toString(), data: data).timeout(_timeoutDuration);
    } on DioError catch (e){ //-Con este package los errores se capturan como una excepcion
      if(e.response != null){
        return ErrorResponse.fromJson(e.response!.data);
      }
    } catch (e) {
      return ErrorResponse(
        error: e.toString(), 
        details: Details(code: 500, msg: e.toString(), name: "UNKNOWN ERROR", extra: null)
      );
    }
  }


  Future<ErrorResponse?> renewToken(String oldToken) async {
    final url = _apiHost + _apiRoutes.renew_token;

    try {
      final response = await _dio.get(url, options: Options(headers: {'x-token': oldToken})).timeout(_timeoutDuration);
      final authResponse = AuthResponse.fromJson(response.data);

      user = authResponse.user;
      token = authResponse.token;

      await _storage.write(key: 'token', value: token);
    } on DioError catch (e){ //-Con este package los errores se capturan como una excepcion
      if(e.response != null){
        return ErrorResponse.fromJson(e.response!.data);
      }
    } catch (e) {
      return ErrorResponse(
        error: e.toString(), 
        details: Details(code: 500, msg: e.toString(), name: "UNKNOWN ERROR", extra: null)
      );
    }
  }


  Future<void> signout() async {
    user = null; //-Tambien podria ser un get/set
    token = null;

    await _storage.delete(key: 'token');
  }
}