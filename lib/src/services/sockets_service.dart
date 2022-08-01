import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../global/enviorement.dart';
import '../models/models.dart';

class SocketsService  {
  SocketsService(){
    socket = io.io(_host, 
      io.OptionBuilder()
      .setTransports(['websocket'])
      .disableAutoConnect()
      .enableForceNew() /// Siempre crear nueva conexion al conectarse y desconectarse
      .build()
    );
  }
  
  void dispose() {
    if(socket.active){
      socket.dispose();
    }
    online.dispose();
  }

  late final io.Socket socket;
  final String _host = Environment.apiHost + '/chat'; //nsp

  Function get emit => socket.emit;
  Function get emitWithAck => socket.emitWithAck;
  Function get on => socket.on;
  Function get off => socket.off;

  /// Para no manejar un changeNotifier para una sola variable
  final ValueNotifier<bool> online = ValueNotifier(true);

  /// No conectamos automaticamente porque debemos pasar el token de autenticacion
  void connect(String token, { void Function(ErrorResponse error)? onError }){
    if(socket.active) return; /// Si ya esta corriendo  no haga nada

    try {
      socket.auth = {'token':token};
      socket.connect();

      socket.on('connect', (_) {
        debugPrint('sockets connected');
        online.value = true;
      });

      socket.on('disconnect', (_) {
        debugPrint('sockets disconnected');
        online.value = false;
      });

      /// Por alguna razon no funciona cuando falla un middleware en el server, no se puede lanzar un throw
      /// porque este es un metodo asincrono, 
      socket.on('connect_error', (e) async {
        debugPrint('socket error: $e');
        socket.disconnect();

        if(onError != null){
          onError(ErrorResponse.fromObject(e));
        }
      });

    } catch (e) {
      if(onError != null) {
        onError(ErrorResponse.fromObject(e));
      }
    }
  }

  void disconnect() {
    if(socket.active){
      socket.clearListeners();
      socket.close();
      // socket!.dispose(); //-El disconnect no desecha los anteriores listeners
    }
  }
}