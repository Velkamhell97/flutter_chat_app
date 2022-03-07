import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:chat_app/models/models.dart';
import 'package:chat_app/global/enviorement.dart';

class AuthServices {
  static final _apiHost = Environment().config.apiHost;
  static final _apiRoutes = Environment().apiRoutes;

  //-Se podrian dejar estaticos esto es algo comun en firebase tener los datos del usuario estatico
  User? user;
  static String? token;

  //-Para obtener el token sin instanciar la clase
  static Future<String?> getToken() async{
    return await _storage.read(key: 'token');
  }

  bool get isAuth => user != null && token != null;

  final _dio = Dio();
  static const _storage = FlutterSecureStorage();

  static const _timeoutDuration = Duration(seconds: 5);
  
  //-Traemos el token, lo comparamos con el servicio, si esta vencido o no esta devuelve a login, si esta presente
  //-y no esta vencido, solicitamos uno nuevo y actualizamos el usuario logeado y el token (el usuario no se almacena internamente)
  Future<bool> isLogged() async {
    print('verifing user...');

    final token = await _storage.read(key: 'token');
    // final uid = await _storage.read(key: 'uid');

    if(token != null){
      final error = await renewToken(token);

      if(error != null){ //-Si hay error hace un singout
        await signout();
        return false;
      } else {
        return true;
      }
    } else { //-Si alguno de los dos es nulo, lo saca
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
      print(e);
      if(e.response != null){
        return ErrorResponse.fromJson(e.response!.data);
      }
    } catch (e) {
      print(e);
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

  //-Al parecer no necesaria, porque en el renew del token se trae la info del usuario
  
  // Future<ErrorResponse?> getUser(String uid) async {
  //   Uri url;
  //
  //   if(_https){
  //     url = Uri.https(_authority, '/api/users/$uid');
  //   } else {
  //     url = Uri.http(_authority, '/api/users/$uid');
  //   }
  //
  //   final response = await http.get(url, 
  //     headers: {
  //       'Content-type':'application/json',
  //     },
  //   );
  //
  //   final Map<String, dynamic> json = jsonDecode(response.body);
  //
  //   //-400 bad request, 401, unauthoraized, 500 server error, se puede manejar cada uno con errores especificod
  //   //-Con este packace los errores se capturan en el response
  //   if(response.statusCode != 200){
  //     return ErrorResponse.fromJson(json);
  //   }
  //
  //   final authResponse = AuthResponse.fromJson(json);
  //
  //   user = authResponse.user;
  //   token = authResponse.token;
  //
  //   await _storage.write(key: 'token', value: token);
  // }

  Future<void> signout() async {
    user = null; //-Tambien podria ser un get/set
    token = null;

    await _storage.delete(key: 'token');
    await _storage.delete(key: 'uid');
  }
}