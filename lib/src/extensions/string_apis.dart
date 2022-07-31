import 'package:flutter/material.dart';
import 'dart:math' as math;

extension StringApis on String {
  bool get isValidEmail {
    final emailRegExp = RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    return emailRegExp.hasMatch(this);
  }

  bool get isValidName{
    final nameRegExp = RegExp(r"^\s*([A-Za-z]{1,}([\.,] |[-']| ))+[A-Za-z]+\.?\s*$");
    return nameRegExp.hasMatch(this);
  }

  bool get isValidPassword{
    // final passwordRegExp = RegExp(r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\><*~]).{8,}/pre>');
    // return passwordRegExp.hasMatch(this);
  
    return length > 5;
  }

  bool get isValidPhone{
    final phoneRegExp = RegExp(r"^\+?0[0-9]{10}$");
    return phoneRegExp.hasMatch(this);
  }

  bool equals(String text, [bool sensitive = false]) {
    return toLowerCase() == text.toLowerCase();
  }

  String hidde(int start, int end, [String replacement = 'X']) {
    if(end.isNegative) {
      end = length + end;
    }

    final times = end - start;

    return replaceRange(start, end, replacement * times);
  }

  List<String> parseFile() {
    final parts = split('.');
    
    final ext = parts.removeLast();
    final name = parts.join('.');

    return [name, ext];
  }

  static double _normalizeHash(int hash, int min, int max) {
    return ((hash % (max - min)) + min).floor().toDouble();
  }

  static const _hRange = [0, 360];
  static const _sRange = [50, 75];
  static const _lRange = [25, 60];

  /// Forma de crear colores aleatorios basados en un string, podemos variar la paleta de colores salientes
  /// cambiando los rangos de los valores para el HSL
  Color getRandomColor() {
    int hash = 0;

    for (var i = 0; i < length; i++) {
      hash = codeUnitAt(i) + ((hash << 5) - hash);
    }

    hash = hash.abs();

    final h = _normalizeHash(hash, _hRange[0], _hRange[1]);
    final s = _normalizeHash(hash, _sRange[0], _sRange[1]) / 100;
    final l = _normalizeHash(hash, _lRange[0], _lRange[1]) / 100;

    return HSLColor.fromAHSL(1.0, h, s, l).toColor();
  }

  String initials ([int characters = 2]) {
    String out = '';

    final parts = split(' ');
    final max = math.min(parts.length, characters);

    for (var i = 0; i < max; i++) {
      out += parts[i][0].toUpperCase();
    }

    return out;
  }

  String get breakWord{
    String breakWord = '';
    
    for (int element in runes) {
      breakWord += String.fromCharCode(element);
      breakWord +='\u200B';
    }
    
    return breakWord;
  }
}