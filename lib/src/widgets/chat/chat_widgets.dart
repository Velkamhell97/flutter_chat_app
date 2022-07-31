import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/providers.dart';
import '../auth/auth.dart';
import 'chat.dart';


///---------------------------------------------
/// CHAT PAGE
///---------------------------------------------
class ChatHeader extends StatelessWidget {
  final User? user; //-por aguna razon un error al volver

  const ChatHeader({Key? key, required this.user}) : super(key: key);

  static const _titleStyle = TextStyle(color: Colors.white, fontSize: 18);

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mq = MediaQuery.of(context);

    return Material(
      color: const Color(0xff4c84b6),
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: EdgeInsets.only(top: mq.padding.top),
          child: SizedBox(
            height: kToolbarHeight,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(), 
                  icon: const Icon(Icons.arrow_back),
                  splashRadius: 25,
                  color: Colors.white,
                ),
                  
                const SizedBox(width: 5.0),
      
                UserAvatar(
                  url: user?.avatar,
                  text: user?.name ?? 'any',
                  radius: 20,
                ),
                  
                const SizedBox(width: 10.0),
                  
                Expanded(child: Text(user?.name ?? 'any', style: _titleStyle)),
                  
                IconButton(
                  onPressed: () {}, 
                  icon: const Icon(Icons.more_vert),
                  splashRadius: 25,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

///---------------------------------------------
/// MESSAGE TYPES
///---------------------------------------------
class AudioNotFound extends StatelessWidget {
  const AudioNotFound({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(Icons.error_outline, color: Colors.redAccent),
        SizedBox(width: 10),
        Text('Audio not found')
      ],
    );
  }
}

///---------------------------------------------
/// EDITION PAGE
///---------------------------------------------
class MediaEditionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onCrop;
  final VoidCallback? onPaint;
  final VoidCallback? onEmoji;

  const MediaEditionHeader({
    Key? key, 
    required this.title,
    this.onCrop,
    this.onPaint,
    this.onEmoji,
  }) : super(key: key);

  static const _lr = 12.0;
  // static const _tb = 10.0;

  static const _style = TextStyle(
    fontSize: 16,
    color: Colors.white
  );

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mq = MediaQuery.of(context);

    final top = mq.padding.top;

    return Material(
      color: Colors.black38,
      child: Padding(
        padding: EdgeInsets.fromLTRB(_lr, top, _lr, 0.0),
        child: Row(
          children: [
            BackButton(
              onPressed: () => Navigator.of(context).pop(),
              color: Colors.white,
            ),

            const SizedBox(width: 10.0),

            Text(title, style: _style),

            const Spacer(),

            if(onCrop != null)
              IconButton(
                color: Colors.white,
                onPressed: onCrop, 
                icon: const Icon(Icons.crop)
              ),

            if(onEmoji != null)
              IconButton(
                color: Colors.white,
                onPressed: onEmoji, 
                icon: const Icon(Icons.emoji_emotions_outlined)
              ),

            if(onPaint != null)
              IconButton(
                color: Colors.white,
                onPressed: onPaint, 
                icon: const Icon(Icons.brush)
              )
          ],
        ),
      ),
    );
  }
}

class MediaEditionFooter extends StatelessWidget {
  final VoidCallback onSend;
  final String hintText;

  const MediaEditionFooter({
    Key? key, 
    required this.onSend,
    required this.hintText
  }) : super(key: key);

  static const _hintStyle = TextStyle(
    fontSize: 14,
    color: Colors.white
  );

  @override
  Widget build(BuildContext context) {
    // final MediaQueryData mq = MediaQuery.of(context);
    // final bottom = mq.viewInsets.bottom + mq.padding.bottom;

    // return TextField(
    //   decoration: InputDecoration(
    //     hintText: 'hola',
    //     filled: true,
    //     fillColor: Colors.white30
    //   ),
    // );

    return EmojiKeyboard(
      style: _hintStyle,
      cursorColor: Colors.white,
      inputDecoration: InputDecoration(
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 25.0),
        hintStyle: _hintStyle,
        hintText: hintText,
        fillColor: Colors.black38,
        filled: true,
      ),
      iconColor: Colors.white,
      backgroundColor: Colors.black38,
      onChanged: (text) {
        context.read<ChatMessageProvider>().message["text"] = text;
      },
      child: Align(
        alignment: const Alignment(0.9, 0.0),
        child: Material(
          clipBehavior: Clip.antiAlias,
          shape: const CircleBorder(),
          color: Colors.blue,
          child: IconButton(
            color: Colors.white,
            onPressed: onSend,
            icon: const Icon(Icons.send),
          ),
        ),
      ),
    );
  }
}