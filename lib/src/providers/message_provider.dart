import 'package:flutter/cupertino.dart';

import '../widgets/overlay_builder.dart';

class MessageProvider extends ChangeNotifier {
  bool showSend = true;

  /// Puede cambiar su estado desde el widget, no notificamos con cada cambio, porque solo lo necesitamos
  /// cuando vamos a hacer el willScopePop
  bool showEmojis = false;

  /// Para notificat sin crear un setter
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

  /// Cambia la animacion cuando se va a navegar
  OverlayType _overlayType = OverlayType.animated;
  OverlayType get overlayType => _overlayType;
  set overlayType(OverlayType overlayType) {
    _overlayType = overlayType;
    notifyListeners();
  }

  /// Siempre que se acceda a la pantalla de chat se crea un nuevo TextController, porque una vez se utiliza
  /// uno ya queda deshabilitado
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