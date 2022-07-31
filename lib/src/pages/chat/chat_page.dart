import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../widgets/chat/chat.dart';

class ChatPage extends StatefulWidget {
  final User receiver;

  const ChatPage({Key? key, required this.receiver}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final AuthService auth;
  late final MessagesService messages;
  late final SocketsService socket;
  late final ChatMessageProvider chat;

  @override
  void initState() {
    super.initState();

    auth = Provider.of<AuthService>(context, listen: false);
    messages = Provider.of<MessagesService>(context, listen: false);
    socket = Provider.of<SocketsService>(context, listen: false);
    chat = Provider.of<ChatMessageProvider>(context, listen: false);
    final users = Provider.of<UsersService>(context, listen: false);

    chat.message["to"] = widget.receiver.uid;

    messages.getMessages(auth.user!.uid, widget.receiver.uid).then((_) {
      if(messages.messages.isNotEmpty){
        final data = {"from": widget.receiver.uid, "to": auth.user!.uid};
        
        socket.emitWithAck('messages-read', data, ack: (_) {
          auth.user!.unreads[widget.receiver.uid] = 0;
          users.refresh();
        });
      }
    });

    socket.on('message-received', (_) {
      messages.onMessageReceived();
    });

    socket.on('message-read', (_) {
      messages.onMessageRead();
    });

    socket.on('messages-read', (count) {
      messages.onMessagesRead(count);
    });
  } 

  @override
  void dispose() {
    socket.off('message-received');
    socket.off('message-read');
    socket.off('messages-read');
    super.dispose();
  }

  static const _messagePadding = 10.0;

  int lastOut = 0;
  int lastIn = 0;

  @override
  Widget build(BuildContext context) {
    return  WillPopScope(
      onWillPop: () async {
        final chat = context.read<ChatMessageProvider>();

        if(chat.showEmojis) {
          chat.showEmojis = false;
          chat.notify();
          return false;
        } else if(chat.showOverlay) {
          chat.showOverlay = false;
          return false;
        } else {
          chat.message.remove("to");
          return true;
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          // fit: StackFit.expand,
          children: [
            ///---------------------------------
            /// BACKGROUND
            ///---------------------------------
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/telegram-background.png'),
                    fit: BoxFit.cover
                  )
                ),
              ),
            ),
        
            ///---------------------------------
            /// BODY
            ///---------------------------------
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ///---------------------------------
                /// HEADER
                ///---------------------------------
                ChatHeader(user: widget.receiver),
                    
                ///---------------------------------
                /// MESSAGES
                ///---------------------------------
                Expanded(
                  child: StreamBuilder<List<Message>>(
                    initialData: null,
                    stream: messages.messagesStream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xff4c84b6),
                          )
                        );
                      }
        
                      if (snapshot.hasError) {
                        final error = snapshot.error as ErrorResponse;
                        return Text('Error while loading the messages: ${error.message}');
                      }

                      return ChangeNotifierProvider(
                        lazy: false,
                        create: (_) => AudioProvider(),
                        child: CustomScrollView(
                          physics: const BouncingScrollPhysics(),
                          reverse: true,
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
                              sliver: SliverAnimatedList(
                                findChildIndexCallback: (key) {
                                  final ValueKey<String> valueKey = key as ValueKey<String>;
                                  final index = messages.messages.indexWhere((m) => m.id == valueKey.value);
                                  return index;
                                },
                                key: messages.listKey,
                                initialItemCount: snapshot.data!.length,
                                itemBuilder: (_, index, animation) {
                                  final message = snapshot.data![index];

                                  if(message.sender){
                                    lastOut = index;
                                  } else {
                                    lastIn = index;
                                  }
        
                                  return Padding(
                                    key: ValueKey(message.id),
                                    padding: const EdgeInsets.only(bottom: _messagePadding),
                                    child: SizeTransition(
                                      sizeFactor: CurvedAnimation(parent: animation, curve: Curves.easeOut),
                                      axisAlignment: -1.0,
                                      child: ChatMessage(
                                        message: message,
                                        lastOut: index == 0,
                                        lastIn: index == 0,
                                      ),
                                    ),
                                  );
                                }
                              ),
                            )
                          ],
                        )
                      );
                    },
                  )
                ),
                    
                /// Opcion 1, la opcion 2 es el boxShadows y la 3 el cambio del fondo de la lista
                const Divider(thickness: 0.9, height: 0.5),
                    
                ///---------------------------------
                /// CHAT TEXTFIELD
                ///---------------------------------
                const ChatTextField()
              ],
            ),
          ],
        ),
      ),
    );
  }
}