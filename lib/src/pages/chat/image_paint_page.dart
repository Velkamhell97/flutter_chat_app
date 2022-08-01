import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:typed_data';
import 'dart:ui';

import '../../widgets/painters.dart';

class ImagePaintPage extends StatefulWidget {
  final ValueNotifier<ImageProvider> imageNotifier;
  final String heroTag;

  const ImagePaintPage({
    Key? key,
    required this.imageNotifier,
    required this.heroTag,
  }) : super(key: key);

  @override
  State<ImagePaintPage> createState() => _ImagePaintPageState();
}

class _ImagePaintPageState extends State<ImagePaintPage> {
  Uint8List? _bytes;
  ImageProvider<Object>? _image;
  
  final _canvasKey = GlobalKey();
  final _sliderNotifier = ValueNotifier<double>(0.3);

  bool _processing = false;
  bool _exit = false;

  Color _currentColor = Colors.white;
  int _index = 0;
  List<Offset> _points = [];

  /// Se utilizan ValueNotifier como repaint del CustomPainter, a diferencia de un AnimationController
  /// Tambien se usan repaint boundarys para no redibujar otros painters, no se sabe si sea mala practica
  List<ValueNotifier<List<Offset>>> _drawLines = [];

  bool _showCanvas = false;

  static const _transitionDuration = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();

    /// Se agrega el primer array de puntos de la primera linea
    _drawLines.add(ValueNotifier<List<Offset>>([]));

    _getColor(_sliderNotifier.value);

    Future.delayed(_transitionDuration, () {
      setState(() => _showCanvas = true);
    });
  }

  @override
  void dispose() {
    _sliderNotifier.dispose();

    for(ValueNotifier<List<Offset>> line in _drawLines){
      line.dispose();
    }

    super.dispose();
  }

  Future<void> _saveCanvas() async {
    _processing = true;

    final boundary = _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

    /// Entre mas pixel ratio mas pesado computacionalmente
    final image = await boundary.toImage(pixelRatio: 2.0);

    /// No se sabe si el await o el then afecten
    image.toByteData(format: ImageByteFormat.png).then((byteData) {
      _bytes = byteData!.buffer.asUint8List();
      /// Si la primera pantalla no tuviera un file todo se podria hacer con Image.memory
      _image = Image.memory(_bytes!).image;

      precacheImage(_image!, context).then((_) {
        _processing = false;

        ///Si se le dio confirmar antes de completar el screenshot actualiza la imagen
        if(_exit){
          widget.imageNotifier.value = _image!;
          Navigator.of(context).maybePop(_bytes);
        }
      });
    });
  }

  void _getColor(double position) {
    final colorFraction = position * (_colors.length - 1);
    
    final colorIndex = colorFraction.truncate();

    final remainder = colorFraction - colorIndex;

    if (remainder == 0.0) {
      _currentColor = _colors[colorIndex];
    } else {
      int redValue = _colors[colorIndex].red == _colors[colorIndex + 1].red
          ? _colors[colorIndex].red
          : (_colors[colorIndex].red +
                  (_colors[colorIndex + 1].red - _colors[colorIndex].red) * remainder)
              .round();

      int greenValue = _colors[colorIndex].green == _colors[colorIndex + 1].green
          ? _colors[colorIndex].green
          : (_colors[colorIndex].green +
                  (_colors[colorIndex + 1].green - _colors[colorIndex].green) * remainder)
              .round();

      int blueValue = _colors[colorIndex].blue == _colors[colorIndex + 1].blue
          ? _colors[colorIndex].blue
          : (_colors[colorIndex].blue +
                  (_colors[colorIndex + 1].blue - _colors[colorIndex].blue) * remainder)
              .round();
      
      _currentColor = Color.fromARGB(255, redValue, greenValue, blueValue);
    }
  }

  static const _colors = [
    Color.fromARGB(255, 255, 0, 0),
    Color.fromARGB(255, 255, 128, 0),
    Color.fromARGB(255, 255, 255, 0),
    Color.fromARGB(255, 128, 255, 0),
    Color.fromARGB(255, 0, 255, 0),
    Color.fromARGB(255, 0, 255, 128),
    Color.fromARGB(255, 0, 255, 255),
    Color.fromARGB(255, 0, 128, 255),
    Color.fromARGB(255, 0, 0, 255),
    Color.fromARGB(255, 127, 0, 255),
    Color.fromARGB(255, 255, 0, 255),
    Color.fromARGB(255, 255, 0, 127),
    Color.fromARGB(255, 128, 128, 128),
  ];

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return WillPopScope(
      onWillPop: () async {
        setState(() => _showCanvas = false);

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
                  /// IMAGE AND LINES
                  ///-----------------------------------
                  Expanded(
                    child: Center(
                      child: RepaintBoundary(
                        key: _canvasKey,
                        ///Para que las lineas no se salgan de la imagen
                        child: ClipRRect(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              ///-----------------------------------
                              /// IMAGE MODIFIED
                              ///-----------------------------------
                              ValueListenableBuilder<ImageProvider<Object>?>(
                                valueListenable: widget.imageNotifier, 
                                builder: (_, image, __) {
                                  return Hero(
                                    tag: widget.heroTag,
                                    createRectTween: (begin, end) => RectTween(begin: begin, end: end),
                                    child: Image(image: image!)
                                  );
                                },
                              ),
                                                
                              ///-----------------------------------
                              /// CANVAS PAINTER
                              ///-----------------------------------
                              Positioned.fill(
                                child: GestureDetector(
                                  onPanUpdate: (details) {
                                    ///se agregan las lineas y se agregan al valueNotifier;
                                    _points.add(details.localPosition);
                                    _drawLines[_index].value = List.from(_points);
                                  },
                                  onPanEnd: (_) {
                                    ///Alterminar se graba el canvas y se crea una nueva linea
                                    _saveCanvas();
                                                            
                                    _index++;
                                    _points = [];

                                    /// Siempre que se levanta el dedo se hace una nueva linea                                      
                                    setState(() {
                                      _drawLines.add(ValueNotifier<List<Offset>>([]));
                                    });                          
                                  },
                                  child:  AnimatedOpacity(
                                    duration: kThemeAnimationDuration,
                                    opacity: _showCanvas ? 1.0 : 0.0,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: _drawLines.map((points) {
                                        ///El rapaint boundary es necesario para que no se redibujen las otras
                                        ///lineas cuando se trabaja en la actual, en otros tutoriales se utiliza
                                        ///un solo custom painter, una sugerencia es colocar un custom painter atras
                                        ///que dibuje las lineas y colores acumulados con el repaint boudnary
                                        ///y al frente un solo painer que dibuje la linea actual
                                        return RepaintBoundary(
                                          child: CustomPaint(
                                            painter: CanvasPainter(
                                              color: _currentColor,
                                              points: points
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  ///-----------------------------------
                  /// COLOR PICKER AND BUTTONS
                  ///-----------------------------------
                  Column(
                    children: [
                      ///-----------------------------------
                      /// COLOR PICKER
                      ///-----------------------------------
                      ValueListenableBuilder<double>(
                        valueListenable: _sliderNotifier,
                        builder: (context, sliderValue, __) {
                          return SliderTheme(
                            data: SliderThemeData(
                              showValueIndicator: ShowValueIndicator.always,
                              valueIndicatorShape: ColorPickerValueIndicatorShape(color: _currentColor),
                              thumbShape: ColorPickerThumbShape(color: _currentColor),
                              trackShape: const ColorPickerTrackShape(colors: _colors)
                            ), 
                            child: Slider(
                              label: 'any', ///Para que salga el indicator
                              value: sliderValue,
                              onChanged: (value) {
                                _getColor(value);
                                _sliderNotifier.value = value;
                              },
                              onChangeEnd: (_) => setState(() {}),
                            )
                          );
                        },
                      ),
            
                      ///-----------------------------------
                      /// BUTTONS
                      ///-----------------------------------
                      Row(
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
                            onPressed: () {
                              setState(() => _drawLines = []);
                              Navigator.of(context).maybePop();
                            },
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
                              if(_drawLines.length == 1){
                                return;
                              }
            
                              _bytes = null;
                              _index = 0;

                              _points = [];
                              _drawLines = [ValueNotifier<List<Offset>>([])];
            
                              setState(() {});
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

                              /// Si se ha presionado y no esta listo prepara el completer
                              if(_bytes != null){
                                widget.imageNotifier.value = _image!;
                              }

                              Navigator.of(context).maybePop(_bytes);
                            },
                            child: const Text('Confirm')
                          )
                        ],
                      ),
                    ],
                  )
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

