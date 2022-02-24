import 'dart:io';

abstract class BaseConfig {
  String get apiHost;
  bool get useHttps;
}

class DevConfig implements BaseConfig {
  //Para que funcione el 10.0.2.2 en android +28 se debe agregar la configuracion al manifest
  @override
  String get apiHost => Platform.isAndroid ? '192.168.1.19:8080' : 'localhost:8080';

  @override
  bool get useHttps => false;
}

class ProdConfig implements BaseConfig {
  @override
  String get apiHost => "flutter-chat-back.herokuapp.com";

  @override
  bool get useHttps => true;
}

enum Env {
  DEV,
  PROD
}

class Environment {
  //-Constructor privado
  Environment._internal();

  //-Variable estatica privada que mantiene su valor sin importar la instanciacion, genera la unica instancia privada
  static final Environment _singlenton = Environment._internal();

  //-el constructor nombrado crea una instancia de la clase, no recibe parametros, tiene acceso al this
  //-el factory solo retorna una instancia de la clase en tiempo de ejecucion, no tiene acceso al this, almacena en cache
  factory Environment(){
    return _singlenton;
  }

  late BaseConfig config;

  initConfig(Env environment){
    config = _getConfig(environment);
  }

  BaseConfig _getConfig(Env environment){
    switch (environment) {
      case Env.DEV:
        return DevConfig();
      case Env.PROD:
        return ProdConfig();
    }
  }
}