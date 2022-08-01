import 'package:flutter/material.dart';

import '../models/models.dart';
import '../singlentons/locales_service.dart';

class AuthProvider extends ChangeNotifier {
  final key = GlobalKey<FormState>();
  final codeKey = GlobalKey<FormState>();

  final location = LocalesService();
  
  final otpTimeout = 30;
  bool _mounted = true; /// Evita actualizar la ui luego del dispose del provider

  /// Parametros para reutilizar este provider
  AuthProvider({String? email, Map<String, String>? phone}){
    body['email'] = email;

    /// Alterntaiva al provider.value, al no poder compartir la misma referencia se tienen que pasar
    /// los datos de inicializacion por parametros, el problema esque no se puede controlar un form desde otro
    if(phone != null){
      this.phone = phone;
    }

    country = location.country;
  }

  /// Pueden ser nulos al enviar al servidor
  Map<String, String?> body = {
    'name'     : null,
    'email'    : null,
    'password' : null,
    'avatar'   : null,
  };

  /// No se envian al servidor pueden setearse vacios y las validaciones atraparan
  Map<String, String> phone = {
    'country'        : '',
    'number'         : '',
    'verificationId' : '',
    'code'           : '',
    'resendToken'    : '',
  };

  String get fullPhone => phone["country"]! + phone["number"]!;

  bool validate() => key.currentState!.validate();
  bool validateCode() => codeKey.currentState!.validate();

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  /// Para evitar que haya un error al hacer una peticion y navegar a otra pantalla
  void _notifyListeners() {
    if(_mounted){
      notifyListeners();
    }
  }

  //----------------------------
  // Notify Variables
  //----------------------------
  ErrorResponse? _error;
  ErrorResponse? get error => _error;
  set error(ErrorResponse? error) {
    if(error != null){
      _loading = false;
      _tokenSent = false;
    }

    _error = error;
    _notifyListeners();
  }
  
  bool _loading = false;
  bool get loading => _loading;
  set loading(bool loading) {
    if(loading){
      _error = null;
    }

    _loading = loading;
    _notifyListeners();
  }

  Country? _country;
  Country? get country => _country;
  set country(Country? country) {
    _country = country;

    phone["country"] = country?.code ?? '';

    _notifyListeners();
  }
  
  bool _tokenSent = false;
  bool get tokenSent => _tokenSent;
  set tokenSent(bool tokenSent) {
    if(tokenSent) {
      _loading = false;
    }

    _tokenSent = tokenSent;

    _notifyListeners();
  }

  /// Para autocompletar el codigo sms
  String? _smsCode;
  String? get smsCode => _smsCode;
  set smsCode(String? smsCode) {
    if(!_loading){
      _loading = true;
      _error = null;
    }

    _smsCode = smsCode;
    notifyListeners();
  }
}