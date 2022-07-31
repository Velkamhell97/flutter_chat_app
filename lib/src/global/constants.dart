import 'package:flutter/material.dart' show IconData;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Esta es una forma muy comun de declarar constantes globales, se crea un archivo con esta variables
/// o clases estaticas y se importan desde donde se vayan a utilizar, sin sufijo o con el sufijo as Constants

///Forma 1: la guia de dart dice que evitemos las clases estaticas, en vez de ello propone las top-level-constants
///en los lugares o archivos donde se vayan a utilizar, sin embargo dice que sea una regla de oro y que las
///clases estaticas tambien son una solucion aceptable, aqui ya puede ser de gustos

/// Forma 2 de declarar constates, colocarlas directamente como una top-level-constant
// const String renewToken     = '/api/auth/renew-token';
// const String login          = '/api/auth/login';
// ↓↓↓ Next routes

/// Forma 3, crear clases estaticas para poder tener cierta encapsulacion entre las constantes
// class ApiRoutes {
//   static const String renewToken     = '/api/auth/renew-token';
//   static const String login          = '/api/auth/login';
//   static const String signinPhone    = '/api/auth/signin-phone';
//   static const String signinGoogle   = '/api/auth/signin-google';
//   static const String forgotPassword = '/api/auth/forgot-password';
//   static const String verifyEmail    = '/api/auth/verify-email';
//   static const String resetPassword  = '/api/auth/reset-password';

//   static const String users        = '/api/users';
//   static const String getUsers     = '/api/users/connected';
//   static const String getMessages  = '/api/users/messages';
//   static const String uploadUnread = '/api/users/unread';
//   static const String uploadFile   = '/api/uploads/media';
// }

class AppFolder {
  static const sentDirectory = 'storage/emulated/0/FlutterChat/sent';
  static const receivedDirectory = 'storage/emulated/0/FlutterChat/received';
  static const thumbnailsDirectory = 'storage/emulated/0/FlutterChat/thumbnails';
}

/// Forma 4: los enums permiten crear constantes y ademas encapsularlas, sin embargo, se debe entender el 
/// contexto de los enums, los enums suelen utilizarse cuando se intenta diferencias diferentes estados
/// de un objeto en comun, para el caso de las rutas, no tienen mucho significado ya que las rutas son
/// meras constantes, que nunca se evaluaran o se tendra la condicion if..else / switch para realizar
/// diferentes acciones en base al enum, por esto no serian los mas ideales a utilzar 
// enum ApiRoutes {
//   login('/api/auth/login');
//   // ↓↓↓ Next routes

//   final String value;
//   const ApiRoutes(this.value);
// }

final Map<String, IconData> mimeTypeToIconDataMap = <String, IconData>{
  'image' : FontAwesomeIcons.fileImage,
  'video' : FontAwesomeIcons.fileVideo,
  'audio' : FontAwesomeIcons.fileAudio,
  'application/pdf': FontAwesomeIcons.filePdf,
  'application/msword': FontAwesomeIcons.fileWord,
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document': FontAwesomeIcons.fileWord,
  'application/vnd.oasis.opendocument.text': FontAwesomeIcons.fileWord,
  'application/vnd.ms-excel': FontAwesomeIcons.fileExcel,
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': FontAwesomeIcons.fileExcel,
  'application/vnd.oasis.opendocument.spreadsheet': FontAwesomeIcons.fileExcel,
  'application/vnd.ms-powerpoint': FontAwesomeIcons.filePowerpoint,
  'application/vnd.openxmlformats-officedocument.presentationml.presentation': FontAwesomeIcons.filePowerpoint,
  'application/vnd.oasis.opendocument.presentation': FontAwesomeIcons.filePowerpoint,
  'text/plain': FontAwesomeIcons.fileLines,
  'text/csv': FontAwesomeIcons.fileCsv,
  'application/x-archive': FontAwesomeIcons.fileZipper,
  'application/x-cpio': FontAwesomeIcons.fileZipper,
  'application/x-shar': FontAwesomeIcons.fileZipper,
  'application/x-iso9660-image': FontAwesomeIcons.fileZipper,
  'application/x-sbx': FontAwesomeIcons.fileZipper,
  'application/x-tar': FontAwesomeIcons.fileZipper,
  'application/x-bzip2': FontAwesomeIcons.fileZipper,
  'application/gzip': FontAwesomeIcons.fileZipper,
  'application/x-lzip': FontAwesomeIcons.fileZipper,
  'application/x-lzma': FontAwesomeIcons.fileZipper,
  'application/x-lzop': FontAwesomeIcons.fileZipper,
  'application/x-snappy-framed': FontAwesomeIcons.fileZipper,
  'application/x-xz': FontAwesomeIcons.fileZipper,
  'application/x-compress': FontAwesomeIcons.fileZipper,
  'application/zstd': FontAwesomeIcons.fileZipper,
  'application/java-archive': FontAwesomeIcons.fileZipper,
  'application/octet-stream': FontAwesomeIcons.fileZipper,
  'application/vnd.android.package-archive': FontAwesomeIcons.fileZipper,
  'application/vnd.ms-cab-compressed': FontAwesomeIcons.fileZipper,
  'application/x-7z-compressed': FontAwesomeIcons.fileZipper,
  'application/x-ace-compressed': FontAwesomeIcons.fileZipper,
  'application/x-alz-compressed': FontAwesomeIcons.fileZipper,
  'application/x-apple-diskimage': FontAwesomeIcons.fileZipper,
  'application/x-arj': FontAwesomeIcons.fileZipper,
  'application/x-astrotite-afa': FontAwesomeIcons.fileZipper,
  'application/x-b1': FontAwesomeIcons.fileZipper,
  'application/x-cfs-compressed': FontAwesomeIcons.fileZipper,
  'application/x-dar': FontAwesomeIcons.fileZipper,
  'application/x-dgc-compressed': FontAwesomeIcons.fileZipper,
  'application/x-freearc': FontAwesomeIcons.fileZipper,
  'application/x-gca-compressed': FontAwesomeIcons.fileZipper,
  'application/x-gtar': FontAwesomeIcons.fileZipper,
  'application/x-lzh': FontAwesomeIcons.fileZipper,
  'application/x-lzx': FontAwesomeIcons.fileZipper,
  'application/x-ms-wim': FontAwesomeIcons.fileZipper,
  'application/x-rar-compressed': FontAwesomeIcons.fileZipper,
  'application/x-stuffit': FontAwesomeIcons.fileZipper,
  'application/x-stuffitx': FontAwesomeIcons.fileZipper,
  'application/x-xar': FontAwesomeIcons.fileZipper,
  'application/x-zoo': FontAwesomeIcons.fileZipper,
  'application/zip': FontAwesomeIcons.fileZipper,
  'text/html': FontAwesomeIcons.code,
  'text/javascript': FontAwesomeIcons.code,
  'text/css': FontAwesomeIcons.code,
  'text/x-python': FontAwesomeIcons.code,
  'application/x-python-code': FontAwesomeIcons.code,
  'text/xml': FontAwesomeIcons.code,
  'application/xml': FontAwesomeIcons.code,
  'text/x-c': FontAwesomeIcons.code,
  'application/java': FontAwesomeIcons.code,
  'application/java-byte-code': FontAwesomeIcons.code,
  'application/x-java-class': FontAwesomeIcons.code,
  'application/x-csh': FontAwesomeIcons.code,
  'text/x-script.csh': FontAwesomeIcons.code,
  'text/x-fortran': FontAwesomeIcons.code,
  'text/x-h': FontAwesomeIcons.code,
  'application/x-ksh': FontAwesomeIcons.code,
  'text/x-script.ksh': FontAwesomeIcons.code,
  'application/x-latex': FontAwesomeIcons.code,
  'application/x-lisp': FontAwesomeIcons.code,
  'text/x-script.lisp': FontAwesomeIcons.code,
  'text/x-m': FontAwesomeIcons.code,
  'text/x-pascal': FontAwesomeIcons.code,
  'text/x-script.perl': FontAwesomeIcons.code,
  'application/postscript': FontAwesomeIcons.code,
  'text/x-script.phyton': FontAwesomeIcons.code,
  'application/x-bytecode.python': FontAwesomeIcons.code,
  'text/x-asm': FontAwesomeIcons.code,
  'application/x-bsh': FontAwesomeIcons.code,
  'application/x-sh': FontAwesomeIcons.code,
  'text/x-script.sh': FontAwesomeIcons.code,
  'text/x-script.zsh': FontAwesomeIcons.code,
  'default': FontAwesomeIcons.file,
};