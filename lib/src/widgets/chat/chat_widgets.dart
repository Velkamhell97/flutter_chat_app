import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../providers/message_provider.dart';
import '../auth/user_avatar.dart';
import 'emoji_keyboard.dart';

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
                ///-----------------------------------
                /// BACK ARROW
                ///-----------------------------------
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(), 
                  icon: const Icon(Icons.arrow_back),
                  splashRadius: 25,
                  color: Colors.white,
                ),
                  
                ///-----------------------------------
                /// SPACING
                ///-----------------------------------
                const SizedBox(width: 5.0),
      
                ///-----------------------------------
                /// AVATAR
                ///-----------------------------------
                UserAvatar(
                  url: user?.avatar,
                  text: user?.name ?? 'any',
                  radius: 20,
                ),
                  
                ///-----------------------------------
                /// SPACING
                ///-----------------------------------
                const SizedBox(width: 10.0),
                  
                ///-----------------------------------
                /// NAME
                ///-----------------------------------
                Expanded(child: Text(user?.name ?? 'any', style: _titleStyle)),
                  
                ///-----------------------------------
                /// OPTIONS
                ///-----------------------------------
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
            ///-----------------------------------
            /// BACK BUTTON
            ///-----------------------------------
            BackButton(
              onPressed: () => Navigator.of(context).pop(),
              color: Colors.white,
            ),

            ///-----------------------------------
            /// SPACING
            ///-----------------------------------
            const SizedBox(width: 10.0),

            ///-----------------------------------
            /// TITLE
            ///-----------------------------------
            Text(title, style: _style),

            ///-----------------------------------
            /// SPACING
            ///-----------------------------------
            const Spacer(),

            ///-----------------------------------
            /// CROP OPTION
            ///-----------------------------------
            if(onCrop != null)
              IconButton(
                color: Colors.white,
                onPressed: onCrop, 
                icon: const Icon(Icons.crop)
              ),

            ///-----------------------------------
            /// EMOJI OPTION
            ///-----------------------------------
            if(onEmoji != null)
              IconButton(
                color: Colors.white,
                onPressed: onEmoji, 
                icon: const Icon(Icons.emoji_emotions_outlined)
              ),

            ///-----------------------------------
            /// PAINT OPTION
            ///-----------------------------------
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
        context.read<MessageProvider>().message["text"] = text;
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