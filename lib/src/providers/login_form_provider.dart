
import 'package:flutter/material.dart';

import '../models/models.dart';

class LoginFormProvider extends ChangeNotifier {
  final key = GlobalKey<FormState>();

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

  Map<String, dynamic> body = {
    'email'    : '',
    'password' : '',
  };

  bool validate(){
    return key.currentState!.validate();
  }
}