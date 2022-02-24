
import 'package:flutter/material.dart';

class AuthFormProvider extends ChangeNotifier {
  final loginKey = GlobalKey<FormState>();
  final registerKey = GlobalKey<FormState>();
  final resetKey = GlobalKey<FormState>();

  Map<String, bool> show = {
    'login'    : false,
    'register' : false,
    'reset'    : false,
    'confirm'  : false,
  };

  void toggleShow(String key){
    show[key] = !show[key]!;
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
    registerBody['avatar'] = image;
    notifyListeners();
  }

  final List<String> _code = List.generate(5, (_) => '');
  
  void updateCode(int index, String value){
    _code[index] = value;
    resetBody['resetToken'] = _code.join();
  }

  Map<String, dynamic> loginBody = {
    'email'    : '',
    'password' : '',
  };

  Map<String, dynamic> registerBody = {
    'name'     : '',
    'email'    : '',
    'password' : '',
    'role'     : '',
    'avatar'    : null,
  };

  void cleanRegisterBody(){
    show['register'] = false;
    image = null;
  }

  Map<String, dynamic> resetBody = {
    'email'    : '',
    'password' : '',
    'resetToken': ''
  };

  void cleanResetBody(){
    for(final key in resetBody.keys){
      resetBody[key] = '';
    }
    show['reset'] = false;
    show['confirm'] = false;
  }

  bool validateLogin(){
    return loginKey.currentState!.validate();
  }

  bool validateRegister(){
    return registerKey.currentState!.validate();
  }

  bool validateReset(){
    return resetKey.currentState!.validate();
  }
}