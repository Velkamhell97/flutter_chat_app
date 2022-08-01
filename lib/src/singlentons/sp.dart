import 'package:shared_preferences/shared_preferences.dart';

/// Por alguna razon no recomiendan mucho las clases singlenton o clases estaticas, unicamente las utilizan
/// cuando por ejemplo se tiene que inicializar un metodo en el main, es decir que no se puedan usar provider
/// por ejemplo en este ejemplo podriamos utilizar la funcion SharedPreferences.getInstance(), siempre que 
/// necesitemos la instancia, pero en este caso se dejara de esta manera
class SP {
  SP._internal();
 
  static final SP _instance = SP._internal();

  factory SP() => _instance;

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  int get fileId => _prefs.getInt('fileId') ?? 0;
  set fileId(int value) => _prefs.setInt('fileId', value);

  String get fcmToken => _prefs.getString('fcmToken') ?? '';
  set fcmToken(String value) => _prefs.setString('fcmToken', value);
  
  ///Para mostrar notificaciones o no si esta auth o no (no utilizado)
  bool get loged => _prefs.getBool('loged') ?? false;
  set loged(bool value) => _prefs.setBool('loged', value);
}