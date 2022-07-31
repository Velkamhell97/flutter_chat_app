import 'package:chat_app/src/widgets/custom_dialog.dart';
import 'package:flutter/material.dart';

import '../models/app_dialog.dart';

class DialogsService {
  /// No muy utilizada, siempre se utiliza el ScaffoldMessenger
  final messengerKey = GlobalKey<ScaffoldMessengerState>();
  bool _visibleSnackbar = false;

  /// Si no fuera por el context del overlay no se necesitaria ya que solo se utilizaria en el main
  final navigatorKey = GlobalKey<NavigatorState>();

  /// Para asignar un routeObserver al MateApp, sirve para escuchar cuando un widget va a hacer un pop o push
  /// pensado para quitar el overlay antes de salir de una pantalla, pero esto impide que se pueda cerrar
  /// el overlay en vez de navegar (como un WillPopScope)
  // final routeObserver = RouteObserver<PageRoute>();

  /// Se manejara una instancia global del overlayEntry, porque muchas veces se desea cerrar desde 
  /// widgets superiores o antes de hacer pop
  OverlayEntry? _entry;

  /// Funcion que se ejecutara antes de cerrar el overlay
  Future<void>? Function()? entryCallback;

  bool get hasOverlay => _entry != null;

  /// Forma de crear un dialogo estadar para la app, no es muy comun ver funciones que dependen del 
  /// context dentro de un service
  Future<bool> showAppDialog({required AppDialog dialog, RouteTransitionsBuilder? transitionBuilder}) async {
    final child = CustomDialog(dialog: dialog);

    return await showGeneralDialog<bool>(
      context: navigatorKey.currentState!.context, 
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionBuilder: transitionBuilder
    ) ?? false;
  }

  /// Se podria utilizar el ScaffoldMessenger en donde se desea
  Future<void> showSnackBar(String message) async{
    if(_visibleSnackbar) {
      messengerKey.currentState!.removeCurrentSnackBar();
    }

    _visibleSnackbar = true;

    messengerKey.currentState!.showSnackBar(
      SnackBar(content: Text(message))
    ).closed.then((_) => _visibleSnackbar = false);
  }

  /// Mostramos el overlay
  void showOverlay(OverlayEntry entry) {
    _entry = entry;
    navigatorKey.currentState!.overlay!.insert(entry);
  }

  /// Redibujamos el overlay
  void rebuildOverlay([bool skipCallback = false]) async {
    _entry?.markNeedsBuild();
  }

  /// Removemos el overlya y si hay un callback esperamos
  void removeOverlay([bool skipCallback = false]) async {
    if(entryCallback != null && !skipCallback){
      await entryCallback!();
    }

    if(_entry != null){
      _entry!.remove();
      _entry = null;
      entryCallback = null;
    }
  }
}