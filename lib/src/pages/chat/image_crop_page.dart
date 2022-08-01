import 'package:flutter/material.dart';
import 'package:crop_image/crop_image.dart';
import 'dart:typed_data';
import 'dart:ui';

class ImageCropPage extends StatefulWidget {
  final ValueNotifier<ImageProvider> imageNotifier;
  final String heroTag;

  const ImageCropPage({
    Key? key,
    required this.imageNotifier,
    required this.heroTag,
  }) : super(key: key);

  @override
  State<ImageCropPage> createState() => _ImageCropPageState();
}

class _ImageCropPageState extends State<ImageCropPage> {
  final _controller = CropController();
  final _imageKey = GlobalKey();

  late ImageProvider<Object> _original;

  Uint8List? _bytes; /// bytes a devolver
  ImageProvider<Object>? _image; ///Imagen modificada (a medida que se mueve el recuadro)

  bool _processing = false; 
  bool _exit = false; /// Si debe salir despues de procesar

  bool _showCropper = false;
  bool _cropped = false;
  
  Size _imageSize = Size.zero;

  static const _transitionDuration = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();

    _original = widget.imageNotifier.value;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _imageSize = _imageKey.currentContext!.size!;
    });

    ///Como no se le puede poner el hero al cropper se esconde por un momento
    Future.delayed(_transitionDuration, () {
      setState(() => _showCropper = true);
    });
  }

  @override
  void dispose() {
    /// Por alguna razon falla
    // _controller.dispose();
    super.dispose();
  }

  Future<void> _crop(PointerUpEvent event) async {
    _processing = true;

    final bitmap = await _controller.croppedBitmap();
    final byteData = await bitmap.toByteData(format: ImageByteFormat.png);

    _bytes = byteData!.buffer.asUint8List();
    _image = Image.memory(_bytes!).image;

    /// Hacemos un precache para no ver un salto al cambiar imagen
    precacheImage(_image!, context).then((_) {
      _processing = false;

      /// Si ysa se habia undido el de crop se sale
      if(_exit){
        widget.imageNotifier.value = _image!;
        Navigator.of(context).maybePop(_bytes);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    /// Se podria pasar la logica a el didChangeDependencies
    final Size size = MediaQuery.of(context).size;

    final height = _imageSize.height * _controller.crop.height;

    return WillPopScope(
      onWillPop: () async {
        ///Antes de salir opacamos el cropper y esperamos un poco
        setState(() => _showCropper = false);

        await Future.delayed(const Duration(milliseconds: 100));

        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              ///-----------------------------------
              /// MAIN WIDGET
              ///-----------------------------------
              Column(
                children: [
                  ///-----------------------------------
                  /// IMAGE AND CROP
                  ///-----------------------------------
                  Expanded(
                    flex: 8,
                    child: SizedBox(
                      width: size.width * 0.85,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final center = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);

                          ///El top es el centro menos la mitad original mas la parte top recortada
                          final top = center.dy - _imageSize.height / 2 + _imageSize.height * _controller.crop.top;

                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              ///-----------------------------------
                              /// MODIFIED IMAGE
                              ///-----------------------------------
                              Positioned(
                                top: !_cropped ? null : top,
                                height: !_cropped ? null : height,
                                child: ValueListenableBuilder<ImageProvider<Object>>(
                                  valueListenable: widget.imageNotifier,
                                  builder: (_, image, __) {
                                    return Hero(
                                      tag: widget.heroTag,
                                      createRectTween: (begin, end) => RectTween(begin: begin, end: end),
                                      child: Image(
                                        image: image,
                                        key: _imageKey,
                                      )
                                    );
                                  },
                                ),
                              ),

                              ///-----------------------------------
                              /// CROP RECT
                              ///-----------------------------------
                              AnimatedOpacity(
                                opacity: _showCropper ? 1.0 : 0.0,
                                duration: kThemeAnimationDuration,
                                child: Listener(
                                  onPointerUp: _crop,
                                  /// Se hizo modificacion al codigo para que actualizara el scrimColor con el setState
                                  child: CropImage(
                                    controller: _controller,
                                    scrimColor: _cropped ? Colors.black : Colors.black54,
                                    image: Image(image: _original),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                  ///-----------------------------------
                  /// BUTTONS
                  ///-----------------------------------
                  Expanded(
                    flex: 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ///-----------------------------------
                        /// CANCEL
                        ///-----------------------------------
                        TextButton(
                          style: TextButton.styleFrom(
                            primary: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0)
                          ),
                          onPressed: () => Navigator.of(context).maybePop(),
                          child: const Text('Cancel')
                        ),

                        ///-----------------------------------
                        /// RESET
                        ///-----------------------------------
                        TextButton(
                          style: TextButton.styleFrom(
                            primary: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0)
                          ),
                          onPressed: () {
                            _controller.crop = const Rect.fromLTWH(0, 0, 1.0, 1.0);
                          },
                          child: const Text('Reset')
                        ),

                        ///-----------------------------------
                        /// CONFIRM
                        ///-----------------------------------
                        TextButton(
                          style: TextButton.styleFrom(
                            primary: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0)
                          ),
                          onPressed: () async {
                            if(_processing){
                              _exit = true;
                              return;
                            }

                            if(_bytes != null) {
                              setState(() => _cropped = true);
                              widget.imageNotifier.value = _image!;
                            }

                            Navigator.of(context).maybePop(_bytes);
                          },
                          child: const Text('Confirm')
                        )
                      ],
                    ),
                  ),
                ],
              ),

              ///-----------------------------------
              /// HEADER
              ///-----------------------------------
              Positioned(
                top: -100,
                child: Hero(
                  tag: 'header',
                  child: SizedBox(
                    width: size.width,
                  )
                ),
              ),

              ///-----------------------------------
              /// FOOTER
              ///-----------------------------------
              Positioned(
                bottom: -100,
                child: Hero(
                  tag: 'footer',
                  child: SizedBox(
                    width: size.width,
                    height: 80,
                  )
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}