import 'package:flutter/material.dart';

class ButtonStyles {
  static final countryButton = ElevatedButton.styleFrom(
    primary: Colors.white,
    onPrimary: Colors.black,
    shape: const StadiumBorder(),
    elevation: 6.0,
    shadowColor: Colors.black.withOpacity(0.65),
    padding: const EdgeInsets.symmetric(horizontal: 10.0),
    splashFactory: NoSplash.splashFactory
  );

  static final authButton = ElevatedButton.styleFrom(
    elevation: 5,
    shape: const StadiumBorder(),
    padding: const EdgeInsets.symmetric(vertical: 15.0)
  );

  static final phoneButton = ElevatedButton.styleFrom(
    shape: const StadiumBorder(),
    // onPrimary: Colors.white,
    onSurface: Colors.green,
    padding: const EdgeInsets.symmetric(vertical: 12.0),
    primary: Colors.green
  );

  static final googleButton = ElevatedButton.styleFrom(
    shape: const StadiumBorder(),
    // onPrimary: Colors.white,
    onSurface: Colors.grey,
    padding: const EdgeInsets.symmetric(vertical: 12.0),
    primary: Colors.black
  );
}