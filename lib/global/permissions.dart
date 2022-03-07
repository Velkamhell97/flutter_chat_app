import 'package:permission_handler/permission_handler.dart';

import 'package:chat_app/global/enviorement.dart';

class Permissions {
  static final _appFolder = Environment().appFolder;

  //-Se podria guardar la informacion en el folder de la app, que no necesita permisos (parece), mientras
  //-se aceptan los permisos para pasarlo a una carpeta local, esta bandera se podria guardar en los sharedPreferences
  static Future<bool> checkStoragePermissions() async {
    final status =  await Permission.storage.status;

    if(!status.isGranted){
      final newStatus = await Permission.storage.request();
      
      if(!newStatus.isGranted){
        return false;
      } else {
        await _createAppFolder();
        return true;
      }
    } else {
      await _createAppFolder();
      return true;
    }
  }

  static Future<bool> checkAudioPermissions() async {
    final status =  await Permission.microphone.status;

    if(!status.isGranted){
      //-Se deberia tambien evaluar que tenga los servicios de storage para guardar los audios
      final newStatus = await Permission.microphone.request();
      
      if(!newStatus.isGranted){
        return false;
      } else {
        return true;
      }
    } else {
      return true;
    }
  }

  static Future<void> _createAppFolder() async {
    if(!await _appFolder.sent.exists()){
      await _appFolder.sent.create(recursive: true);
    }

    if(!await _appFolder.received.exists()){
      await _appFolder.received.create(recursive: true);
    }
  }
}