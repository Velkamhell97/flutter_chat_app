
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// ignore: library_prefixes
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../services/services.dart';
import '../global/globals.dart';

enum ServerStatus {
  online,
  offline,
  connecting
}

class SocketServices  {
  static final String _host = Environment().config.apiHost + '/mobile-chat'; //nsp

  late final IO.Socket socket;
  dynamic socketError;

  final ChatServices? _chat;

  final ValueNotifier<bool> online = ValueNotifier(false);

  static ServerStatus serverStatus = ServerStatus.connecting; //-Metodo estatico, no redibuja

  SocketServices(this._chat){
    socket = IO.io(_host, 
      IO.OptionBuilder()
      .setTransports(['websocket'])
      .disableAutoConnect()
      .enableForceNew() //-Siempre crear nueva conexion al conectarse y desconectarse
      .build()
    );
  }

  void connect(String token, { void Function(dynamic error)? onError }){
    if(socket.active) return; //-Si ya esta corriendo  no haga nada

    try {
      socket.auth = {'token':token};
      socket.connect();

      //-Antes de la conexion se desuscribe para no crear doble listener
      socket.off('user-connect');
      socket.off('user-disconnect');

      socket.on('connect', (_) {
        online.value = true;
        serverStatus = ServerStatus.online;
      });

      socket.on('disconnect', (_) {
        online.value = false;
        serverStatus = ServerStatus.offline;
      });

      //-Por alguna razon no funciona cuando falla un middleware en el server
      socket.on('connect_error', (e) async {
        socketError = 'Error from socket backend';
        socket.disconnect();

        if(onError != null){
          onError(e); //-Error opcional por si se quiere
        }
      });

      //-Forma 1 de actaulziar los usuarios desde este provider de sockets (proxyProvider)
      // socket.on('user-connect', (_) async {
      //   print('user-connected');
      //   // _chat!.getUsers();
      // });

      // socket.on('user-disconnect', (_) async {
      //   print('user-disconnect');
      //   // _chat!.getUsers();
      // });
    } on FormatException catch(e){
      socketError = e;
    }catch (e) {
      socketError = e;
    }
  }

  void disconnect() {
    if(socket.active){
      //-No se sabe si sea mejor manejar una instancia y hacer el clear y disconnect o crear una en el connect y usar el dispose
      //-o crear una en un connect y utilizar el disconnect o destroy
      socket.clearListeners();
      socket.close();
      // socket!.dispose(); //-El disconnect no desecha los anteriores listeners
    }
  }
}