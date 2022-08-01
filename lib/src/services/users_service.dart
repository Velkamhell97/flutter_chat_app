import 'package:dio/dio.dart';
import 'dart:async';

import '../global/enviorement.dart';
import '../services/auth_service.dart';
import '../models/models.dart';

const String connectedUsersRoute = '/connected';

class UsersService {
  UsersService() {
    _dio.options.baseUrl = '$_host/api/users';
    _dio.options.connectTimeout = 10000;
  }

  void dispose() {
    _usersStreamController.close();
    _dio.close();
  }

  final _host = Environment.apiHost;
  final _dio = Dio();

  List<User> users = [];

  /// El broadcast para ser escuchado muchas veces
  final StreamController<List<User>> _usersStreamController = StreamController.broadcast();
  Stream<List<User>> get usersStream => _usersStreamController.stream;

  bool _isFetching = false;

  Future<void> getUsers() async {
    if(_isFetching) return;
   
    _isFetching = true;

    try {
      final options = Options(headers: {'x-token': AuthService.token});

      final response = await _dio.get(connectedUsersRoute, options: options);

      final usersResponse = UsersResponse.fromJson(response.data);

      users = usersResponse.users;

      _usersStreamController.add(users);
    } catch (e) {
      final error = ErrorResponse.fromObject(e);
      _usersStreamController.addError(error);
    } finally {
      _isFetching = false;
    }
  }

  void connect(String id) {
    final user = users.firstWhere((element) => element.uid == id);
    user.online = true;
    _usersStreamController.add(users);
  }

  void disconnect(String id) {
    final user = users.firstWhere((element) => element.uid == id);
    user.online = false;
    _usersStreamController.add(users);
  }

  /// Actualiza la lista, si se pasa el id, coloca ese usuario de primero
  void refresh([String? id]) {
    if(id != null){
      final user = users.firstWhere((element) => element.uid == id);

      if(user != users[0]){
        users.remove(user);
        users.insert(0, user);
      }
    }

    _usersStreamController.add(users);
  }
}