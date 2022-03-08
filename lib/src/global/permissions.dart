import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'enviorement.dart';

class Permissions {
  static final _appFolder = Environment().appFolder;
  static const _platform = MethodChannel('samples.flutter.dev/sdk');

  static Future<int> _getAndroidVersion() async {
    try {
      return await _platform.invokeMethod('getAndroidVersion');
    } catch (e) {
      // print(e);
      return 30;
    }
  }

  //-Se podria guardar la informacion en el folder de la app, que no necesita permisos (parece), mientras
  //-se aceptan los permisos para pasarlo a una carpeta local, esta bandera se podria guardar en los sharedPreferences
  static Future<bool> checkStoragePermissions() async {
    PermissionStatus status =  await Permission.storage.status;

    if(!status.isGranted){
      status = await Permission.storage.request();
    } 
    
    final androidVersion = await _getAndroidVersion();

    if(status.isGranted){
      if(androidVersion > 29) {
        status = await Permission.manageExternalStorage.status;
        if(!status.isGranted){
          status = await Permission.manageExternalStorage.request();
         }
      }
    }

    if(status.isGranted){
      await _createAppFolder();
      return true;
    } else {
      return false;
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
        //-crear folders
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