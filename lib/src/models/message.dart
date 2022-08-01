import 'package:flutter/material.dart' show IconData;

import '../models/app_enums.dart';

abstract class Message {
  final String id;
  final String from;
  final String to;
  final String time;
  MessageStatus status; /// Puede cambiar
  bool sender; /// se asigna despues
  final bool unsent; /// Para manejo de errores (solo local)

  Message(
    Map<String, dynamic> data,
  ) : id     = data["_id"],
      from   = data["from"],
      to     = data["to"],
      time   = data["time"],
      sender = false,
      status = MessageStatus.values.byName(data["status"]),
      unsent = data["unsent"] ?? false;

  factory Message.fromJson(Map<String, dynamic> json) {
    if(json["image"] != null){
      return ImageMessage(
        text: json["text"],
        filename: json["image"], 
        tempUrl: json["tempUrl"],
        data: json
      );
    } 

    if(json["video"] != null){
      return VideoMessage(
        text: json["text"],
        filename: json["video"], 
        duration: json["duration"], 
        tempUrl: json["tempUrl"],
        data: json
      );
    } 

    if(json["audio"] != null){
      return AudioMessage(
        filename: json["audio"],
        duration: json["duration"], 
        tempUrl: json["tempUrl"],
        data: json
      );
    } 

    if(json["file"] != null){
      return FileMessage(
        filename: json["file"],
        tempUrl: json["tempUrl"],
        duration: json["duration"],
        data: json
      );
    } 
    
    return TextMessage(
      text: json["text"],
      data: json
    );
  }
}

abstract class MediaMessage extends Message {
  final String filename;
  String? tempUrl;
  bool downloaded;
  String path;
  String? thumbnail; /// El unico que no necesita es el audio
  bool exist;

  MediaMessage({
    required this.filename,
    this.tempUrl,
    this.downloaded = false,
    this.path = "",
    this.thumbnail,
    this.exist = true,
    required Map<String, dynamic> data
  }) : super(data);
}

class TextMessage extends Message {
  final String text;

  TextMessage({
    required this.text,
    required Map<String, dynamic> data
  }) : super(data, );
}

class ImageMessage extends MediaMessage {
  final String? text;

  ImageMessage({
    required String filename,
    this.text,
    String? tempUrl,
    required Map<String, dynamic> data
  }) : super(filename: filename, tempUrl: tempUrl, data: data);
}

class VideoMessage extends MediaMessage {
  final String? text;
  final int duration;

  VideoMessage({
    required String filename,
    this.text,
    required this.duration,
    String? tempUrl,
    required Map<String, dynamic> data
  }) : super(filename: filename, tempUrl: tempUrl, data: data);
}

class AudioMessage extends MediaMessage {
  final int duration;
  Future<List<dynamic>?>? waveform;

  AudioMessage({
    required String filename,
    required this.duration,
    String? tempUrl,
    this.waveform,
    required Map<String, dynamic> data,
  }) : super(filename: filename, tempUrl: tempUrl, data: data);
}

class FileMessage extends MediaMessage {
  IconData? icon;
  int bytes;
  String mime;
  int? duration;
  Future<List<dynamic>?>? waveform;

  FileMessage({
    required String filename,
    String? tempUrl,
    this.icon,
    this.mime = "image",
    this.bytes = 1024,
    this.duration,
    this.waveform,
    required Map<String, dynamic> data,
  }) : super(filename: filename, tempUrl: tempUrl, data: data);
}