
import 'package:flutter/material.dart';

import 'package:chat_app/models/error_response.dart';

class RegisterFormProvider extends ChangeNotifier {
  final key = GlobalKey<FormState>();

  RegisterFormProvider(String loginEmail){
    body['email'] = loginEmail;
  }

  ErrorResponse? _error;
  ErrorResponse? get error => _error;
  set error(ErrorResponse? error) {
    _error = error;
    notifyListeners();
  }

  bool _show = false;
  bool get show => _show;
  set show(bool show) {
    _show = show;
    notifyListeners();
  }

  bool _loading = false;
  bool get loading => _loading;
  set loading(bool loading) {
    _loading = loading;
    notifyListeners();
  }

  String? _image;
  String? get image => _image;
  set image(String? image) {
    _image = image;
    body['avatar'] = image;
    notifyListeners();
  }

  Map<String, dynamic> body = {
    'name'     : '',
    'email'    : '',
    'password' : '',
    'role'     : '',
    'avatar'   : null
  };

  bool validate(){
    return key.currentState!.validate();
  }
}