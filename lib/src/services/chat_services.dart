// ignore_for_file: body_might_complete_normally_nullable

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:async';

import '../global/globals.dart';
import '../services/services.dart';
import '../models/models.dart';


class ChatServices extends ChangeNotifier {
  static final _apiHost = Environment().config.apiHost;
  static final _apiRoutes = Environment().apiRoutes;

  final _dio = Dio();
  static const _timeoutDuration = Duration(seconds: 10); //-Cuando heroku duerme suele demorarse

  User? receiverUser;
  ErrorResponse? error;

  StreamController<List<User>> _usersStreamController = StreamController();
  Stream<List<User>> get usersStream => _usersStreamController.stream;

  close() { //-Para mantener un single stream escuchando los cambios
    _usersStreamController.close();
    _usersStreamController = StreamController();
  }

  bool _isFetching = false;

  List<User> _users = [];
  List<Message>? chatMessages = [];

  void addMessage(Message message){
    chatMessages!.insert(0, message);
    notifyListeners();
  }

  void updateStream(){
    _usersStreamController.add(_users);
    notifyListeners();
  }

  Future<void> getUsers() async {
    if(_isFetching) return;
    _isFetching = true;

    final url = _apiHost + _apiRoutes.get_users;
    final token = AuthServices.token;

    try {
      final response = await _dio.get(url, options: Options(headers: {'x-token': token})).timeout(_timeoutDuration);

      final usersResponse = UsersResponse.fromJson(response.data);

      _users = usersResponse.users;
      _usersStreamController.add(usersResponse.users);
    } on DioError catch (e){ //-Con este package los errores se capturan como una excepcion
      if(e.response != null){
        _usersStreamController.addError(ErrorResponse.fromJson(e.response!.data));
      }
    } catch (e) {
      final error = ErrorResponse(
        error: e.toString(), 
        details: Details(code: 500, msg: e.toString(), name: "UNKNOWN ERROR", extra: null)
      );

      _usersStreamController.addError(error);
    } finally {
      _isFetching = false;
    }
  }

  //-Tambien se pudo hacer con un stream, pero al agregar un mensaje se debia resetear todo el stream
  //-por esta razon se utilizo una lista y solo se agregaba valores, no se sabe cual es mas optima
  Future<void> getChatMessages() async { 
    final url = _apiHost + _apiRoutes.get_messages + '/' + receiverUser!.uid;
    final token = AuthServices.token;

    error = null;

    try {
      final response = await _dio.get(url, options: Options(headers: {'x-token': token})).timeout(_timeoutDuration);
      final json = response.data;

      final messages = List<Message>.from(
        json['messages'].map((message) => Message.fromJson(message))
      );

      chatMessages = messages;
    } on DioError catch (e){ //-Con este package los errores se capturan como una excepcion
      if(e.response != null){
        error = ErrorResponse.fromJson(e.response!.data);
      }
    } catch (e) {
      error = ErrorResponse(
        error: e.toString(), 
        details: Details(code: 500, msg: e.toString(), name: "UNKNOWN ERROR", extra: null)
      );
    } finally {
      notifyListeners(); //-> Si se desea actualizar el ui con el error;
    }
  }

  //-Cuando se utiliza en el home no se tiene el from del receiver y se extrae del payload from
  //-Cuando se utiliza en el chat se tiene el receiver  
  Future<int?> uploadUnread(String from, {bool reset = false}) async {
    final url = _apiHost + _apiRoutes.upload_unread + '/' + from;
    final token = AuthServices.token;

    error = null;

    try {
      final response = await _dio.put(url,
        data: {'reset': reset}, 
        options: Options(headers: {'x-token': token})
      ).timeout(_timeoutDuration);

      return response.data['value'] ?? 0;
    } on DioError catch (e){ //-Con este package los errores se capturan como una excepcion
      if(e.response != null){
        error = ErrorResponse.fromJson(e.response!.data);
        return null;
      }
    } catch (e) {
      error = ErrorResponse(
        error: e.toString(), 
        details: Details(code: 500, msg: e.toString(), name: "UNKNOWN ERROR", extra: null)
      );
      return null;
    } 
  }
}