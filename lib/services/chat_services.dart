import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'dart:async';

import 'package:chat_app/global/enviorement.dart';
import 'package:chat_app/services/services.dart';
import 'package:chat_app/models/models.dart';


class ChatServices extends ChangeNotifier {
  static final _apiHost = Environment().config.apiHost;
  static final _apiRoutes = Environment().apiRoutes;

  final _dio = Dio();
  final pathReceiver = Directory('storage/emulated/0/FlutterChat/received');

  static const _timeoutDuration = Duration(seconds: 10); //-Cuando heroku duerme suele demorarse

  User? receiverUser;

  bool _isFetching = false;

  StreamController<List<User>> _usersStreamController = StreamController();
  Stream<List<User>> get usersStream => _usersStreamController.stream;

  close() {
    _usersStreamController.close();
    _usersStreamController = StreamController();
  }

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

  Future<ErrorResponse?> getUsers() async {
    if(_isFetching) return null;

    // print('fetching users...');
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
        return ErrorResponse.fromJson(e.response!.data);
      }
    } catch (e) {
      return ErrorResponse(
        error: e.toString(), 
        details: Details(code: 500, msg: e.toString(), name: "UNKNOWN ERROR", extra: null)
      );
    } finally {
      _isFetching = false;
    }
  }

  Future<ErrorResponse?> getChatMessages() async {
    final url = _apiHost + _apiRoutes.get_messages + '/' + receiverUser!.uid;
    final token = AuthServices.token;

    try {
      final response = await _dio.get(url, options: Options(headers: {'x-token': token})).timeout(_timeoutDuration);
      final json = response.data;

      final messages = List<Message>.from(
        json['messages'].map((message) => Message.fromJson(message))
      );

      chatMessages = messages;
      notifyListeners(); //-Forma 1 con notify listener para actualizar los cambios
    } on DioError catch (e){ //-Con este package los errores se capturan como una excepcion
      if(e.response != null){
        return ErrorResponse.fromJson(e.response!.data);
      }
    } catch (e) {
      return ErrorResponse(
        error: e.toString(), 
        details: Details(code: 500, msg: e.toString(), name: "UNKNOWN ERROR", extra: null)
      );
    } finally {
      _isFetching = false;
    }
  }

  Future<int?> uploadUnread(String from, {bool reset = false}) async {
    final url = _apiHost + _apiRoutes.upload_unread + '/' + from;
    final token = AuthServices.token;

    try {
      final response = await _dio.put(url,
        data: {'reset': reset}, 
        options: Options(headers: {'x-token': token})
      ).timeout(_timeoutDuration);

      return response.data['value'];
    } on DioError catch (e){ //-Con este package los errores se capturan como una excepcion
      // if(e.response != null){
      //   return ErrorResponse.fromJson(e.response!.data);
      // }
    } catch (e) {
      // return ErrorResponse(
      //   error: e.toString(), 
      //   details: Details(code: 500, msg: e.toString(), name: "UNKNOWN ERROR", extra: null)
      // );
    } 
  }
}