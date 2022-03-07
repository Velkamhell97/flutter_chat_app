import 'dart:convert';
import 'package:chat_app/services/file_servides.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart' hide RefreshIndicator;

import 'package:chat_app/services/services.dart';
import 'package:chat_app/models/models.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({Key? key}) : super(key: key);

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  late final AuthServices auth;
  late final SocketServices socket;
  late final ChatServices chat;

  //-Se necesita un staful para craer una variable final y con el constructor del widget como const
  final _refreshController = RefreshController(initialRefresh: false);

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    // await chat.getUsers(); //-actualizacion usuarios manual

    _refreshController.refreshCompleted();
  }

  void _logout({dynamic error}) { //-Error en caso de conexion por socket
    Navigator.of(context).pushReplacementNamed('/login');
    auth.signout();
    chat.close();
    socket.disconnect();
  }

  @override
  void initState() {
    super.initState();

    auth = Provider.of<AuthServices>(context, listen: false);
    chat = Provider.of<ChatServices>(context, listen: false);
    socket = Provider.of<SocketServices>(context, listen: false);
    final file = Provider.of<FileServices>(context, listen: false);

    //Socket.connect(AuthServices.token!, onError: (e) => _logout(error: e));
    socket.connect(AuthServices.token!);

    //Forma 2 de actualizar los usuarios desde el provider de socket (exponer el socket)
    socket.socket.on('user-connect', (_) => chat.getUsers());
    socket.socket.on('user-disconnect', (_) => chat.getUsers());

    WidgetsBinding.instance!.addPostFrameCallback((_) async { 
      final storagePermissions = await Permissions.checkStoragePermissions();
      
      if(!storagePermissions){
        await Future.delayed(const Duration(milliseconds: 200));
        Notifications.showStoragePermissionDialog(context);
      } else {
        socket.socket.on('chat-message', (payload) async {
          final json = jsonDecode(payload);
          final message = Message.fromJson(json['message']);

          if(message.image != null || message.audio != null){
            await file.downloadFile(message.tempUrl!, message.image ?? message.audio!);
            file.deleteTempFile(message.tempUrl!); //No se hace el await para actaulizar la ui mas rapido
          } 

          chat.uploadUnread(message.from).then((value) {
            if(value != null){
              auth.user!.unread[message.from] = value;
              chat.updateStream();
            }
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF2F2F2),

      //----------------------------
      // AppBar
      //----------------------------
      appBar: AppBar(
        title: Text(auth.user!.name),
        leading: ValueListenableBuilder<bool>(
          valueListenable: socket.online,
          builder: (_, online, __) => Icon(
            online ? Icons.check_circle : Icons.offline_bolt, 
            color: online ? Colors.blue : Colors.redAccent
          )
        ),
        actions: [IconButton(onPressed: _logout, icon: const Icon(Icons.exit_to_app))],
      ),

      //----------------------------
      // Users List
      //----------------------------
      body: StreamBuilder<List<User>>(
        initialData: null,
        stream: chat.usersStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Text('Error');
          }

          final users = snapshot.data!;

          return SmartRefresher(
            controller: _refreshController,
            onRefresh: _onRefresh,
            header: WaterDropHeader(
              idleIcon: const Icon(Icons.check, color: Colors.white, size: 15),
              waterDropColor: Colors.blue,
              complete: Icon(Icons.check_circle, color: Colors.blue.shade300),
            ),
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              separatorBuilder: (context, index) => const Divider(thickness: 1),
              itemCount: users.length,
              itemBuilder: (_, index)  {
                return _UserTile(user: users[index]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final User user;

  const _UserTile({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthServices>(context);
    final chat = Provider.of<ChatServices>(context);
    final Color color = user.online ? Colors.green.shade300 : Colors.red.shade300;

    final unreadMsg = auth.user?.unread[user.uid] ?? 0;

    return Stack(
      children: [
        ListTile(
          leading: CircleAvatar(
            child: Text(user.name.substring(0, 2)),
            backgroundColor: Colors.blue[100],
          ),
          trailing: Icon(Icons.circle, color: color, size: 16),
          title: Text(user.name),
          subtitle: Text(user.email),
          onTap: () {
            final chat = Provider.of<ChatServices>(context, listen: false);
            final socket = Provider.of<SocketServices>(context, listen: false).socket;

            chat.receiverUser = user;
            chat.chatMessages = null;
            socket.off('chat-message');

            Navigator.of(context).pushNamed('/chat');
          },
        ),
        if(unreadMsg != null && unreadMsg != 0)
          Positioned(
            right: 10,
            top: 0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.shade100
              ),
              padding: const EdgeInsets.all(5.0),
              child: Text(unreadMsg.toString()),
            ),
          )
      ],
    );
  }
}
