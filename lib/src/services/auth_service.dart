import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import 'dart:async';

import '../models/models.dart';
import '../global/globals.dart';

/// Forma de declarar variables globales, declarlas como top-leve-constants
const String renewTokenRoute     = '/renew-token';
const String signupRoute         = 'api/users'; /// Es diferente a las demas 'api/auth'
const String signinRoute         = '/login';
const String signinPhoneRoute    = '/signin-phone';
const String signinGoogleRoute   = '/signin-google';
const String forgotPasswordRoute = '/forgot-password';
// const String verifyEmailRoute    = '/verify-email';
// const String resetPasswordRoute  = '/reset-password';

class AuthService {
  AuthService(){
    _dio.options.baseUrl = '$_host/api/auth';
    _dio.options.connectTimeout = 10000;
  }

  void dispose() {
    _dio.close();
  }

  final _host = Environment.apiHost;

  final _dio = Dio();
  final _googleSignin = GoogleSignIn(scopes: ['email']);

  User? user; /// Se podrian dejar estatico como firebase
  CancelToken _cancelToken = CancelToken(); 

  static const _storage = FlutterSecureStorage();
  // static const _timeoutDuration = Duration(seconds: 10);

  static String? token;

  bool get isAuth => user != null && token != null;

  void cancelRequest() {
    _cancelToken.cancel();
    _cancelToken = CancelToken();
  }

  Future<bool> isLogged() async {
    final token = await _storage.read(key: 'token');

    if(token != null){
      debugPrint('Token Renew');
      final error = await _renewToken(token);

      if(error != null){
        await signout();
        return false;
      } else {
        return true;
      }
    } else { 
      debugPrint('Token not found');
      return false;
    }
  }

  Future<ErrorResponse?> _renewToken(String oldToken) async {
    try {
      final options = Options(headers: {'x-token':oldToken}, );

      final response = await _dio.get(renewTokenRoute, options: options, cancelToken: _cancelToken);

      final authResponse = AuthResponse.fromJson(response.data);

      user = authResponse.user;
      token = authResponse.token;

      await _storage.write(key: 'token', value: token);
      
      return null;
    } catch (e) {
      return ErrorResponse.fromObject(e);
    }
  }

  Future<void> _signin(String endpoint, dynamic data) async {
    final response = await _dio.post(endpoint, data: data, cancelToken: _cancelToken);

    final authResponse = AuthResponse.fromJson(response.data);

    user = authResponse.user;
    token = authResponse.token;

    await _storage.write(key: 'token', value: token);
  }

  Future<ErrorResponse?> signinWithCredentials(AuthType authType, Map<String, dynamic> data) async {
    final route = authType == AuthType.login ? signinRoute : '$_host/$signupRoute';

    try {
      await _signin(route, data);
      return null;
    } catch (e) {
      return ErrorResponse.fromObject(e);
    }
  }

  Future<ErrorResponse?> signinWithPhone(PhoneAuthCredential credentials) async {
    try {
      /// No importa si es exitoso en firebase o no en el backend, pues la autenticacion se hara frente 
      /// al backend y tendra que volver a intentar el proceso en caso de que falle
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credentials);
      final idToken = await userCredential.user!.getIdToken();

      await _signin(signinPhoneRoute, {'idToken': idToken});
      return null;
    } catch (e) {
      return ErrorResponse.fromObject(e);
    }
  }

  Future<ErrorResponse?> signinWithGoogle() async {
    try {
      final googleUser = await _googleSignin.signIn();

      if(googleUser == null) {
        throw const ErrorResponse(code: 'google-cancel');
      }

      final googleKey = await googleUser.authentication;

      await _signin(signinGoogleRoute, {'idToken': googleKey.idToken});
      
      await _googleSignin.signOut();

      return null;
    } catch (e) {
      return ErrorResponse.fromObject(e);
    }
  }

  Future<ErrorResponse?> updateUser(Map<String, String?> body) async {
    ///Necesario el casteo para recibir el MultipartFile
    final data = <String, dynamic>{for (dynamic e in body.entries) e.key: e.value};

    try {
      final image = data['avatar'] as String?;

      if(image != null){
        final ext = image.split('/').last.split('.').last;
        final avatar = await MultipartFile.fromFile(image, filename: 'avatar.$ext');
        data['avatar'] = avatar;
      } 

      /// Cuando la ruta comienza con http o https, dio ignora el baseUrl
      final route = '$_host/$signupRoute';
      final options = Options(headers: {'x-token': token});
      final formData = FormData.fromMap(data);

      final response = await _dio.put(route, data: formData, options: options, cancelToken: _cancelToken);

      final authResponse = AuthResponse.fromJson(response.data);

      user = authResponse.user;

      return null;
    } catch (e) {
      return ErrorResponse.fromObject(e);
    }
  }

  /// Puede utilizarse este mismo para enviar el correo de verificacion
  Future<ErrorResponse?> sendResetEmail(String email) async {
    try {
      await _dio.post(forgotPasswordRoute, data: {'email': email}, cancelToken: _cancelToken);
      return null;
    } catch (e) {
      return ErrorResponse.fromObject(e);
    }
  }

  Future<void> signout() async {
    user = null;
    token = null;
    await _storage.delete(key: 'token');
  }
}  

/// Para cancelar peticiones, uno de los casos mas comunes es cuando el usuario sale de la pantalla sin
/// terminar la peticion, aqui se pueden presentar dos tipos de errores, primero los errores de UI, por
/// intentar actualizar un elemento un setState, notifiListener o navegar luego del dispose, por lo que tenemos que
/// utilizar la propiedad mounted del setState o implementarla en el provider, para evitar que se actaulice
/// el UI si se salio de la pantalla, ahora el otro tipo de errores es el de las operaciones que se hacen
/// con el resultado de la peticion, por ejemplo si cancelamos antes de realizar un registro, hay una cosa
/// que no podemos evitar o por lo menos muy dificil controlar y es lo que se graba en el backend, por ejemplo
/// si empieza a registrar y se devuelve apenas empieza la peticion puede detenerse la navegacion y la peticion
/// pero si lo hace cuando ya hizo la peticion y esta devolviendo la respuesta, ya se habra hecho la operacion
/// y asi se cancele no se podra borrar la creacion
/// 
/// Una alternativa al cancel token es el willPopScope evitando que el usuario se salga de la pantalla
/// antes que se complete la peticion, aunque es muy efectiva se debe implementar en todas las pantallas
/// y colocar el changeNotifier en el punto mas alto de los widgets
/// 
/// Tambien lo que podriamos hacer es hacer todos los widgets StafullWidget para tener el metodo mount
/// y evitar que se modifique la ui o se navege a otro lugar si se obtiene la respuesta de la peticion
/// luego de salir de la pantalla, pero no se sabe si es mas optimo que el WillPopScope
/// 
/// En ambos casos anteriores la peticion se termina realizando, solo que en una le impedimos la salida 
/// al cliente y en la otra no, no se sabe cual sea mas eficiente la del willPopscope por tener un
/// StalessWidget pero con un ChangeNotifier muy arriba en el tree (que no se sabe si es problema)
/// o el StafullWidget por el ciclo de vide del widget y por ser un widget mas complejo, podria hacerse
/// un tipo de combinacion entre el WillPopScope y el setSate para conseguir ambos beneficios, por el
/// lado del willPopScope detectar cuando se devuelve y hacer un cancel de la peticion pero dejando
/// de salir al usuario de la pantalla y usando el mount para evitar que se actualice el ui o se navege
/// 
/// Para el caso del auth no hay problema que todas las peticiones compartan el mismo cancelToken pues
/// siempre se realizara una peticion al tiempo y no hay problema en cancelar las demas

/// Despues de cancelar la peticion es necesario reinicializar el token, todas las peticiones que compartan
/// el token seran canceladas, esta cancelacion seria opcional ya que se mostrara como un error, y no
/// es muy comun ver un error de cancelacion al presionar atras, generalmente se bloquea el atras o se
/// permite, la ultima opcion seria que este error en especifico no sea considerado como error y no
/// afecte la ui, pero otra alternativa es manejar los snackbar cuando se completa una peticion
/// en el backend, por ejemplo si regresa pero se alcanzo a crear el usuario evitar la navegacion pero
/// mostrar un snackbar del exito
/// 
/// Sin embargo se presenta una situacion y esque si se cancela la peticion, esta ya noo dara una 
/// respuesta posiva, por lo que nunca entradra a la condicion de la peticion exitosa y nunca navegara
/// a otra pantalla por lo que no seria necesario el mount, entonces aqui es donde se puede decidir cual 
/// de los dos appoachs tomar, si dejar que la peticion continue y se usa el mount para saber si esta en
/// el widget o no para navegar o mostrar un snack respectivamente o si solo se cancela la peticion
/// y se hace la navegacion hacia la pantalla de salida, quizas cada solucion sea mas ideal para algunos
/// casos, para el caso de la autenticacion no es necesario esperar que la peticion se haga y mostrar un
/// snack, en vez de eso se considera que es mejor cancelarla, no se sabe si haya un problema en cancelar
/// esta peticion en un punto muy cercano a la respuesta 

/// Con google people api se puede al parecer obtener informacion de los contactos de una
/// persona o de si misma, ya que el googleSignin no devuelve el phone, se pensaba obtener
/// por esta api pero el phone que devuelve es uno que se setea manual en la cuenta y no
/// el vinculado a la cuenta de google como tal, este no se puede extraer por este medio
/// en conclusion, no se puede extraer el numero de telefono de google signin
// final peopleEndpoint = 'https://people.googleapis.com/v1/people/${googleUser.id}?personFields=phoneNumbers';
// final peopleHeaders = await googleUser.authHeaders;
//
// final peopleResponse = await _dio.get(peopleEndpoint, options: Options(headers: peopleHeaders));

 