import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageRoute;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

import '../../singlentons/sp.dart';
import '../../providers/message_provider.dart';
import '../../services/services.dart';
import '../../models/models.dart';
import '../../widgets/chat/chat.dart';
import 'chat.dart';

class UsersPage extends StatefulWidget {
  final String? appLaunchPayload;

  const UsersPage({Key? key, this.appLaunchPayload}) : super(key: key);

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> with WidgetsBindingObserver {
  late final AuthService auth;
  late final SocketsService socket;
  late final UsersService users;
  late final DialogsService dialogs;
  late final MessageProvider chat;

  AppLifecycleState _appState = AppLifecycleState.resumed;

  final _player = AudioPlayer();
  final _sp = SP();

  User? get _user => auth.user;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _initServices();
    
    _player.setSourceAsset('audios/incoming.mp3');
    
    socket.connect(AuthService.token!, onError: (_) {});
    
    chat.message["from"] = _user?.uid;

    _getUsers();

    if(_sp.fcmToken.isEmpty){
      FirebaseMessaging.instance.getToken().then((token) {
        auth.updateUser({'token':token});
        _sp.fcmToken = token ?? '';
      });
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) async { 
      if(widget.appLaunchPayload != null){
        _onAppLaunchDetails();
      } else {
        final storagePermissions = await context.read<PermissionsService>().checkStoragePermissions();

        if(!storagePermissions){
          await Future.delayed(const Duration(milliseconds: 200));

          /// Podria hacerse manualmente con el showGeneralDialog
          dialogs.showAppDialog(dialog: AppDialog.storagePermissionDialog);
        } else {
          _listenForMessages();
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _appState = state;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _player.dispose();
    chat.message.remove("from");
    super.dispose();
  }

  void _initServices() {
    auth = Provider.of<AuthService>(context, listen: false);
    socket = Provider.of<SocketsService>(context, listen: false);
    users = Provider.of<UsersService>(context, listen: false);
    chat = Provider.of<MessageProvider>(context, listen: false);
    dialogs = Provider.of<DialogsService>(context, listen: false);
  }

  void _getUsers() {
    users.getUsers().then((_) {
      socket.on('user-connect', (id) {
        if(_user!.uid != id) {
          users.connect(id);
        }
      });

      socket.on('user-disconnect', (id) => users.disconnect(id));
    });
  }

  void _onAppLaunchDetails() {
    final payload = jsonDecode(widget.appLaunchPayload!);
    
    final user = User.fromJson(payload);
    
    final route = CupertinoPageRoute(builder: (_) => ChatPage(receiver: user));
    
    Navigator.of(context).push(route);
  }

  void _listenForMessages() {
    final messages = Provider.of<MessagesService>(context, listen: false);
    final files = Provider.of<FilesService>(context, listen: false);

    socket.on('incoming-message', (json) async {
      // print('message');
      final message = Message.fromJson(json["message"]);

      if(message is MediaMessage){
        final error = await files.downloadFile(message);

        if(error != null){
          dialogs.showSnackBar(error.message);
          return; 
        }
      }

      _user!.latest[message.from] = json["last"];

      final to = chat.message["to"];
      
      final data = {
        "userId": message.to, 
        "senderId": message.from, 
        "messageId": message.id, 
        "text": json["last"],
        "name": json["name"], 
        "avatar": json["avatar"]
      };

      if(_appState == AppLifecycleState.paused){
        /// En background siempre notifica, solo aumenta el badge
        socket.emitWithAck('message-unread', {...data, 'notify':true}, ack: (payload) {
          _user!.unreads[payload["id"]] = payload["count"];
          users.refresh(payload["id"]);
        });
      } else if(_appState == AppLifecycleState.resumed) {
        if(to == null || to != message.from){
          /// En home o en otro chat aumenta el badge, notifica solo si esta en otro chat
          final notify = to != null && to != message.from;

          socket.emitWithAck('message-unread', {...data, 'notify':notify}, ack: (payload) {
            if(to == null) _player.resume();

            debugPrint('counter: ${payload["count"]}');

            _user!.unreads[payload["id"]] = payload["count"];
            users.refresh(payload["id"]);
          });
        } else { 
          /// En el mismo chat no aumenta el badge
          await messages.addMessage(message: message, sender: false);
          socket.emit('message-read', message.id);
          users.refresh(null);
        }
      }
    });

    /// No se ejecuta cada imagen multiple se sube por independiente y dispara el incoming-message
    // socket.on('incoming-messages', (json) async { ... });
  }
  
  void _logout() {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    auth.signout();
    socket.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      ///----------------------------
      /// AppBar
      ///----------------------------
      appBar: AppBar(
        backgroundColor: const Color(0xff4c84b6),
        foregroundColor: Colors.white,
        // systemOverlayStyle: const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
        title: Text(_user?.name ?? 'User'),
        leading: ValueListenableBuilder<bool>(
          valueListenable: socket.online,
          builder: (_, online, __) => Icon(
            online ? Icons.check_circle : Icons.offline_bolt, 
            color: online ? Colors.white : Colors.redAccent
          )
        ),
        actions: [IconButton(onPressed: _logout, icon: const Icon(Icons.exit_to_app))],
      ),

      ///----------------------------
      /// Users List
      ///----------------------------
      body: StreamBuilder<List<User>>(
        initialData: null,
        stream: users.usersStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final error = snapshot.error as ErrorResponse;
            return Text('Error while loading the users: ${error.message}');
          }

          final users = snapshot.data!;

          return ListView.separated(
            physics: const BouncingScrollPhysics(),
            separatorBuilder: (context, index) => const Divider(thickness: 1),
            itemCount: users.length,
            itemBuilder: (_, index)  {
              final user = users[index];

              return UserTile(
                user: user,
                unreads: _user?.unreads[user.uid] ?? 0,
                last: _user?.latest[user.uid] ?? '',
              );
            },
          );
        },
      ),
    );
  }
}