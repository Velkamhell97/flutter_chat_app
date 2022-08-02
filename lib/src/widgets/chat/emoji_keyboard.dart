import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter_persistent_keyboard_height/flutter_persistent_keyboard_height.dart';

import '../../singlentons/singlentons.dart';

class EmojiKeyboard extends StatefulWidget {
  final Widget? child;
  final TextEditingController? textController;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final InputDecoration? inputDecoration;
  final TextStyle? style;
  final Color? cursorColor;
  final Color? iconColor;
  final Color? backgroundColor;
  final bool hideKeyboard;
  /// Como este widget maneja su propio estado y no lo controla desde afuera, tenemos que pasar los cambios
  /// para sincronizar con los valores de afuera, especificamente para recibir el hideKeyboard
  final void Function(bool isVisible)? onVisibilityChanged;

  const EmojiKeyboard({
    Key? key,
    this.child,
    this.textController,
    this.focusNode,
    this.onChanged,
    this.inputDecoration,
    this.style,
    this.cursorColor,
    this.iconColor,
    this.backgroundColor,
    this.hideKeyboard = false,
    this.onVisibilityChanged
  }) : super(key: key);

  @override
  State<EmojiKeyboard> createState() => _EmojiKeyboardState();
}

class _EmojiKeyboardState extends State<EmojiKeyboard> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final TextEditingController _textEditingController;
  late final FocusNode _focusNode;

  final _sp = SP();

  static const _platform = MethodChannel('com.example.chat_app/channel');
  static const _duration = Duration(milliseconds: 180);

  bool _keyboardOpen = false;
  bool _emojisOpen = false;

  /// Necesitamos un height inicial, por si la libreria no me arroja nada las primeras veces, este valor incial
  /// lo guardamos en el input donde se almacena el nombre y lo utilizamos aqui
  late double _initialHeight;
  /// Cuando hay cambios en el height del keyboard, se anima el AnimatedContainer y el SizeTransition
  /// al tiempo, por lo que la transicion no se muestra correcta, para evitar esto tomamos el height inicial
  /// y si se presentan cambios en este solo animamos el AnimatedContainer
  late double _keyboardHeight;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: _duration
    );

    _initialHeight = _sp.keyboardHeight;
    _keyboardHeight = _initialHeight;

    _animationController.addStatusListener((status) {
      if(status == AnimationStatus.forward){
        if(widget.onVisibilityChanged != null) {
          widget.onVisibilityChanged!(true);
        }
      } else if(status == AnimationStatus.reverse) {
        _keyboardOpen = false;

        if(widget.onVisibilityChanged != null) {
          widget.onVisibilityChanged!(false);
        }
      }
    });

    _textEditingController = widget.textController ?? TextEditingController();

    _focusNode = widget.focusNode ?? FocusNode();
  }
  
  @override
  void didChangeDependencies() {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    /// Tener en cuenta que esto no se ejecuta en un setState, solo servira para detectar cambios en el teclado
    final visible = bottom != 0.0;

    /// Si esta abierto el keyboard (ontap) y se cierra devuelve la animacion, esto sirve para el caso
    /// que se abre solo o se abre el emoji, ya que primero se oculta antes de actualizarse el _keyboardOpen
    if(_keyboardOpen && !visible){
      /// Se coloca aqui y no en el listener para que empiece a ocultar los emojis primero
      setState(() => _emojisOpen = false);
      _animationController.reverse();
    } else if(visible) {
      /// Solo anima el sizeTransition si no es un cambio en el height del keyboard
      if(_keyboardHeight != bottom) return;
      _animationController.forward();
    }

    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(covariant EmojiKeyboard oldWidget) {
    if(oldWidget.hideKeyboard && widget.hideKeyboard){
      if(widget.hideKeyboard){
        setState(() => _emojisOpen = false);
        _animationController.reverse();
      }
    }

    /// Este metodo tampoco se dispara con el setState
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _animationController.dispose();

    if(widget.textController == null){
      _textEditingController.dispose();
    }

    if(widget.focusNode == null) {
      _focusNode.dispose();
    }

    super.dispose();
  }

  void _onEmojiSelected(Category category, Emoji selected) {
    final emoji = selected.emoji;
    final text = _textEditingController.text;

    final selection = _textEditingController.selection;
    final newText = text.replaceRange(selection.start, selection.end, emoji);
    
    _textEditingController.text = newText;
    
    _textEditingController.selection = selection.copyWith(
      baseOffset: selection.start + emoji.length,
      extentOffset: selection.start + emoji.length
    );

    if(widget.onChanged != null) {
      widget.onChanged!(_textEditingController.text);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    /// Si da un valor de 0 quiere decir que no ha detectado el height y utilizamos el inicial, caso contrario
    /// establecemos el valor que devuelva la libreria ya sea mayor que el initial o menor
    final currentHeight = PersistentKeyboardHeight.of(context).keyboardHeight;
    _keyboardHeight = currentHeight == 0.0 ? _initialHeight : currentHeight;

    return Column(
      children: [
        Stack(
          alignment: Alignment.centerRight,
          children: [
            ///-----------------------------------
            /// CHAT TEXTFIELD
            ///-----------------------------------
            TextField(
              maxLines: 4,
              minLines: 1,
              autocorrect: false,
              textCapitalization: TextCapitalization.sentences,
              controller: _textEditingController,
              // focusNode: _focusNode,
              onChanged: widget.onChanged,
              textAlignVertical: TextAlignVertical.center,
              style: widget.style,
              cursorColor: widget.cursorColor,
              /// Siempre mostrara el teclado, no necesitamos la condicion del _keyboardOpen
              onTap: () {
                _keyboardOpen = true;
              },
              decoration: widget.inputDecoration?.copyWith(
                prefixIcon: IconButton(
                  onPressed: () {
                    if(!_emojisOpen){
                      _animationController.forward();
                    }

                    setState(() => _emojisOpen = true);

                    /// Si el keyboard esta abierto este lo cerrara (solo ocultar)
                    if(_keyboardOpen) {
                      _platform.invokeMethod('hideKeyboard');
                      _keyboardOpen = false;
                    } 
                  },
                  color: widget.iconColor,
                  icon: const Icon(Icons.emoji_emotions_outlined), 
                ),
              )
            ),
            
            ///-----------------------------------
            /// CHAT ACTIONS
            ///-----------------------------------
            Positioned.fill(
              child: widget.child ?? const SizedBox.shrink()
            )
          ],
        ),
    
        ///-----------------------------------
        /// EMOJIS AND KEYBOARD
        ///-----------------------------------
        SizeTransition(
          sizeFactor: _animationController,
          axisAlignment: -1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: _keyboardHeight, 
            curve: Curves.easeInOut,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ///-----------------------------------
                /// EMOJIS LAYOUT
                ///-----------------------------------
                AnimatedOpacity(
                  duration: _duration,
                  opacity: _emojisOpen ? 1.0 : 0.0,
                  child: EmojiPicker(
                    onEmojiSelected: _onEmojiSelected,
                    config: Config(
                      bgColor: widget.backgroundColor ?? Colors.white
                    ),
                  ),
                ),
                
                ///-----------------------------------
                /// HIDE BACKGROUND
                ///-----------------------------------
                IgnorePointer(
                  child: AnimatedOpacity(
                    duration: _duration,
                    opacity: _emojisOpen ? 0.0 : 1.0, 
                    child: Container(
                      foregroundDecoration: BoxDecoration(
                        color: widget.backgroundColor ?? Colors.white,
                      )
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}