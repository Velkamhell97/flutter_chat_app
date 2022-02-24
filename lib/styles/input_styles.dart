import 'package:flutter/material.dart';

class InputStyles { 
  static final authInputStyle = InputDecoration(
    enabledBorder: OutlineShadownInputBorder(
      borderRadius: BorderRadius.circular(50),
      borderSide: BorderSide.none,
    ),
    fillColor: Colors.white,
    filled: true,

    focusedBorder: OutlineShadownInputBorder(
      borderRadius: BorderRadius.circular(50),
      borderSide: BorderSide.none
    ),
    errorBorder: OutlineShadownInputBorder(
      borderRadius: BorderRadius.circular(50),
      borderSide: const BorderSide(color: Colors.red)
    ),
    focusedErrorBorder: OutlineShadownInputBorder(
      borderRadius: BorderRadius.circular(50),
      borderSide: const BorderSide(color: Colors.red)
      //-Por alguna razon al agregar mas borde al focus, no se ve correcto el sombreado
    ),
  );
}

class OutlineShadownInputBorder extends OutlineInputBorder {
  const OutlineShadownInputBorder({
    BorderSide borderSide = const BorderSide(),
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(4.0)),
    double gapPadding = 4.0,
  }) : super(
    borderSide: borderSide,
    borderRadius: borderRadius,
    gapPadding: gapPadding
  );

  //-Llamamos el metodo super que pinta el borde tal cual y solo agregamos a ese canvas el sombreado
  @override
  void paint(Canvas canvas, Rect rect, {double? gapStart, double gapExtent = 0.0, double gapPercentage = 0.0, TextDirection? textDirection}) {
    super.paint(canvas, rect, gapStart: gapStart, gapExtent: gapExtent, gapPercentage: gapPercentage, textDirection: textDirection);
    
    final RRect outer = borderRadius.toRRect(rect);
    final RRect center = outer.deflate(borderSide.width / 2.0);

    //-Esta es la sombra que se se le agrega al input outline, pero debido a que este es un path con fill
    //-y el canvas del rect, es solo un rect con border la sombra se superpondra sobre el rect
    final path = Path();
    path.addRRect(center);
    canvas.drawShadow(path, Colors.black.withOpacity(0.65), 6.0, false);

    //-por esta razon agregamos otro path con el style en fill para que tape esta sombra por encima
    //-y deje unicamente la que sobresale por la elevacion
    final shadownPaint = Paint()
    ..strokeWidth = 0
    ..color =Colors.white; //Debe ser el color del fondo
    canvas.drawRRect(center, shadownPaint);
  }
}