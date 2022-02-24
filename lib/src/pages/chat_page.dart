import 'package:chat_app/models/message.dart';
import 'package:chat_app/widgets/chat_message.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<Message> _messages = [
    // Message(uid: '1', text: 'Hola Mundo mi nombre es luis daniel valencia y soy estilo rcn si me entiende'),
    // Message(uid: '2', text: 'Respuesta Mundo'),
    // Message(uid: '1', text: 'Hola Mundo'),
    // Message(uid: '2', text: 'Respuesta Mundo'),
    // Message(uid: '1', text: 'Hola Mundo'),
    // Message(uid: '2', text: 'Respuesta Mundo'),
    // Message(uid: '1', text: 'Hola Mundo'),
    // Message(uid: '2', text: 'Respuesta Mundo'),
    // Message(uid: '1', text: 'Hola Mundo'),
    // Message(uid: '2', text: 'Respuesta Mundo'),
    // Message(uid: '1', text: 'Hola Mundo'),
    // Message(uid: '2', text: 'Respuesta Mundo'),
  ];

  static const _messagePadding = 10.0;

  final _listKey = GlobalKey<AnimatedListState>();

  void _addMessage(String text) {
    _messages.insert(0, Message(uid: '1', text: text));
    _listKey.currentState!.insertItem(0);
  }

  final _inputFocus = FocusNode();
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _inputFocus.addListener(() {
      //-Al parecer abrir y cerrar el teclado de por si causa dos rebuild
      setState(() => _hasFocus = _inputFocus.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mq = MediaQuery.of(context);
    final bottomInset = mq.viewInsets.bottom + mq.padding.bottom;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xffF2F2F2),
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              //---------------------------------
              // Header
              //---------------------------------
              const _Header(),

              //---------------------------------
              // Messages
              //---------------------------------
              Flexible(
                child: AnimatedList(
                  key: _listKey,
                  initialItemCount: _messages.length,
                  padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 0.0),
                  physics: const BouncingScrollPhysics(),
                  // itemExtent: 40 + _messagePadding, //-No se puede poner fijo porque puede variar el height
                  reverse: true, //-Empezamos en el ultimo elemento y scroleamos hacia arriba
                  itemBuilder: (_, index, animation) {
                    return SizeTransition(
                      sizeFactor: CurvedAnimation(parent: animation, curve: Curves.easeOut),
                      axisAlignment: -1.0,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: _messagePadding),
                        child: ChatMessage(message: _messages[index]),
                      ),
                    );
                  },
                ),
              ),

              //Opcion 1, la opcion 2 es el boxShadows y la 3 el cambio del fondo de la lista
              const Divider(thickness: 0.9, height: 0.5),

              //---------------------------------
              // TextField
              //---------------------------------
              _ChatTextField(onSubmit: _addMessage, inputFocus: _inputFocus),
              AnimatedContainer(
                duration: const Duration(milliseconds: 20),
                curve: Curves.easeOutQuad,
                //-Por alguna razon funciona solo sin la necesidad de la condicion del _inputFocus
                padding: EdgeInsets.only(bottom: bottomInset),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1.0, //-Cuando la elevacion es tan bajita un divider daria un efecto muy similar
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Column(
          children: [
            CircleAvatar(
              child: const Text('U'),
              backgroundColor: Colors.blue.shade100,
            ),
            const SizedBox(height: 5),
            const Text('User 1', textAlign: TextAlign.center)
          ],
        ),
      ),
    );
  }
}

class _ChatTextField extends StatefulWidget {
  final ValueChanged<String> onSubmit;
  final FocusNode inputFocus;

  const _ChatTextField({Key? key, required this.onSubmit, required this.inputFocus}) : super(key: key);

  @override
  State<_ChatTextField> createState() => __ChatTextFieldState();
}

class __ChatTextFieldState extends State<_ChatTextField> {
  final _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: TextField(
        maxLines: 4,
        minLines: 1,
        autocorrect: false,
        textCapitalization: TextCapitalization.sentences,
        controller: _textController,
        focusNode: widget.inputFocus,
        onChanged: (_) => setState(() {}), //-Solo para actualizar el valor del textController
        onSubmitted: widget.onSubmit,
        decoration: InputDecoration(
          border: InputBorder.none,
          filled: true,
          // fillColor: Colors.white, //-Tapa el color del splash
          suffixIcon: AnimatedSwitcher(
            duration: kThemeAnimationDuration,
            child: _textController.text.isEmpty
            ? const SizedBox()
            : IconButton(
              splashRadius: 24,
              splashColor: Colors.blue.shade100,
              onPressed: () {
                widget.onSubmit(_textController.text);
                _textController.clear();
                setState(() {}); //-Para el AnimatedSwitch
              },
              icon: const Icon(Icons.send),
            ),
            transitionBuilder: (child, animation) {
              return ScaleTransition(
                scale: animation,
                child: child,
              );
            },
          ),
          hintText: 'Message'
        )
      ),
    );
  }
}
