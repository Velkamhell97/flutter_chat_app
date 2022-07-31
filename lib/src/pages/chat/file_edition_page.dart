import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pdfx/pdfx.dart';
import 'package:provider/provider.dart';
import 'package:mime/mime.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:io';

import '../../global/constants.dart';
import '../../providers/chat_message_provider.dart';
import '../../services/services.dart';
import '../../widgets/chat/chat.dart';

class FileEditionPage extends StatefulWidget {
  final List<File> files;

  const FileEditionPage({
    Key? key, 
    required this.files,
  }) : super(key: key);

  @override
  State<FileEditionPage> createState() => _FileEditionPageState();
}

class _FileEditionPageState extends State<FileEditionPage> {
  static const _platform = MethodChannel('com.example.chat_app/channel');

  @override
  void didChangeDependencies() {
    FocusManager.instance.primaryFocus?.unfocus();
    super.didChangeDependencies();
  }

  Future<void> _sendMessage() async {
    final file = widget.files.first;

    /// Dejamos el file con el mismo nombre
    final filename = file.path.split('/').last;

    final path = '/${AppFolder.sentDirectory}/$filename';

    file.copySync(path);

    final mime = lookupMimeType(filename) ?? 'image/jpg';

    if(mime.startsWith('video')){
      await VideoThumbnail.thumbnailFile(
        video: path,
        thumbnailPath: AppFolder.thumbnailsDirectory,
        imageFormat: ImageFormat.PNG,
        maxWidth: 600,
        quality: 100
      );
    } else if(mime.endsWith('pdf')) {
      final document = await PdfDocument.openFile(file.path);
      final page = await document.getPage(1);

      /// Default ext jpeg, pero se adaptan todos a png
      final pageImage = await page.render(
        width: page.width, 
        height: page.height,
        format: PdfPageImageFormat.png
      );
      
      Future.wait<void>(<Future<void>>[
        page.close(),
        document.close(),
      ]);

      if(pageImage != null){
        final newFilename = '${filename.split('.')[0]}.png';
        final thumbail = File('${AppFolder.thumbnailsDirectory}/$newFilename');
        thumbail.writeAsBytesSync(pageImage.bytes);
      }
    }

    int? duration;

    try {
      duration = await _platform.invokeMethod<int>('getDuration', {'path': file.path});
    } on PlatformException catch(_) {
      debugPrint('File dont have duration property');
    } 

    final chat = context.read<ChatMessageProvider>();

    chat.message["file"] = filename;
    chat.message["duration"] = duration;

    context.read<MessagesService>().sendMessage(chat.message);
    chat.clearMessage();

    int count = 0;
    Navigator.of(context).popUntil((_) => count++ == 1);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ///---------------------------------------
          /// IMAGES FILE
          ///---------------------------------------
          PageView.builder(
            itemCount: widget.files.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final file = widget.files[index];
             
              return _FileThumbnail(file: file);
            } 
          ),
    
          ///---------------------------------------
          /// OPTIONS
          ///---------------------------------------
          Column(
            children: [
              const MediaEditionHeader(
                title: 'File edition',
              ),
              
              const Spacer(),
              
              MediaEditionFooter(
                hintText: 'File description',
                onSend: _sendMessage,
              )
            ],
          )
        ],
      )
    );
  }
}

class _FileThumbnail extends StatefulWidget {
  final File file;

  const _FileThumbnail({Key? key, required this.file}) : super(key: key);

  @override
  State<_FileThumbnail> createState() => __FileThumbnailState();
}

class __FileThumbnailState extends State<_FileThumbnail> with AutomaticKeepAliveClientMixin {
  late String _basename;
  late String _mime;
  late IconData _icon;

  bool _loading = true;
  ImageProvider<Object>? _image;

  @override
  void initState() {
    super.initState();

    _basename = widget.file.path.split('/').last;
    _mime = lookupMimeType(_basename) ?? 'image/jpg';

    final type = _mime.split('/')[0];

    _icon = mimeTypeToIconDataMap[type] ?? mimeTypeToIconDataMap[_mime] ?? FontAwesomeIcons.file;

    if(_mime.startsWith('image')){
      _loading = false;
      _image = Image.file(widget.file).image;
    } else {
      _loadThumbnail(_mime);
    }
  }

  Future<void> _loadThumbnail(String mime) async {
    if(mime.startsWith('video')){
      final path = await VideoThumbnail.thumbnailFile(
        video: widget.file.path, 
        quality: 100,
        maxWidth: 600,
        maxHeight: 500
      );

      _image = Image.file(File(path!)).image;
    } else if(mime.endsWith('pdf')) {
      final document = await PdfDocument.openFile(widget.file.path);
      final page = await document.getPage(1);

      /// Default ext jpeg
      final pageImage = await page.render(width: page.width, height: page.height);
      
      Future.wait<void>(<Future<void>>[
        page.close(),
        document.close(),
      ]);

      _image = Image.memory(pageImage!.bytes).image;
    }

    setState(() => _loading = false);
  }

  static const _style = TextStyle(
    color: Colors.white,
    fontSize: 16
  );

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final MediaQueryData mq = MediaQuery.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: mq.padding.top),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(_icon, color: Colors.white),
              
              const SizedBox(width: 15.0),
              
              Flexible(
                child: Text(
                  _basename,
                  style: _style,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            ],
          ),

          const SizedBox(height: 15.0),

          ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: mq.size.height * 0.5, 
              maxHeight: mq.size.height * 0.6
            ),
            child: Builder(
              builder: (context) {
                if(_loading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                if(_image == null){
                  return Center(
                    child: FaIcon(_icon, color: Colors.white, size: 80),
                  );
                }

                return Image(
                  image: _image!,
                  fit: BoxFit.contain,
                );
              },
            ),
          )
        ],
      ),
    );
  }
  
  @override
  bool get wantKeepAlive => true;
}