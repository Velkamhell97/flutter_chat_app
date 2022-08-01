import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import 'dart:io';
import 'dart:ui';

import '../../global/constants.dart';
import '../../global/helpers.dart';
import '../../providers/message_provider.dart';
import '../../services/messages_service.dart';
import '../../widgets/chat/chat.dart';

class MediaEditionPage extends StatefulWidget {
  final List<Uint8List> thumbnails;
  final List<AssetEntity> assets;

  const MediaEditionPage({
    Key? key, 
    required this.thumbnails,
    required this.assets
  }) : super(key: key);

  @override
  State<MediaEditionPage> createState() => _MediaEditionPageState();
}

class _MediaEditionPageState extends State<MediaEditionPage> {
  /// Por si se quisiera que cada uno tuviera sus modificaciones y sus emojis
  final Map<int, ValueNotifier<ImageProvider<Object>>> _imageNotifiers = {};
  final Map<int, List<String>> _imageEmojis = {};
  
  late final List<File?> _files;
  /// Copia que tendra el mismo length y orden que el files
  late final List<AssetEntity> _assets;

  final Map<int, int> _durations = {};

  int _page = 0;

  @override
  void initState() {
    super.initState();

    _files = List.filled(widget.assets.length, null);
    _assets = widget.assets;

    final List<AssetEntity> images = [];

    for (int i = 0; i < widget.assets.length; i++) {
      final asset = widget.assets[i];

      if(asset.type == AssetType.image){
        images.add(asset);
        final image = Image.memory(widget.thumbnails[i]).image;
        
        _imageNotifiers[i] = ValueNotifier<ImageProvider<Object>>(image);
        _imageEmojis[i] = [];
      } else {
        _durations[i] = asset.videoDuration.inMilliseconds;

        /// Se ejecuta mas rapido no necesidad de agruparlos en un future.wait
        _loadAssetsVideos(asset, i);
      }
    }

    Future.wait(
      List.generate(images.length, (index) => _loadAssetsImage(images[index], index))
    );
  }

  @override
  void dispose() {
    for (ValueNotifier<ImageProvider<Object>> notifier in _imageNotifiers.values) {
      notifier.dispose();
    }

    super.dispose();
  }

  Future<void> _loadAssetsImage(AssetEntity asset, int index) async {
    final file = await asset.file;

    if(file == null) {
      _files.removeAt(index);
      _assets.removeAt(index);
      return;
    }

    _files[index] = file;

    final image = Image.file(file).image;

    if(!mounted) return;

    await precacheImage(image, context);

    _imageNotifiers[index]!.value = image;
  }

  Future<void> _loadAssetsVideos(AssetEntity asset, int index) async {
    final file = await asset.file;

    if(file == null) {
      _files.removeAt(index);
      _assets.removeAt(index);
      return;
    }

    _files[index] = file;
  }

  Future<String?> _showEmojiModal() async {
    final emoji = await showGeneralDialog<String?>(
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

  Future<void> _sendMessage() async {
    final chat = context.read<MessageProvider>();
    final lenght = _files.length;

    final List<Map<String, dynamic>> messages = List.generate(lenght, (_) => {...chat.message});

    for (int i = 0; i < lenght; i++) {
      final asset = _assets[i];
      final file = _files[i];

      final prefix = asset.type == AssetType.image ? 'IMAGE' : 'VIDEO';
      final ext = asset.title!.split('.').last;

      final filename = generateFileName(prefix, ext);

      final path = '/${AppFolder.sentDirectory}/$filename';

      file!.copySync(path);

      if(asset.type == AssetType.image) {
        /// Para cuando se modifican las imagener
        // if(_data != null) {
        //   File(path).writeAsBytesSync(_data!);
        // }

        messages[i]["image"] = filename;
      } else {
        await VideoThumbnail.thumbnailFile(
          video: path,
          thumbnailPath: AppFolder.thumbnailsDirectory,
          imageFormat: ImageFormat.PNG,
          maxWidth: 600,
          quality: 100
        );

        messages[i]["video"] = filename;
        messages[i]["duration"] = _durations[i];
      }
    }

    context.read<MessagesService>().sendMessages(messages);
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
            /// IMAGES FILE
            ///---------------------------------------
            PageView.builder(
              itemCount: widget.assets.length,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (page) => _page = page,
              ///Precarga la siguiente pagina cuando esta en la presente
              allowImplicitScrolling: true,
              itemBuilder: (context, index) {
                final asset = widget.assets[index];
                final thumbnail = widget.thumbnails[index];
    
                if(asset.type == AssetType.image){
                  return Center(
                    child: ValueListenableBuilder<ImageProvider<Object>>(
                      valueListenable: _imageNotifiers[index]!,
                      builder: (_, image, __) {
                        return MediaImage(
                          image: image,
                          emojis: _imageEmojis[index]!,
                        );
                      },
                    ),
                  );
                } else {
                  return MediaVideo(
                    bytes: thumbnail,
                    asset: asset,
                  );
                }
              }
            ),
      
            ///---------------------------------------
            /// OPTIONS (TAMBIEN FUNCIONA CON EL STACK)
            ///---------------------------------------
            Column(
              children: [
                ///---------------------------------------
                /// HEADER
                ///---------------------------------------
                MediaEditionHeader(
                  title: 'Media edition',
                  onEmoji: () async {
                    if(!_imageEmojis.keys.contains(_page)){
                      return;
                    }
    
                    final emoji = await _showEmojiModal();
      
                    if(emoji != null){
                      setState(() {
                        _imageEmojis[_page]!.add(emoji);
                      });
                    }
                  }
                ),
      
                ///---------------------------------------
                /// SPACING
                ///---------------------------------------
                const Spacer(),
                
                ///---------------------------------------
                /// FOOTER
                ///---------------------------------------
                MediaEditionFooter(
                  hintText: 'Media description',
                  onSend: _sendMessage,
                )
              ],
            )
          ],
        )
      ),
    );
  }
}