import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:mime/mime.dart';
import 'package:pdfx/pdfx.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import 'dart:io';

import '../global/globals.dart';
import '../extensions/string_apis.dart';
import '../services/auth_service.dart';
import '../models/models.dart' hide MediaType;

const uploadMediaRoute = '/media';

class FilesService {
  FilesService() {
    _dio.options.baseUrl = '$_host/api/uploads';
    _dio.options.connectTimeout = 10000;
  }

  void dispose() {  
    _dio.close();
  }

  final _host = Environment.apiHost;
  final _dio = Dio();

  ErrorResponse? error;

  Future<ErrorResponse?> deleteTempFile(String secureUrl) async {
    try {
      final options = Options(headers: {"x-token": AuthService.token});
      await _dio.delete(uploadMediaRoute, data: {"url": secureUrl}, options: options);
      return null;
    } catch (e) {
      return ErrorResponse.fromObject(e);
    }
  }

  Future<String?> uploadFile(String name) async {
    /// Cuando se quiere devolver un valor (como string) y al tiempo devolver el error utilzizamos una
    /// variable auxiliar que consultaremos una vez se termine esta peticion
    error = null;

    try {
      final options = Options(
        headers: {
          'x-token': AuthService.token,
          'Content-Type': 'multipart/form-data'
        }
      );

      final mime = lookupMimeType(name);

      /// Siempre que se va a subir un documento es de parte del que envia, antes de enviarse el mensaje
      /// el asset ya esta guardado en la carpeta de send, tomamos este path y enviamos la peticion
      final file = await MultipartFile.fromFile(
        '${AppFolder.sentDirectory}/$name',
        contentType: mime == null ? null : MediaType(mime.split('/')[0], mime.split('/')[1])
      );

      final formData = FormData.fromMap({'file': file});

      final response = await _dio.post(uploadMediaRoute, data: formData, options: options);

      final mediaResponse = MediaResponse.fromJson(response.data);
      return mediaResponse.url;
    } catch (e) {
      error = ErrorResponse.fromObject(e);
      return null;
    }
  }

  Future<ErrorResponse?> downloadFile(MediaMessage message) async {
    try {
      /// Creamos el folder donde se almacenara el archivo
      final file = File('/${AppFolder.receivedDirectory}/${message.filename}');

      /// Descargamos el archivo en formato de bytes
      final options = Options(responseType: ResponseType.bytes, followRedirects: false, receiveTimeout: 0);

      /// Como tiene el https, ignora el baseUrl
      final response  = await _dio.get(message.tempUrl!, options: options);

      /// Sea cual sea la extension creamos el archivo
      await file.create();
      await file.writeAsBytes(response.data);

      final mime = lookupMimeType(message.filename) ?? 'image/jpg';

      /// Si es una imagen, no necesita thumbnail, si es un video o pdf se genera el thumbnail
      if(mime.startsWith('video')){
        await VideoThumbnail.thumbnailFile(
          video: file.path,
          thumbnailPath: AppFolder.thumbnailsDirectory,
          imageFormat: ImageFormat.PNG,
          maxWidth: 600,
          quality: 100
        );
      } else if(mime.endsWith('pdf')){
        final document = await PdfDocument.openFile(file.path);
        final page = await document.getPage(1);

        final pageImage = await page.render(
          width: page.width, 
          height: page.height,
          format: PdfPageImageFormat.png // default jpeg
        );
        
        Future.wait<void>(<Future<void>>[page.close(), document.close()]);

        if(pageImage != null){
          final parts = message.filename.parseFile();
          
          final thumbnailFilename = '${parts[0]}.png';
          final thumbailFile = File('${AppFolder.thumbnailsDirectory}/$thumbnailFilename');

          thumbailFile.writeAsBytesSync(pageImage.bytes);
        }
      }

      return null;
    } catch (e) {
      return ErrorResponse.fromObject(e);
    }
  }
}