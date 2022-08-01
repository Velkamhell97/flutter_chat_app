import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageRoute;
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'dart:typed_data';
import 'dart:io';
import 'dart:ui';

import '../../global/globals.dart';
import '../../providers/message_provider.dart';
import '../../services/messages_service.dart';
import '../../models/app_enums.dart';
import '../../widgets/chat/chat.dart';
import 'chat.dart';

class ImageEditionPage extends StatefulWidget {
  final Uint8List bytes;
  final XFile? xFile;
  final double? fitScale;
  final AssetEntity? asset;

  const ImageEditionPage({
    Key? key, 
    required this.bytes,
    this.xFile,
    this.fitScale,
    this.asset
  }) : super(key: key);

  @override
  State<ImageEditionPage> createState() => _ImageEditionPageState();
}

class _ImageEditionPageState extends State<ImageEditionPage> {
  /// Se usa un ImageProvider porque se utiliza image.memory y image.file, igualmente, como este se debe pasar
  /// a otras pantallas, no sirve inicializarlo dentro del widget, y si se crea un provider seria mas complicado
  /// porque este debe de ser global y se deberia reinicializar con cada pop de esta pagina
  late ValueNotifier<ImageProvider<Object>> _imageNotifier;
  
  late String _heroTag;
  
  /// El file que contiene el archivo original o modfificado
  late File _file;

  /// Como los emojis se seleccionan desde fuera de la imagen, toca pasarselos como argumentos
  /// por eso esto no puede ir dentro
  final _emojis = <String>[];

  /// Bytes de la imagne modificada
  Uint8List? _data;
  
  /// Para la animacion del header y footer al navegar
  bool _showOptions = true;

  static const _hideDuration = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();

    /// Ya sea de la camara o de la galeria empiezan con bytes
    final image = Image.memory(widget.bytes).image;
    _imageNotifier = ValueNotifier(image);

    if(widget.asset != null){
      _loadAsset();
    } else {
      _file = File(widget.xFile!.path);
    }

    /// Para no sobrecargar el cache con el image, al parecer no necesita el WidgetBinding, se puede aplicar
    /// en otros lugares como al volver de la pantalla del chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // if(PaintingBinding.instance.imageCache.currentSize > 50 * 1024 * 1024){
      //   PaintingBinding.instance.imageCache.clear();
      //   PaintingBinding.instance.imageCache.clearLiveImages();
      // }
    });

    _heroTag = widget.asset == null ? 'camera' : widget.asset!.id;
  }

  @override
  void dispose() {
    _imageNotifier.dispose();
    super.dispose();
  }

  /// Como la imagen se controla desde afuera (ValueNotifier) este metodo no puede ir dentro del widget
  /// porque se necesita compartir con otras paginas, ademas se necesitar extraer el file, para enviar
  /// el mensaje, se tendrian que crear callbacks dentro del widget
  Future<void> _loadAsset() async {
    final file = await widget.asset!.file;

    if(file == null) return;

    _file = file;

    final image = Image.file(file).image;

    if(!mounted) return;

    await precacheImage(image, context);

    _imageNotifier.value = image;
  }

  Future<String?> _showEmojiModal() async {
    /// Para dialogs personalizados ya usamos el showGeneralDialog normal
    final emoji = showGeneralDialog<String?>(
      context: context,
      barrierColor: Colors.transparent, 
      pageBuilder: (context, animation, _) {
        return Material(
          type: MaterialType.transparency,
          child: SafeArea(
            child: EmojiPicker(
              onEmojiSelected: (category, emoji) { /* ...*/ },
              customWidget: (config, state) => EmojiGrid(config, state),
            ),
          ),
        );
      },
      transitionBuilder: (_, animation, __, child){
        final sigma = animation.value * 3;

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: FadeTransition(
            opacity: animation,
            child: child
          ),
        );
      }
    );

    return emoji;
  }

  Future<void> _onEditionAction(EditionType type) async {
    if(type == EditionType.emoji) {
      final emoji = await _showEmojiModal();

      if(emoji != null){
        setState(() => _emojis.add(emoji));
      }
    } else {
      CupertinoPageRoute<Uint8List> route;

      if(type == EditionType.crop){
        route = CupertinoPageRoute(
          builder: (_) => ImageCropPage(
            imageNotifier: _imageNotifier,
            heroTag: _heroTag,
          )
        );
      } else {
        route = CupertinoPageRoute(
          builder: (_) => ImagePaintPage(
            imageNotifier: _imageNotifier,
            heroTag: _heroTag,
          )
        );
      }

      setState(() => _showOptions = false);

      ///Se mira el efecto del slide antes de hacer la navegacion            
      Future.delayed(_hideDuration, () {
        /// Si se edita la imagen devuelve los bits, ya que el obtejo es un ImageProvider
        Navigator.of(context).push<Uint8List>(route).then((bytes) {
          setState(() => _showOptions = true);
          _data = bytes;
        });
      });
    }
  }

  Future<void> _sendMessage() async {
    final ext = _file.path.split('/').last.split('.').last;
    final filename = generateFileName('IMAGE', ext);

    final path = '/${AppFolder.sentDirectory}/$filename';

    _file.copySync(path);

    if(_data != null) {
      File(path).writeAsBytesSync(_data!);
    }

    final chat = context.read<MessageProvider>();
    
    chat.message["image"] = filename;

    context.read<MessagesService>().sendMessage(chat.message);
    chat.clearMessage();

    int count = 0;
    Navigator.of(context).popUntil((_) => count++ == 2);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final chat = context.read<MessageProvider>();

        if(chat.showEmojis) {
          chat.showEmojis = false;
          chat.notify();
          return false;
        } else {
          return true;
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            ///---------------------------------------
            /// IMAGE FILE
            ///---------------------------------------
            ValueListenableBuilder<ImageProvider>(
              valueListenable: _imageNotifier,
              builder: (_, image, __) {
                return MediaImage(
                  image: image,
                  emojis: _emojis,
                  fitScale: widget.fitScale,
                  heroTag: _heroTag,
                  // onEmojiChanged: (image, bytes) {
                  //   print('entre');
                  //   _data = bytes;
                  // },
                );
              },
            ),
              
            ///---------------------------------------
            /// HEADER
            ///---------------------------------------
            AnimatedSlide(
              offset: Offset(0.0, _showOptions ? 0.0 : -1.0),
              duration: _hideDuration,
              child: Hero(
                tag: 'header',
                child: MediaEditionHeader(
                  title: 'Edit Image',
                  onCrop: () => _onEditionAction(EditionType.crop),
                  onPaint: () => _onEditionAction(EditionType.paint),
                  onEmoji: () => _onEditionAction(EditionType.emoji),
                ),
              ),
            ),

            ///---------------------------------------
            /// FOOTER
            ///---------------------------------------
            Positioned.fill(
              top: null,
              child: AnimatedSlide(
                offset: Offset(0.0, _showOptions ? 0.0 : 1.0),
                duration: _hideDuration,
                child: Hero(
                  tag: 'footer',
                  child: Material(
                    type: MaterialType.transparency,
                    child: MediaEditionFooter(
                      hintText: 'Image description',
                      onSend: _sendMessage,
                    ),
                  )
                )
              ),
            ),
          ],
        ),
      ),
    );
  }
}