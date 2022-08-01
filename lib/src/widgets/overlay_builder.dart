import 'package:flutter/material.dart';

/// Para pasar otro tipo de builder que devuelve un rect para posicionar
// typedef PositionedBuilder = Widget Function(BuildContext context, Rect rect);

typedef AnimatedOverlayBuilder = Widget Function(BuildContext context, Animation<double> animation, Offset offset);

/// Estos enum se definen aqui, porque este es un tipo de widget reutilizable
enum Anchor {
  leftTop(0.0),
  leftCenter(0.5),
  leftBottom(1.0),
  topLeft(0.0),
  topCenter(0.5),
  topRight(1.0),
  rightTop(0.0),
  rightCenter(0.5),
  rightBottom(1.0),
  bottomLeft(0.0),
  bottomCenter(0.5),
  bottomRight(1.0);

  final double value;

  const Anchor(this.value);
}

enum OpenDirection {
  left(1.0),
  top(1.0),
  right(0.0),
  bottom(0.0);

  final double value;

  const OpenDirection(this.value);
}

enum OverlayType {
  normal,
  animated,
} 

class OverlayBuilder extends StatefulWidget {
  final bool showOverlay;
  final OverlayType overlayType;
  final AnimatedOverlayBuilder builder;
  final Widget child;
  final Anchor? anchor;
  final OpenDirection direction;
  final Offset offset;
  final bool barrierDismissible;
  final Color barrierColor;
  final Duration transitionDuration;
  final VoidCallback? onRemove;

  const OverlayBuilder({
    Key? key,
    this.showOverlay = false,
    this.overlayType = OverlayType.normal,
    required this.builder, 
    required this.child,
    this.anchor,
    this.direction = OpenDirection.bottom,
    this.offset = Offset.zero,
    this.barrierDismissible = true,
    this.barrierColor = Colors.black38,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.onRemove
  }) : super(key: key);

  @override
  State<OverlayBuilder> createState() => _OverlayBuilderState();
}

class _OverlayBuilderState extends State<OverlayBuilder> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  
  late final Animation<double> _barrierAnimation;
  
  OverlayEntry? _overlayEntry;

  bool _overlayVisible = false;

  /// Para validar si es left o right, se quita una letra para compararlos con substring
  static const _horizontalAnchors = ['left', 'righ'];

  /// No utilizado con la comparacion de arriba es suficiente
  // static const _vertivalAnchors = ['top', 'bottom'];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.transitionDuration
    );

    _barrierAnimation = Tween(begin: 0.0, end: 0.38).animate(_controller);

    _overlayVisible = widget.showOverlay;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(_overlayVisible){
        _showOverlay();
      }
    });
  }

  @override
  void didUpdateWidget(covariant OverlayBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);

    /// Alternativa al Future.microtask(), este metodo no se ejecuta en el primer build
    WidgetsBinding.instance.addPostFrameCallback((_) => syncOverlay());
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    super.dispose();
  }

  /// Calculamos la posicion del anchor
  Map<String, double> _calcPosition(Offset leftTop, Offset rightBottom, Size size) {
    Map<String, double> align = {};

    final anchor = widget.anchor;

    if(anchor == null) return align;

    if(_horizontalAnchors.contains(anchor.name.substring(0,4))){
      if(anchor.name.startsWith('left')) {
        align["right"] = rightBottom.dx + size.width - widget.offset.dx;
      } else if(anchor.name.startsWith('right')) {
        align["left"] = leftTop.dx + size.width + widget.offset.dx;
      }

      if(widget.direction == OpenDirection.bottom){
        final value = size.height * (widget.direction.value + anchor.value);
        align["top"] = leftTop.dy + value + widget.offset.dy;
      } else if(widget.direction == OpenDirection.top) {
        final value = size.height * (widget.direction.value - anchor.value);
        align["bottom"] = rightBottom.dy + value - widget.offset.dy;
      }
    } else {
      if(anchor.name.startsWith('top')) {
        align["bottom"] = rightBottom.dy + size.height - widget.offset.dy;
      } else if(anchor.name.startsWith('bottom')) {
        align["top"] = leftTop.dy + size.height + widget.offset.dy;
      }

      if(widget.direction == OpenDirection.left){
        final value = size.width * (widget.direction.value - anchor.value);
        align["right"] = rightBottom.dx + value - widget.offset.dy;
      } else if(widget.direction == OpenDirection.right) {
        final value = size.width * (widget.direction.value + anchor.value);
        align["left"] = leftTop.dx + value + widget.offset.dx;
      }
    }

    return align;
  }

  void _showOverlay() {
    if(_overlayEntry != null) return;

    final box = context.findRenderObject() as RenderBox;

    final size = box.size;
    final screen = MediaQuery.of(context).size;
        
    final leftTop = box.localToGlobal(Offset.zero);
    final rightBottom = Offset(screen.width - leftTop.dx - size.width, screen.height - leftTop.dy - size.height);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final align = _calcPosition(leftTop, rightBottom, size);

        return Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return GestureDetector(
                    onTap: widget.barrierDismissible ? _removeOverlay : null,
                    child: ColoredBox(
                      color: widget.barrierColor.withOpacity(_barrierAnimation.value)
                    ),
                  );
                },
              ),
            ),
        
            widget.anchor == null
              ? widget.builder(context, _controller, leftTop)
              : Positioned(
                top: align["top"],
                left: align["left"],
                right: align["right"],
                bottom: align["bottom"],
                child: widget.builder(context, _controller, leftTop)
              ),
          ],
        );
      }
    );

    if(widget.overlayType == OverlayType.animated){
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }

    Overlay.of(context)!.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    if(_overlayEntry != null){
      if(widget.overlayType == OverlayType.animated){
        _controller.reverse().whenComplete(() {
          _overlayEntry!.remove();
          _overlayEntry = null;

          if(widget.onRemove != null){
            widget.onRemove!();
          }
        });
      } else {
        _controller.value = 0.0;
        _overlayEntry!.remove();
        _overlayEntry = null;
      }
    }
  }

  void syncOverlay() {
    if(!widget.showOverlay){
      _overlayVisible = false;
      _removeOverlay();
    } else if(widget.showOverlay){
      _overlayVisible = widget.showOverlay;
      _showOverlay();
    } 
    
    if(_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
