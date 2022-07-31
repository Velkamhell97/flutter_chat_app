import 'package:chat_app/src/widgets/overlay_builder.dart';
import 'package:flutter/cupertino.dart';

class ChatMessageProvider extends ChangeNotifier {
  bool showSend = true;

  /// Puede cambiar su estado desde el widget, no notificamos con cada cambio, porque solo lo necesitamos
  /// cuando vamos a hacer el willScopePop
  bool showEmojis = false;

  void notify(){
    notifyListeners();
  }

  /// Solo lo puede cambiar externamente desde el boton, decide se abre o cierra el overlay
  bool _showOverlay = false;
  bool get showOverlay => _showOverlay;
  set showOverlay(bool showOverlay) {
    _showOverlay = showOverlay;
    notifyListeners();
  }

  OverlayType _overlayType = OverlayType.animated;
  OverlayType get overlayType => _overlayType;
  set overlayType(OverlayType overlayType) {
    _overlayType = overlayType;
    notifyListeners();
  }

  TextEditingController _controller = TextEditingController();

  TextEditingController get controller => _controller;

  set controller(TextEditingController controller) {
    _controller.dispose();
    _controller = controller;

    _controller.addListener(() {
      if(_controller.text.isEmpty){
        showSend = true;
        notifyListeners();
      }

      if(_controller.text.length == 1){
        showSend = false;
        notifyListeners();
      }
    });
  }

  Map<String, dynamic> message = {};

  void clearMessage([String? to]) {
    message = {'from': message["from"], 'to': to ?? message["to"] };
    _controller.clear();
  }
}