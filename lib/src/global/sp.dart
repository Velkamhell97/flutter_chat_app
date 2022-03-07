import 'package:shared_preferences/shared_preferences.dart';

class SP {
  SP._internal();
 
  static final SP _sp = SP._internal();

  factory SP(){
    return _sp;
  }

  late SharedPreferences _prefs;

  Future<void> initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  int get fileId => _prefs.getInt('fileId') ?? 0;

  set fileId(int value) => _prefs.setInt('fileId', value);
}