import 'package:flutter/material.dart';

class InputStyles { 
  static final authInputStyle = InputDecoration(
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(50),
      borderSide: BorderSide(color: Colors.grey.withOpacity(0.3))
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(100),
      borderSide: BorderSide(color: Colors.grey.withOpacity(0.3))
    ),
  );

  
}