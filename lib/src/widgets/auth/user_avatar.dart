import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';

import '../../extensions/extensions.dart';

class UserAvatar extends StatefulWidget {
  final String? url;
  final String? text;
  final double radius;
  final void Function(String?)? onAvatarChanged;
  final void Function(Object)? onImageError;

  const UserAvatar({
    Key? key, 
    this.url, 
    this.text, 
    this.radius = 30.0,
    this.onAvatarChanged,
    this.onImageError,
  }) : super(key: key);

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  /// Se podria haber hecho con el setState y una variable del mismo tipo, pero aun asi el value notifier
  /// ayuda bastante con widgets que tienen que mantener su estado propio, poder modificarlo y ademas
  /// pasar el cambiio de estado por fuera del widget
  late final ValueNotifier<String?> _avatarNotifier;
  
  // OverlayEntry? _entry;

  // Offset? _tapPosition;

  @override
  void initState() {
    super.initState();
    _avatarNotifier = ValueNotifier<String?>(widget.url);
  }

  // void _removeOverlay() {
  //   if(_entry != null){
  //     _entry!.remove();
  //     _entry = null;
  //   }
  // }

  Future<void> _pickImage() async {
    /// Se puede setear un popup o dialog para establecer de donde sacar la imagen
    final _picker = ImagePicker(); 

    final image = await _picker.pickImage(source: ImageSource.gallery);

    if(image != null){
      _avatarNotifier.value = image.path;
      widget.onAvatarChanged!(_avatarNotifier.value);
    }
  }

  /// Intento de simular el showMenu pero con un Overlay, se utiliza una animacion muy similar a la del
  /// showMenu, pero todo controlado desde Overlay
  // Future<void> _showOverlay(BuildContext context) async {
  //   if(_entry != null) return;
  //
  //   final box = context.findRenderObject() as RenderBox;
  //   final offset = box. localToGlobal(Offset.zero);
  //
  //   final width = box.size.width;
  //   final height = box.size.height;
  //
  //   bool show = true;
  //
  //   _entry = OverlayEntry(
  //     builder: (_) {
  //       return Stack(
  //         children: [
  //           /// Si se da tap fuera redibuja el overlay, se termina la animacion y apenas acaba si se quita
  //           Positioned.fill(
  //             child: GestureDetector(
  //               onTap: (){
  //                 show = false;
  //                 _entry!.markNeedsBuild();
  //                 // _entry?.remove();
  //               },
  //             )
  //           ),
  //           /// Si se da tap al overlay no se cierra, aqui se podria una logica compleja para posicionar como
  //           /// El SingleRenderObject del showMenu, pero se dejara sencillo
  //           Positioned(
  //             /// Dependiendo de un limite que le pongamos aqui podemos hacer que se abra hacia un lugar u otro
  //             /// por ejemplo si ponemos el left se abrira hacia la derecha si ponemos el right se abrira 
  //             /// hacia la izquierda, se podria crear un widget mas sofisticado que detecte lo ubique en una
  //             /// esquina con un offset para mover y que lo mueva automatico cuando no quepa, pero seria
  //             /// complejo y ademas ya tenemos algo similar con el showMenu.
  //             /// 
  //             /// pordriamos limitar el menu con valores maximos y minimos con el BoxConstrains y si se desea
  //             /// en multiplos con el IntrisecWidth, pero lo complicado es hallar la posicion de salida, por lo que
  //             /// tendriamos que utilizar el SingleChildRenderObject en donde si podemos acceder al size
  //             /// del widget y definir cual sera su posicion de salida u otra opcion es utilizar el onTapDown
  //             /// para capturar el punto global donde se hizo el tap, utilizar este punto para saber si el menu
  //             /// quedara corto o no, pero en este caso si necesitamos tener un width fijo, ya que igualmente
  //             /// no podriamos determinar el ancho de las opciones en el menu (texto) pero para ello podemos
  //             /// usar un fitbox para que no se pasen del limite, existen muchas formas de hacer las cosas en flutter
  //              top: offset.dy,
  //             // left: offset.dx,
  //             right: offset.dx + width,
  //             child: _OverlayWidget(
  //               show: show,
  //               onEnd: () => _removeOverlay(),
  //             ),
  //           )
  //         ],
  //       );
  //     }
  //   );
  //
  //   Overlay.of(context)!.insert(_entry!);
  // }

  Future<void> _showMenu(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox;
    final offset = box. localToGlobal(Offset.zero);
    final screen = MediaQuery.of(context).size;

    /// Para informacion de como funciona este metodo mirar el archivo show_menu_commented, el position es
    /// donde quiere que se ponga el menu, generalmente lo mas importante es el top-left
    await showMenu<int>(
      context: context, 
      /// Al parecer no se puede controlar del todo la posicion en Y, y en X si se setea un 0 en un extremo 
      /// aparecera en ese lugar y si no le alcanza el espacio en un extremo se mostrara en el otro
      // position: RelativeRect.fromLTRB(offset.dx, offset.dy, screen.width - offset.dx, screen.height - offset.dy), 
      position: RelativeRect.fromLTRB(
        offset.dx + box.size.width, 
        offset.dy + box.size.height / 3, 
        screen.width - offset.dx, 
        screen.height - offset.dy
      ), 
      items: [
        PopupMenuItem<int>(
          // value: 0, no tan util si tambien da la opcion del onTap
          onTap: () {
            _avatarNotifier.value = null;

            if(widget.onAvatarChanged != null){
              widget.onAvatarChanged!(_avatarNotifier.value);
            }
          } ,
          child: const Text('Delete Avatar'),
        ),
      ]
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: widget.onAvatarChanged == null ? null : () => _pickImage(),
      onLongPress: () => _showMenu(context),
      // onLongPress: () => _showOverlay(context),
      // onTapDown: (details) => _tapPosition = details.globalPosition,
      child: ClipOval(
        child: SizedBox.square(
          dimension: widget.radius * 2,
          child: ValueListenableBuilder<String?>(
            valueListenable: _avatarNotifier,
            builder: (context, avatar, _) {
              if(avatar == null){
                final color = widget.text == null ? Colors.grey : widget.text!.getRandomColor();
                final letters = widget.text == null ? 'NN' : widget.text!.initials();
      
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                  ),
                  child: FittedBox(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(letters, style: const TextStyle(color: Colors.white))
                    )
                  ),
                );
              }
      
              if(avatar.contains('http')) {
                return CachedNetworkImage(
                  imageUrl: avatar,
                  fit: BoxFit.cover,
                  errorWidget: (context, error, __) {
                    if(widget.onImageError != null) {
                      widget.onImageError!(error);
                      /// Si hay un error deja la imagen por defecto
                      _avatarNotifier.value = null;
                    }
    
                    return const SizedBox.shrink();
                  },
                );
              }
      
              /// Cuando se cambia la imagen antes de subir es una File Image
              return Image.file(
                File(avatar),
                fit: BoxFit.cover,
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Overlay que da el efecto de un diagonal size transition
class _OverlayWidget extends StatefulWidget {
  final bool show;
  final VoidCallback? onEnd;

  const _OverlayWidget({
    Key? key, 
    // ignore: unused_element
    this.show = true, 
    // ignore: unused_element
    this.onEnd
  }) : super(key: key);

  @override
  State<_OverlayWidget> createState() => __OverlayWidgetState();
}

class __OverlayWidgetState extends State<_OverlayWidget> with SingleTickerProviderStateMixin{
  late AnimationController _controller;

  late final Animation<double> _widthFactorAnimation;
  late final Animation<double> _heightFactorAnimation;

  late final Animation<double> _menuOpacityAnimation;
  late final Animation<double> _childOpacityAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000)
    );

    _widthFactorAnimation = CurvedAnimation(
      parent: _controller, 
      curve: const Interval(0.0, 0.15)
    );

    /// Se puede decicir si el height crece mas lento por ejemplo si hay mas elementos
    _heightFactorAnimation = CurvedAnimation(
      parent: _controller, 
      curve: const Interval(0.0, 0.15)
    );

    /// Opacidad del menu, no de los elementos
    _menuOpacityAnimation = CurvedAnimation(
      parent: _controller, 
      curve: const Interval(0.0, 0.30)
    );

    /// Si fuera una lista de childs se tendria que hacer una lista de intervalos para mejores ejemplos
    /// mirar el show_menu_commented, tambien es otra opcion crear una lista de FadeTransition con su
    /// curvedAnimation correspondiente, ne sabe si esto es mas optimo que el opacity y evaluar cada intervalo
    /// tambien se deberia hacer una lista de widgets ya que estos son el child del animated builder
    _childOpacityAnimation = CurvedAnimation(
      parent: _controller, 
      curve: const Interval(0.15, 0.25)
    );

    _controller.forward();
  }

  /// Una alternativa al FutureMicrotask, aqui podemos escuchar cuando el widget se redibuja pero cambia
  /// algun valor de sus parametros, y hacer alguna accion al respecto, en este caso hacer reverse, no
  /// puede ser una funcion asyncrona
  @override
  void didUpdateWidget(covariant _OverlayWidget oldWidget) {
    if(!widget.show){
      _controller.reverse().then((_) => widget.onEnd!());
    }
    
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return FadeTransition(
          opacity: _menuOpacityAnimation,
          child: Material(
            type: MaterialType.card,
            elevation: 8.0,
            /// Forma de lograr el efecto de un diagonal size transition
            child: Align(
              alignment: AlignmentDirectional.topEnd,
              widthFactor: _widthFactorAnimation.value,
              heightFactor: _heightFactorAnimation.value,
              child: FadeTransition(
                opacity: _childOpacityAnimation,
                child: Container(
                  width: 150,
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
                  child: const Text('Some'),
                ),
              ),
            ),
          ),
        );
      },
    );

    /// Un efecto de resize diagonal tambien se puede completar con el doble sizeTransition
    /// este evita la necesidad de ocultar el desplazamiento del align, pero tambien se trabaja con opacity
    /// en los elemento para que no se vea como se escalan (opcional)
    // return SizeTransition(
    //   sizeFactor: _controller,
    //   axisAlignment: -1.0,
    //   axis: Axis.horizontal,
    //   child: Container(
    //     width: 150,
    //     height: 50,
    //     color: Colors.red.withOpacity(0.5),
    //   ),
    // );
  }
}