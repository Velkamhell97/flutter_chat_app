
import 'package:flutter/material.dart';

import '../models/models.dart';

class ResetFormProvider extends ChangeNotifier {
  final key = GlobalKey<FormState>();

  ResetFormProvider(String loginEmail){ //-Email que viene del login
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

  bool _reshow = false;
  bool get reshow => _reshow;
  set reshow(bool reshow) {
    _reshow = reshow;
    notifyListeners();
  }

  bool _loading = false;
  bool get loading => _loading;
  set loading(bool loading) {
    _loading = loading;
    notifyListeners();
  }

  bool _tokenSent = false;
  bool get tokenSent => _tokenSent;
  set tokenSent(bool tokenSent) {
    _tokenSent = tokenSent;
    notifyListeners();
  }

  final List<String> code = List.generate(5, (_) => '');

  void uploadToken(int index, String value){
    code[index] = value;
    body['resetToken'] = code.join();
    notifyListeners();
  }

  Map<String, dynamic> body = {
    'email' : '',
    'resetToken' : '',
    'password' : '',
  };

  void refresh(){
    notifyListeners();
  }

  bool validate(){
    return key.currentState!.validate();
  }
}