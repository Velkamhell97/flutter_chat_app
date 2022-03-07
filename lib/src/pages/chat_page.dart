import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../providers/providers.dart';
import '../models/models.dart';
import '../global/globals.dart';
import '../services/services.dart';
import '../widgets/widgets.dart';

class ChatState extends StatelessWidget {
  const ChatState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fromUser = Provider.of<AuthServices>(context, listen: false).user!;
    final toUser = Provider.of<ChatServices>(context, listen: false).receiverUser!;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ChatProvider(fromUser.uid, toUser.uid)),
        ChangeNotifierProvider(create: (context) => AudioProvider())
      ],
      child: const ChatPage(),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ChatProvider input;
  late final AuthServices auth;

  @override
  void initState() {
    super.initState();

    input = Provider.of<ChatProvider>(context, listen: false);
    auth = Provider.of<AuthServices>(context, listen: false);
    final chat = Provider.of<ChatServices>(context, listen: false);
    final file = Provider.of<FileServices>(context, listen: false);
    final socket = Provider.of<SocketServices>(context, listen: false).socket;

    chat.getChatMessages().then((_) {
      if(chat.error == null){
        final unread = chat.chatMessages!.where((message) {
          return message.from != auth.user!.uid && !message.read;
        }).toList();

        //-Aqui solo actualizamos el numero en el mapa del user en la DB
        if(unread.isNotEmpty){
          chat.uploadUnread(unread.first.from, reset: true).then((value) {
            if(value != null){
              auth.updateUnread(chat.receiverUser!.uid, value);
            } else {
              final error = chat.error!.details.msg;
              Notifications.showSnackBar(error);
            }
          });
        }

        //aqui cambiamos el estado de los mensajes a leidos
        for (var i = 0; i < unread.length; i++) {
          chat.chatMessages![i].read = true;
          socket.emit('message-read', unread[i].id);
        }
      }
    });

    socket.on('chat-message', (payload) async {
      if(chat.receiverUser != null){
        final json = jsonDecode(payload);
        final message = Message.fromJson(json['message']);

        if(message.image != null || message.audio != null){
          await file.downloadFile(message.tempUrl!, message.image ?? message.audio!);
          file.deleteTempFile(message.tempUrl!); //No se hace el await para actaulizar la ui mas rapido
        } 

        message.read = true;
        chat.addMessage(message);

        if(input.listKey.currentState != null){
          input.listKey.currentState!.insertItem(0);
        }

        socket.emit('message-read', message.id);
      }
    });
  } 

  static const _messagePadding = 10.0;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mq = MediaQuery.of(context);
    final bottomInset = mq.viewInsets.bottom + mq.padding.bottom;

    final chat = Provider.of<ChatServices>(context);

    return WillPopScope(
      onWillPop: () async {
        chat.receiverUser = null;
        return true;
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: SafeArea(
            child: Stack(
              // fit: StackFit.expand,
              children: [
                //---------------------------------
                // Background
                //---------------------------------
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/chat-bg.jpg'),
                        fit: BoxFit.fill
                      )
                    ),
                  ),
                ),
    
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    //---------------------------------
                    // Header
                    //---------------------------------
                    _Header(user: chat.receiverUser!),
    
                    //---------------------------------
                    // Messages
                    //---------------------------------
                    Flexible(
                      child: Builder(
                        builder: (context) {
                          if(chat.chatMessages == null){
                            return const Center(child: CircularProgressIndicator());
                          }
    
                          if(chat.error != null) {
                            final error = chat.error!.details.msg;
                            return Text('Error while loading the users: $error');
                          }
    
                          return AnimatedList(
                            key: input.listKey,
                            initialItemCount: chat.chatMessages!.length,
                            padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 0.0),
                            physics: const BouncingScrollPhysics(),
                            reverse: true, //-Empezamos en el ultimo elemento y scroleamos hacia arriba
                            itemBuilder: (_, index, animation) {
                              final message = chat.chatMessages![index];
    
                              return SizeTransition(
                                sizeFactor: CurvedAnimation(parent: animation, curve: Curves.easeOut),
                                axisAlignment: -1.0,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: _messagePadding),
                                  child: ChatMessage(message: message, sender: message.from == auth.user!.uid ),
                                ),
                              );
                            },
                          );
                        },
                      )
                    ),
    
                    //Opcion 1, la opcion 2 es el boxShadows y la 3 el cambio del fondo de la lista
                    const Divider(thickness: 0.9, height: 0.5),
    
                    Selector<ChatProvider, bool>(
                    selector: (_, p1) => p1.isFocus,
                    builder: (context, isFocus, child) {
                      return AnimatedContainer(
                        color: Colors.white,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.linear,
                        child: Stack(
                          alignment: Alignment.centerRight,
                          children: const [
                            _ChatTextField(),
                            _ChatActions(),
                          ],
                        ),
                        padding: isFocus ? EdgeInsets.only(bottom: bottomInset) : const EdgeInsets.only(bottom: 0),
                      );
                    },
                  ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//-Mas manejable para transiciones en vez de un appbar
class _Header extends StatelessWidget {
  final User user;

  const _Header({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mq = MediaQuery.of(context);

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => {},
        child: Container(
          padding: EdgeInsets.only(top: mq.padding.top),
          height: kToolbarHeight + mq.padding.top,
          child: Row(
            children: [
              IconButton(onPressed: () => Navigator.of(context).maybePop(), icon: const Icon(Icons.arrow_back)),
              const SizedBox(width: 5.0),
              CircleAvatar(
                child: Text(user.name.substring(0,2)),
                backgroundColor: Colors.blue[100],
              ),
              const SizedBox(width: 10.0),
              Expanded(child: Text(user.name)),
              IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatTextField extends StatelessWidget {
  const _ChatTextField({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final input = Provider.of<ChatProvider>(context, listen: false);
    final record = Provider.of<AudioProvider>(context);

    final recordTime = record.recordTime;

    return SizedBox(
      child: TextField(
        maxLines: 4,
        minLines: 1,
        autocorrect: false,
        textCapitalization: TextCapitalization.sentences,
        controller: input.textController,
        focusNode: input.focusNode,
        onChanged: (value) => input.message.text = value, //-Solo para actualizar el valor del textController
        decoration:  InputDecoration(
          border: InputBorder.none,
          filled: true,
          fillColor: Colors.white, //-Tapa el color del splash (se arregla con el material)
          suffixIcon: const SizedBox(width: 24),
          hintText: recordTime.isEmpty ? 'Message' : '',
          prefixIcon: recordTime.isEmpty ? null : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 10.0),
              const Icon(Icons.circle, color: Colors.redAccent),
              const SizedBox(width: 8.0),
              Text(recordTime)
            ],
          )
        )
      ),
    );
  }
}

class _ChatActions extends StatelessWidget {
  const _ChatActions({Key? key}) : super(key: key);
  
  Future<void> _sendMessage(BuildContext context) async{
    final chat = Provider.of<ChatServices>(context, listen: false);
    final input = Provider.of<ChatProvider>(context, listen: false);
    final socket = Provider.of<SocketServices>(context, listen: false).socket;
    final file = Provider.of<FileServices>(context, listen: false);

    input.message.time = DateFormat("hh:mm a").format(DateTime.now());

    socket.emitWithAck('message-id', input.message, ack: (id) async {
      input.message.id = id;

      chat.addMessage(input.message.copyWith());
      if(input.listKey.currentState != null){
        input.listKey.currentState!.insertItem(0);
      }

      if(input.message.image != null || input.message.audio != null){
        final tempUrl = await file.uploadFile(input.message.image ?? input.message.audio!);
        input.message.tempUrl = tempUrl;
      }

      socket.emit('chat-message', input.message);

      input.textController.clear();
      input.clearMessage();
    });
  }

  @override
  Widget build(BuildContext context) {
    final input = Provider.of<ChatProvider>(context);

    return AnimatedSwitcher(
      duration: kThemeAnimationDuration,
      child: !input.showSend
      ? _MediaActions(sendFile: () => _sendMessage(context))
      : Material(
        type: MaterialType.transparency,
        child: IconButton(
          key: const ValueKey('send'),
          splashRadius: 24,
          splashColor: Colors.blue.shade100,
          onPressed: () => _sendMessage(context),
          icon: const Icon(Icons.send, color: Colors.blue),
        ),
      ),
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: animation, 
        child: child
      ),
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.centerRight,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
    );
  }
}

class _MediaActions extends StatefulWidget {
  final VoidCallback sendFile;

  const _MediaActions({Key? key, required this.sendFile}) : super(key: key);

  @override
  State<_MediaActions> createState() => __MediaActionsState();
}

class __MediaActionsState extends State<_MediaActions> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final _appFolder = Environment().appFolder;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150)
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final input = Provider.of<ChatProvider>(context, listen: false);

    return Selector<AudioProvider, bool>(
      selector: (p0, p1) => p1.isRecording,
      builder: (context, isRecording, child) {
        final record = Provider.of<AudioProvider>(context, listen: false);

        return  AnimatedBuilder(
          animation: _controller, 
          builder: (context, child) {
            final dx = lerpDouble(0.0, kMinInteractiveDimension, _controller.value)!;
            final scale = lerpDouble(1.0, 0.5, _controller.value)!;
      
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: scale,
                  child: Transform.translate(
                    offset: Offset(dx, 0.0),
                    child: IconButton(
                      splashRadius: 24,
                      onPressed: () async {
                        final hasPermissions = await Permissions.checkStoragePermissions();
                        
                        if(hasPermissions){
                          final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
                          
                          if(image != null){
                            final ext = image.name.split('.').last;
                            final fileName = Helpers.generateFileName('IMG', ext);
      
                            await image.saveTo('${_appFolder.sent.path}/$fileName');
                            input.message.image = fileName;
      
                            widget.sendFile();
                          }
                        } else {
                          Notifications.showSnackBar('You must accept permissions');
                        }
                      }, 
                      icon: const Icon(Icons.attach_file, color: Colors.grey,)
                    ),
                  ),
                ),
                GestureDetector(
                  onLongPressDown: (details) async {
                    final firstTime = await Permission.microphone.isGranted;
                    final hasPermissions = await Permissions.checkAudioPermissions();

                    if(hasPermissions && firstTime){
                      final fileName = Helpers.generateFileName('WAV', 'wav');
                      input.message.audio = fileName;
      
                      await record.record('${_appFolder.sent.path}/$fileName');
                      _controller.forward();
                    } else if(!hasPermissions) {
                      Notifications.showSnackBar('You must accept permissions');
                    }
                  },
                  onLongPressUp: () async {
                    if(isRecording){
                      await record.stop();
                      _controller.reverse();
      
                      widget.sendFile();
                    }
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        painter: _RecordBackgroundPainter(animation: _controller),
                      ),
                      SizedBox.square(
                        dimension: kMinInteractiveDimension,
                        child: Icon(Icons.mic_none, color: isRecording ? Colors.white : Colors.grey)
                      )
                    ],
                  )
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _RecordBackgroundPainter extends CustomPainter {
  final Animation<double> animation;

  _RecordBackgroundPainter({required this.animation}) : super(repaint: animation);

  static const _maxRadius = 50;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
    ..color = Colors.blue.shade200;

    final radius = lerpDouble(0.0, _maxRadius, animation.value)!;

    canvas.drawCircle(const Offset(0.0, 0.0), radius, paint);
  }

  @override
  bool shouldRepaint(_RecordBackgroundPainter oldDelegate) => true;
}