import 'package:flutter/material.dart' show debugPrint;
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Pordria tambien crear el AppResponse pero de este se utiliza casi siempre solo el payload
class ErrorResponse {
  final int status;
  final String code;
  final String message;
  final dynamic details;

  const ErrorResponse({
    this.status = 500,
    this.code = 'UNKNOWN_ERROR',
    this.message = 'There was an error, please try again',
    this.details,
  });

  factory ErrorResponse.fromJson(Map<String, dynamic> json) => ErrorResponse(
    status: json["status"],
    code: json["code"],
    message: json["message"],
    details: json["details"],
  );

  factory ErrorResponse.fromObject(Object e) {
    debugPrint('error from error response: $e');

    if(e is DioError) {
      if(e.response != null){
        return ErrorResponse.fromJson(e.response!.data);
      } else {
        if(e.type == DioErrorType.cancel){
          return ErrorResponse(code: e.type.name, message: 'The request was canceled', details: e.error);
        } else {
          return ErrorResponse(code: e.type.name, message: e.message, details: e.error);
        }
      }
      
    }

    if(e is FirebaseAuthException){
      if(e.code == 'invalid-phone-number'){
        return ErrorResponse(code: e.code, message: 'The provided phone number is not valid.');
      } else {
        return ErrorResponse(code: e.code, message: e.message!);
      }
    }

    if(e is ErrorResponse){
      return e;
    }

    return const ErrorResponse();
  }
}