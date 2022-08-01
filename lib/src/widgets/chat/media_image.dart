import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:matrix_gesture_detector/matrix_gesture_detector.dart';
import 'dart:typed_data';
import 'dart:ui';

class MediaImage extends StatefulWidget {
  final ImageProvider<Object> image;
  final List<String> emojis;
  final String? heroTag;
  final double? fitScale;
  final Function(ImageProvider image, Uint8List bytes)? onEmojiChanged;

  const MediaImage({
    Key? key,
    required this.image,
    this.emojis = const [],
    this.heroTag,
    this.fitScale,
    this.onEmojiChanged
  }) : super(key: key);

  @override
  State<MediaImage> createState() => _MediaImageState();
}

/// Para no perder estados con el pageview (multiple selected)
class _MediaImageState extends State<MediaImage> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final AnimationController _animationController;

  final _canvasKey = GlobalKey();
  final _transformationController = TransformationController();

  Animation<Matrix4>? _transformationAnimation;

  static const _duration = Duration(milliseconds: 300);
  static const _emojiSize = 120.0;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(vsync: this, duration: _duration);

    _animationController.addListener(() {
      _transformationController.value = _transformationAnimation!.value;
    });
  }

  void _restoreScale() {
    if(_animationController.isAnimating) return;

    _transformationAnimation = Matrix4Tween(
      begin: _transformationController.value,
      end: Matrix4.identity()
    ).animate(_animationController);

    _animationController.forward(from: 0.0);
  }

  ///Para el scale de las fotos tomadas de camara y seleccionadas en la galeria (extra)
  Widget _heroFlight(BuildContext context, Animation<double> animation, HeroFlightDirection direction, BuildContext from, BuildContext to) {
    final child = direction == HeroFlightDirection.pop ? from.widget : to.widget;
                
    return AnimatedBuilder(
      animation: animation, 
      child: child,
      builder: (_, child) {
        final scale = lerpDouble(widget.fitScale, 1.0, animation.value)!;
        return Transform.scale(scale: scale, child: child);
      }
    );
  }

  ///Siempre se tarda como 2 segundos, con pixelRatio en 1.0 tarda casi 1
  Future<void> _saveCanvas() async {
    if(widget.onEmojiChanged == null) return;

    final boundary = _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

    final image = await boundary.toImage(pixelRatio: 2.0);

    image.toByteData(format: ImageByteFormat.png).then((byteData) {
      final bytes = byteData!.buffer.asUint8List();
      final image = Image.memory(bytes).image;
      widget.onEmojiChanged!(image, bytes);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    /// Mejor pasarlo al didChangeDependencies
    final Size size = MediaQuery.of(context).size;

    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 0.1,
      onInteractionEnd: (details) {
        final scale = _transformationController.value.entry(0, 0);
    
        if(details.pointerCount < 2 && scale < 1.0){
          _restoreScale();
        }
      },
      child: Center(
        child: RepaintBoundary(
          key: _canvasKey,
          child: Stack(
            /// Cuando hay una imagen de camara o de galeria
            fit: widget.fitScale == null ? StackFit.loose : StackFit.expand,
            children: [
              ///-----------------------------------
              /// MULTIPLE IMAGE FILE
              ///-----------------------------------
              /// Si se seleccionan con multiples imagenes
              if(widget.heroTag == null)
                SizedBox(
                  width: size.width,
                  child: Image(image: widget.image),
                ),

              ///-----------------------------------
              /// CAMERA OR GALLERY IMAGE
              ///-----------------------------------
              if(widget.heroTag != null)
                Hero(
                  tag: widget.heroTag!,
                  createRectTween: (begin, end) => RectTween(begin: begin, end: end),
                  flightShuttleBuilder: widget.fitScale == null ? null : _heroFlight,
                  child: SizedBox(
                    width: size.width,
                    child: Transform.scale(
                      scale: widget.fitScale ?? 1.0,
                      child: Image(image: widget.image),
                    ),
                  ),
                ),
            
              ///-----------------------------------
              /// EMOJIS
              ///-----------------------------------
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final middleWidth = (constraints.maxWidth / 2) - (_emojiSize / 2);
                    final middleHeight = (constraints.maxHeight / 2) - (_emojiSize / 2);
                    
                    return Listener(
                      onPointerUp: (_) => _saveCanvas(),
                      child: Stack(
                        children: [
                          for(String emoji in widget.emojis)
                            _DraggableEmoji(
                              center: Offset(middleWidth, middleHeight), 
                              emoji: emoji
                            )
                        ]
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
  
  @override
  bool get wantKeepAlive => true;
}


class _DraggableEmoji extends StatefulWidget {
  final Offset center;
  final String emoji;

  const _DraggableEmoji({Key? key, required this.center, required this.emoji}) : super(key: key);

  @override
  State<_DraggableEmoji> createState() => __DraggableEmojiState();
}

class __DraggableEmojiState extends State<_DraggableEmoji> {
  late final ValueNotifier<Matrix4> _transformNotifier;

  @override
  void initState() {
    super.initState();
    _transformNotifier = ValueNotifier(Matrix4.identity());
  }

  @override
  void dispose() {
    _transformNotifier.dispose();
    super.dispose();
  }

  Matrix4 tMatrix = Matrix4.identity();
  Matrix4 sMatrix = Matrix4.identity();
  Matrix4 rMatrix = Matrix4.identity();

  @override
  Widget build(BuildContext context) {
    /// Otra forma de utilizar el ValueNotifier
    return AnimatedBuilder(
      animation: _transformNotifier,
      child: MatrixGestureDetector(
        clipChild: false,
        focalPointAlignment: Alignment.center, 
        onMatrixUpdate: (matrix, tm, sm, rm) {
          tMatrix = tMatrix * tm;
          sMatrix = sMatrix * sm;
          rMatrix = rMatrix * rm;
    
          _transformNotifier.value = matrix;
        },
        child: FittedBox(
          child: Text(
            widget.emoji, 
            style: const TextStyle(fontSize: 80)
          )
        ),
      ),
      builder: (_, child) {
        final tOffset = Offset(tMatrix.entry(0, 3), tMatrix.entry(1, 3));
        final sOffset = Offset(sMatrix.entry(0, 3), sMatrix.entry(1, 3));
        final rotation =  MatrixGestureDetector.decomposeToValues(rMatrix).rotation;

        return Positioned(
          left:   widget.center.dx + sOffset.dx + tOffset.dx,
          top:    widget.center.dy + sOffset.dy + tOffset.dy,
          right:  widget.center.dx + sOffset.dx - tOffset.dx,
          bottom: widget.center.dy + sOffset.dy - tOffset.dy,
          child: Transform.rotate(
            angle: rotation,
            child: child,
          ),
        );
      },
    );
  }
}