
// ignore_for_file: body_might_complete_normally_nullable

import 'dart:io';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:dio/dio.dart';

import '../global/globals.dart';
import '../services/services.dart';
import '../models/models.dart';

class FileServices {
  static final _apiHost = Environment().config.apiHost;
  static final _apiRoutes = Environment().apiRoutes;
  static final _appFolder = Environment().appFolder;

  final _dio = Dio();
  final Cloudinary _cloudinary = Cloudinary('939227237552849', 'ErEEDpd7aPkDhNzJkg-2de9v0PY', 'dwzr9lray');

  Future<bool> deleteTempFile(String secureUrl) async {
    final file = secureUrl.split('/').last.split('.');
    final name = file[0];
    final ext = file[1];
    
    final res = await _cloudinary.deleteFile(
      publicId: 'flutter_chat_back/chat/$name',
      resourceType: ext == 'wav' ? CloudinaryResourceType.video : CloudinaryResourceType.image
    );

    return res.isSuccessful;
  }

  ErrorResponse? error;

  Future<String?> uploadFile(String name) async {
    final url = _apiHost + _apiRoutes.upload_file;
    final token = AuthServices.token;

    error = null;

    try {
      final body = FormData.fromMap({'file': await MultipartFile.fromFile('${_appFolder.sent.path}/$name')});
      final response = await _dio.post(url, data: body, options: Options(headers: {'x-token': token}));

      final chatFileResponse = ChatFileResponse.fromJson(response.data);
      return chatFileResponse.file.secureUrl;
    } on DioError catch (e){
      if(e.response != null){
        error = ErrorResponse.fromJson(e.response!.data);
        return null;
      }
    } catch (e) {
      error = ErrorResponse(
        error: e.toString(), 
        details: Details(code: 500, msg: e.toString(), name: "UNKNOWN ERROR", extra: null)
      );
      return null;
    }
  }

  Future<ErrorResponse?> downloadFile(String url, String name) async {
    try {
      final response  = await _dio.get(url,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
          receiveTimeout: 0
        )
      );

      final file = File('${_appFolder.received.path}/$name');
        
      await file.create();
      await file.writeAsBytes(response.data);
    } on DioError catch (e){
      if(e.response != null){
        return ErrorResponse.fromJson(e.response!.data);
      }
    } catch (e) {
      return ErrorResponse(
        error: e.toString(), 
        details: Details(code: 500, msg: e.toString(), name: "UNKNOWN ERROR", extra: null)
      );
    }
  }
}