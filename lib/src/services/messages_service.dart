import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:mime/mime.dart';
import 'dart:io';
import 'dart:async';

import '../global/globals.dart';
import '../extensions/string_apis.dart';
import '../services/services.dart';
import '../models/models.dart';

const String userMessagesRoute   = '/messages';

class MessagesService {
  final SocketsService _socket;
  final AuthService _auth;
  final FilesService _files;
  final UsersService _users;

  MessagesService(
    this._socket, 
    this._auth,
    this._files,
    this._users
  ) {
    _dio.options.baseUrl = '$_host/api/users';
    _dio.options.connectTimeout = 10000;
  }

  /// Como es una clase normal debemos hacer el dispose manualmente y pasarlo al dispose del main, no se sabe
  /// si esto sea realmente necesario, ya que solo se llama este metodo al cerrar la app
  void dispose() {
    _messagesStreamController.close();
    _dio.close();
  }

  final _host = Environment.apiHost;
  final listKey = GlobalKey<SliverAnimatedListState>();
  final _dio = Dio();

  static const _platform = MethodChannel('com.example.chat_app/channel');
  static const _mediaTypes = ['image', 'audio', 'video', 'file'];

  List<Message> messages = [];
  bool _sending = false;

  final StreamController<List<Message>> _messagesStreamController = StreamController.broadcast();
  Stream<List<Message>> get messagesStream => _messagesStreamController.stream;

  /// Stream para comunicar a algun Provider o Widget, cuando se complete un envio de mensaje
  /// en el servidor, util para sincronizar pero casi nunca se espera que se envie el mensaje
  /// para hacer una accion como borrar el textfield
  // final StreamController<Message> _messageStreamController = StreamController.broadcast();
  // Stream<Message> get messageStream => _messageStreamController.stream;

  Future<void> _preloadData(Message message, bool sender) async {
    message.sender = sender;

    /// Solo si es un media message se asigna el future para que no se mantenga ese estado
    if(message is MediaMessage){
      /// Dependiendo de quien lo envie, cambia el directorio
      final folder = message.sender ? AppFolder.sentDirectory : AppFolder.receivedDirectory;
      
      message.path = '/$folder/${message.filename}';
      
      final file = File(message.path);

      /// Verificamos si existe el file
      message.exist = file.existsSync();

      /// Si no existe el file (si es sender deberia existir), se descarga nuevamente, y si se obtiene
      /// un error se deja como que no existe (se deberia habilitar el boton para intentar descargar)
      if(!message.exist){
        // print('download');
        final error = await _files.downloadFile(message);
        message.exist = error == null;
      }

      final mime = lookupMimeType(message.filename) ?? 'image/jpg';

      if(message is FileMessage) {
        /// Si es un file asignamos las propiedades propias, podriamos guardar tambien en la DB el size
        /// para no obtenerlo aqui
        message.mime = mime;
        message.bytes = file.lengthSync();
        message.icon = mimeTypeToIconDataMap[mime.split('/')[0]] ?? mimeTypeToIconDataMap[mime];

        if(mime.startsWith('audio')){
          /// Si es un audio obtenemos el waveform, para videos o audios ya se tiene la duracion
          message.waveform = _platform.invokeMethod<List<dynamic>>('processAudio', {'path':message.path});
        }
      } else if(message is AudioMessage ){
        /// Tambien podriamos obtener la waveform para messages tipo files, ya tenemos el path
        message.waveform = _platform.invokeMethod<List<dynamic>>('processAudio', {'path':message.path});
      }

      /// los thumbnails se generaran siempre en el downloaded y se guardaran en la carpeta, aqui solo 
      /// devolvemos el path a ese thumbnail, no un Unit8List
      if(mime.startsWith('image')){
        /// si es una imagen, no se tiene como tal un thumbnail, se utiliza la misma imagen
        message.thumbnail = file.path;
      } else if(mime.startsWith('video') || mime.endsWith('pdf')) {
        /// Si hay un video o pdf, se debe ubicar el thumbnail en la carpeta
        final parts = message.filename.parseFile();
        
        final thumbnailFilename = '${parts[0]}.png';
        final thumbnailPath = '/${AppFolder.thumbnailsDirectory}/$thumbnailFilename';
        
        message.thumbnail = thumbnailPath;
      }
    }
  }

  Future<void> getMessages(String from, String to) async { 
    final route = '$userMessagesRoute/$to';
    
    final options = Options(headers: {'x-token': AuthService.token});

    try {
      final response = await _dio.get(route, options: options);

      final messagesResponse = MessagesResponse.fromJson(response.data);

      messages = messagesResponse.messages;

      final List<Future<void>> _futures = [];

      for(Message message in messages){
        final sender = message.from == from;
        _futures.add(_preloadData(message, sender));
      }

      await Future.wait(_futures);

      _messagesStreamController.add(messages);
    } catch (e) {
      final error = ErrorResponse.fromObject(e);
      _messagesStreamController.addError(error);
    }
  }

  Future<void> addMessage({required Message message, required bool sender}) async {
    await _preloadData(message, sender);
    messages.insert(0, message);
    listKey.currentState?.insertItem(0); /// la animatedList hace rebuild
  }

  Future<void> addMessages({required List<Message> messages, required bool sender}) async {
    final List<Future<void>> _futures = [];

    for(Message message in messages){
      _futures.add(_preloadData(message, sender));
    }

    await Future.wait(_futures);

    this.messages.insertAll(0, messages);
    _messagesStreamController.add(this.messages);

    for (int i = 0; i < messages.length; i++) {
      listKey.currentState?.insertItem(0 + i);
    }
  }

  Future<void> sendMessage(Map<String, dynamic> message) async {
    /// Puede detener el envio de mensajes consecutivos
    if(_sending) return;

    _sending = true;

    /// Se podria inyectar la dependencia de chat, pero se deja asi
    message["time"] = DateFormat("hh:mm a").format(DateTime.now());
    message["downloaded"] = true;

    final media = message.keys.any((element) => _mediaTypes.contains(element));

    final name = _auth.user!.name;
    final avatar = _auth.user!.avatar;

    if(_socket.online.value) {
      final data = {...message, 'media': media, 'name': name, 'avatar': avatar};

      _socket.emitWithAck('message-sent', data, ack: (json) async {
        final message = Message.fromJson(json["message"]);
        addMessage(message: message, sender: true);
        _sending = false;

        ///Actualizamos el ultimo mensaje y subimos la conversacion al inicio
        _auth.user!.latest[message.to] = json["last"];
        _users.refresh(message.to);
      });
    } else {
      message["_id"] = message.hashCode.toString();
      message["unsent"] = true;
      message["status"] = MessageStatus.unsent.name;

      addMessage(message: Message.fromJson(message), sender: true);
      _sending = false;
    }
  }

  Future<void> sendMessages(List<Map<String, dynamic>> messages) async {
    if(_sending) return;

    _sending = true;

    final name = _auth.user!.name;
    final avatar = _auth.user!.avatar;

    for(Map<String, dynamic> message in messages) {
      message["time"] = DateFormat("hh:mm a").format(DateTime.now());
    }
    
    if(_socket.online.value) {
       final data = {'messages': jsonEncode(messages.reversed.toList()), 'name': name, 'avatar': avatar};

      _socket.emitWithAck('messages-sent', data, ack: (json) async {
        final messages = List<Message>.from(json["messages"].map((m) => Message.fromJson(m)));
        addMessages(messages: messages, sender: true);

        _sending = false;
        _auth.user!.latest[messages[0].to] = json["last"];
        _users.refresh(messages[0].to);
      });
    } else {
      messages[0]["_id"] = messages[0].hashCode.toString();
      messages[0]["unsent"] = true;
      messages[0]["status"] = MessageStatus.unsent.name;
      messages[0]["text"] = 'Failed to send multiple files';

      addMessage(message: Message.fromJson(messages[0]), sender: true);
      _sending = false;
    }    
  }

  void onMessageReceived() {
    /// El primero porque la lista esta al reves
    messages.first.status = MessageStatus.received;
    _messagesStreamController.add(messages);
  }

  void onMessageRead() {
    /// Puede que sea mejor buscarla por el id en vez de el ultimo
    messages.first.status = MessageStatus.read;
    _messagesStreamController.add(messages);
  }

  void onMessagesRead(int count) {
    /// Puede que mientras se actualizan cambien el count
    for (int i = 0; i < count; i++) {
      messages[i].status = MessageStatus.read;
    }

    _messagesStreamController.add(messages);
  }

  void onMediaUpdated(String id, String tempUrl) {
    ///Para no disparar el upload de nuevo
    final message = messages.firstWhere((element) => element.id == id) as MediaMessage;
    message.tempUrl = tempUrl;
    _messagesStreamController.add(messages);
  }

  void onMediaDownloaded(String id) {
    ///Para no disparar el upload de nuevo
    final message = messages.firstWhere((element) => element.id == id) as MediaMessage;
    message.downloaded = true;
    _messagesStreamController.add(messages);
  }
}