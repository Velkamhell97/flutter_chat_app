import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

import '../global/constants.dart';

class PermissionsService {
  static const _platform = MethodChannel('com.example.chat_app/channel');

  /// Se podria inicializar en el constructor
  Future<int> _getAndroidVersion() async {
    try {
      return await _platform.invokeMethod('getAndroidVersion');
    } catch (e) {
      return 30;
    }
  }

  //-Hay otras opciones de almacenamiento con mejores practicas como utilizar el externalAppStorage (com.app)
  //-o en media, que es donde se pueden almacenar estos archivos de media, sin tener tantos problemas de seguridad
  Future<void> _createAppFolder() async {
    final sentFolder = Directory(AppFolder.sentDirectory);
    final receivedFolder = Directory(AppFolder.receivedDirectory);
    final thumbnailsFolder = Directory(AppFolder.thumbnailsDirectory);

    if(!sentFolder.existsSync()){
      sentFolder.createSync(recursive: true);
    }

    if(!receivedFolder.existsSync()){
      receivedFolder.createSync(recursive: true);
    }

    if(!thumbnailsFolder.existsSync()){
      thumbnailsFolder.createSync(recursive: true);
    }
  }

  //-Podriamos almacenar en un shared preferences si el usuario previamente dio el permiso para
  //-no ejecutar toda la funcion de nuevo, sin embargo, si este llega a desactivar un permiso manualmente
  //-no se podria detectar y actualizar el sp
  Future<bool> checkStoragePermissions() async {
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
}