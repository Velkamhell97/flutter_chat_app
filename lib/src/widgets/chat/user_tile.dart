import 'package:flutter/cupertino.dart' show CupertinoPageRoute;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../providers/message_provider.dart';
import '../../pages/chat/chat_page.dart';
import '../auth/user_avatar.dart';

class UserTile extends StatelessWidget {
  final User user;
  final int unreads;
  final String last;

  const UserTile({
    Key? key, 
    required this.user,
    required this.unreads,
    required this.last
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = user.online ? Colors.green.shade300 : Colors.red.shade300;
    final style = unreads == 0 ? null : const TextStyle(color: Colors.black, fontWeight: FontWeight.w600);

    return Stack(
      children: [
        ///-----------------------------------
        /// TILE
        ///-----------------------------------
        ListTile(
          leading: UserAvatar(
            url: user.avatar,
            text: user.name,
            radius: 20,
          ),
          trailing: Icon(Icons.circle, color: color, size: 16),
          title: Text(user.name ?? 'Any'),
          subtitle: Text(last, style: style),
          onTap: () {
            context.read<MessageProvider>().clearMessage(user.uid);

            final route = CupertinoPageRoute(
              builder: (_) => ChatPage(receiver: user)
            );

            Navigator.of(context).push(route).then((_) {
              // if(PaintingBinding.instance.imageCache.currentSize > 50 * 1024 * 1024){
              //   PaintingBinding.instance.imageCache.clear();
              //   PaintingBinding.instance.imageCache.clearLiveImages();
              // }
            });
          },
        ),

        ///-----------------------------------
        /// COUNTER BADGE
        ///-----------------------------------
        if(unreads != 0)
          Positioned(
            right: 10,
            top: 0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.shade100
              ),
              padding: const EdgeInsets.all(5.0),
              child: Text(unreads.toString()),
            ),
          )
      ],
    );
  }
}
