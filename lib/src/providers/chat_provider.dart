import 'package:flutter/material.dart';

import '../models/models.dart';

class ChatProvider extends ChangeNotifier {
  final textController = TextEditingController();
  final focusNode = FocusNode();
  final listKey = GlobalKey<AnimatedListState>();

  bool _isFocus = false;
  bool get isFocus => _isFocus;
  set isFocus(bool isFocus) {
    _isFocus = isFocus;
    notifyListeners();
  }

  bool _showSend = false;
  bool get showSend => _showSend;
  set showSend(bool showSend) {
    _showSend = showSend;
    notifyListeners();
  }

  late final Message message;

  ChatProvider(String from, String to){
    message = Message(from: from, to: to);

    focusNode.addListener(() {
      if(focusNode.hasFocus){
        isFocus = true;
      } else {
        _isFocus = false;
      }
    });

    textController.addListener(() {
      if(textController.text.isEmpty){
        showSend = false;
      }

      if(textController.text.length == 1){
        showSend = true;
      }
    });
  }

  void clearMessage(){
    message.text = null;
    message.image = null;
    message.tempUrl = null;
    message.audio = null;
  }
}