
import 'dart:io';
import 'package:chat_app/services/services.dart';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:dio/dio.dart';

import 'package:chat_app/global/enviorement.dart';
import 'package:chat_app/models/models.dart';

class FileServices {
  static final _apiHost = Environment().config.apiHost;
  static final _apiRoutes = Environment().apiRoutes;
  static final _appFolder = Environment().appFolder;

  final _dio = Dio();
  final Cloudinary _cloudinary = Cloudinary('939227237552849', 'ErEEDpd7aPkDhNzJkg-2de9v0PY', 'dwzr9lray');

  Future<bool> deleteTempFile(String secureUrl) async {
    final name = secureUrl.split('/').last.split('.').first;
    final res = await _cloudinary.deleteFile(publicId: 'flutter_chat_back/chat/$name');

    return res.isSuccessful;
  }

  Future<String?> uploadFile(String name) async {
    final url = _apiHost + _apiRoutes.upload_file;
    final token = AuthServices.token;

    try {
      final body = FormData.fromMap({'file': await MultipartFile.fromFile('${_appFolder.sent.path}/$name')});
      final response = await _dio.post(url, data: body, options: Options(headers: {'x-token': token}));

      final chatFileResponse = ChatFileResponse.fromJson(response.data);
      return chatFileResponse.file.secureUrl;
    } on DioError catch (e){
      print(e.response);
      // if(e.response != null){
      //   return ErrorResponse.fromJson(e.response!.data);
      // }
    } catch (e) {
      print(e.toString());
      // return ErrorResponse(
      //   error: e.toString(), 
      //   details: Details(code: 500, msg: e.toString(), name: "UNKNOWN ERROR", extra: null)
      // );
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