import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'dart:io';

import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../styles/styles.dart';
import '../../extensions/extensions.dart';
import '../../pages/chat/chat.dart';
import '../transitions/transitions.dart';
import '../widgets.dart';

class ChatMessage extends StatelessWidget {
  final Message message;
  final bool lastOut;
  final bool lastIn;

  const ChatMessage({
    Key? key, 
    required this.message, 
    this.lastOut = false,
    this.lastIn = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final _message = message;

    return Align(
      alignment: _message.sender ? Alignment.centerRight : Alignment.centerLeft,
      child: CustomPaint(
        painter: _message.sender 
          ? OutcomingMessagePainter(showTail: lastOut) 
          : IncomingMessagePainter(showTail: lastIn),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: size.width * 0.8,
            maxHeight: size.height * 0.35
          ),
          child: Builder(
            builder: (context) {
              if(_message.unsent){
                return Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: _TextMessageWidget(
                    text: 'Message sending failed',
                    textStyle: TextStyles.messageUnsent,
                    child: _MessageStatus(message: _message),
                  ),
                );
              }

              if(_message is TextMessage){
                return Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: _TextMessageWidget(
                    text: _message.text,
                    textStyle: TextStyles.messageSent,
                    child: _MessageStatus(message: _message),
                  ),
                );
              }

              if(_message is MediaMessage){
                return _MediaMessageWidget(
                  message: _message,
                );
              }
             
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}

class _IconData {
  final IconData icon;
  final Color color;

  const _IconData(this.icon, this.color);
}

class _MessageStatus extends StatelessWidget {
  final Message message;
  final bool transparent;
  final EdgeInsetsGeometry padding;

  const _MessageStatus({
    Key? key, 
    required this.message, 
    this.transparent = true,
    this.padding = EdgeInsets.zero
  }) : super(key: key);

  static const _iconSize = 12.0;
  static const Map<MessageStatus, _IconData> _icons = {
    MessageStatus.unsent : _IconData(Icons.access_time_outlined, ChatTheme.check),
    MessageStatus.sent : _IconData(Icons.done, ChatTheme.check),
    MessageStatus.received: _IconData(Icons.done_all, ChatTheme.check),
    MessageStatus.read : _IconData(Icons.done_all, Colors.blue)
  };

  @override
  Widget build(BuildContext context) {
    final style = transparent ? TextStyles.messageTime : TextStyles.messageTimeWhite;
    final color = (!transparent && message.status != MessageStatus.read) ? Colors.white : _icons[message.status]!.color;
    final icon = _icons[message.status]!.icon;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: transparent ? null : Colors.black38,
        borderRadius: BorderRadius.circular(20.0)
      ),
      child: Padding(
        padding: padding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message.time, style: style),

            (!message.sender)
              ? const SizedBox.shrink()
              : Icon(icon, size: _iconSize, color: color)
          ],
        ),
      ),
    );
  }
}


class _TextMessageWidget extends SingleChildRenderObjectWidget {
  /// Al parecer algunas variables se definen como propiedades, el child y key solo como argumento
  final String text;
  final TextStyle? textStyle;
  final double? spacing;
  
  const _TextMessageWidget({
    Key? key,
    required this.text,
    this.textStyle,
    // ignore: unused_element
    this.spacing,
    required Widget child,
  }) : super(key: key, child: child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderTextMessageWidget(text, textStyle, spacing);
  }

  @override
  void updateRenderObject(BuildContext context, _RenderTextMessageWidget renderObject) {
    renderObject
      ..text = text
      ..textStyle = textStyle
      ..spacing = spacing;
  }
}

class _RenderTextMessageWidget extends RenderBox with RenderObjectWithChildMixin<RenderBox> {
  /// En el render ya no se utiliza el final todo se setea como propiedad cambiante y privada, con getter y setter
  String _text;
  TextStyle? _textStyle;
  double? _spacing;

  // With this constants you can modify the final result
  static const double _kOffset = 1.5;
  static const double _kFactor = 0.8;

  _RenderTextMessageWidget(
    String text,
    TextStyle? textStyle, 
    double? spacing
  ) : _text = text, _textStyle = textStyle, _spacing = spacing;

  String get text => _text;
  set text(String value) {
    if (_text == value) return;
    _text = value;
    markNeedsLayout();
  }

  TextStyle? get textStyle => _textStyle;
  set textStyle(TextStyle? value) {
    if (_textStyle == value) return;
    _textStyle = value;
    markNeedsLayout();
  }

  double? get spacing => _spacing;
  set spacing(double? value) {
    if (_spacing == value) return;
    _spacing = value;
    markNeedsLayout();
  }

  TextPainter textPainter = TextPainter();

  @override
  void performLayout() {
    size = _performLayout(constraints: constraints, dry: false);

    final BoxParentData childParentData = child!.parentData as BoxParentData;
  
    /// Aqui asigna la posicion del child
    childParentData.offset = Offset(
      size.width - child!.size.width, 
      size.height - child!.size.height / _kOffset
    );
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return _performLayout(constraints: constraints, dry: true);
  }

  Size _performLayout({required BoxConstraints constraints, required bool dry}) {
    textPainter = TextPainter(
      text: TextSpan(text: _text, style: _textStyle),
      textDirection: TextDirection.ltr
    );

    late final double spacing;

    if(_spacing == null){
      spacing = constraints.maxWidth * 0.03;
    } else {
      spacing = _spacing!;
    }

    textPainter.layout(minWidth: 0, maxWidth: constraints.maxWidth);

    double height = textPainter.height;
    double width = textPainter.width;
    
    // Compute the LineMetrics of our textPainter
    final List<LineMetrics> lines = textPainter.computeLineMetrics();
    
    // We are only interested in the last line's width
    final lastLineWidth = lines.last.width;

    if(child != null){
      late final Size childSize;
    
      if (!dry) {
        child!.layout(BoxConstraints(maxWidth: constraints.maxWidth), parentUsesSize: true);
        childSize = child!.size;
      } else {
        childSize = child!.getDryLayout(BoxConstraints(maxWidth: constraints.maxWidth));
      }

      if(lastLineWidth + spacing > constraints.maxWidth - child!.size.width) {
        height += (childSize.height * _kFactor);
      } else if(lines.length == 1){
        width += childSize.width + spacing;
      }
    }

    return Size(width, height);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    ///El offset al parecer es la posicion local dentro de los constrains si se deja cero va al incio de la pnatalla
    textPainter.paint(context.canvas, offset);

    /// EL offset del parent es el setead en la parte de arriba del performLayout
    final parentData = child!.parentData as BoxParentData;
    context.paintChild(child!, offset + parentData.offset);
  }
}


class _MediaMessageWidget extends StatefulWidget {
  final MediaMessage message;

  const _MediaMessageWidget({
    Key? key,
    required this.message
  }) : super(key: key);

  @override
  State<_MediaMessageWidget> createState() => _MediaMessageWidgetState();
}

class _MediaMessageWidgetState extends State<_MediaMessageWidget> {
  bool _uploaded = false;
  bool _downloaded = false;
  // bool _loading = false;

  @override
  void initState() {
    super.initState();

    _uploaded = widget.message.tempUrl != null;
    _downloaded = widget.message.downloaded;

    if(!_uploaded){
      _uploadFile();
    }
  }

  Future<void> _uploadFile() async {
    // setState(() => _loading = true);

    final files = Provider.of<FilesService>(context, listen: false);
    final socket = Provider.of<SocketsService>(context, listen: false);
    final messages = Provider.of<MessagesService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);
    final users = Provider.of<UsersService>(context, listen: false);

    files.uploadFile(widget.message.filename).then((url) {
      if(url != null){
        final data = {'id': widget.message.id, 'name': auth.user!.name, 'url':url};

        socket.emitWithAck('media-uploaded', data, ack: (json) {
          if(mounted){
            messages.onMediaUpdated(widget.message.id, url);
            setState(() => _uploaded = true);
            // setState(() => _loading = false);

            auth.user!.latest[json["message"]["to"]] = json["last"];
            users.refresh(json["message"]["to"]);
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(files.error!.message))
        );
      }
    });
  }

  Future<void> _downloadFile() async {
    // setState(() => _loading = true);

    final files = Provider.of<FilesService>(context, listen: false);
    final socket = Provider.of<SocketsService>(context, listen: false);
    final messages = Provider.of<MessagesService>(context, listen: false);

    files.downloadFile(widget.message).then((error) {
      if(error == null){
        final data = {'id': widget.message.id};

        socket.emitWithAck('media-downloaded', data, ack: (json) {
          if(mounted){
            messages.onMediaDownloaded(widget.message.id);
            setState(() => _downloaded = true);
            // setState(() => _loading = false);
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message))
        );
      }
    });
  }

  static const _iconSize = 48.0;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final message = widget.message;

    return Builder(
      builder: (context) {
        if(message is FileMessage){
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 7.0, horizontal: 7.0),
            child: SizedBox(
              width: size.width * 0.6,
              child: _FileTile(
                message: message, 
                uploaded: _uploaded,
                upload: _uploadFile,
                downloaded: _downloaded,
                download: _downloadFile,
              ),
            ),
          );
        }

        if(message is AudioMessage) {
          return Padding(
            padding: const EdgeInsets.all(10.0),
            child: SizedBox(
              width: size.width * 0.6,
              height: _iconSize,
              child: _AudioTile(
                message: message, 
                uploaded: _uploaded,
                upload: _uploadFile,
                downloaded: _downloaded,
                download: _downloadFile,
              ),
            ),
          );
        } 

        /// Se podria usar solo un file
        final path = message.thumbnail!;

        return Padding(
          padding: const EdgeInsets.all(3.0),
          child: _MediaTile(
            mediaMessage: message, 
            image: Image.file(File(path)).image, 
            uploaded: _uploaded,
            upload: _uploadFile,
            downloaded: _downloaded,
            download: _downloadFile,
          ),
        );
      }
    );
  }
}

class _FileTile extends StatelessWidget {
  final FileMessage message;
  final bool uploaded;
  final bool downloaded;
  final VoidCallback upload;
  final VoidCallback download;

  const _FileTile({
    Key? key,
    required this.message,
    required this.uploaded,
    required this.downloaded,
    required this.upload,
    required this.download
  }) : super(key: key);

  void _openFile() {
    OpenFile.open(message.path);
  }

  @override
  Widget build(BuildContext context) {

    return Stack(
      children: [
        (!message.exist) 
          ? Row(
            children: const [
              Icon(Icons.error_outline, color: Colors.redAccent),
              SizedBox(width: 10),
              Text('File not found')
            ],
          ) 
          : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: uploaded ? _openFile : null,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 213, 238, 187),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(7.0),
                    child: Column(
                      children: [
                        if(message.thumbnail != null)
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: MediaQuery.of(context).size.height * 0.2
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 7.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12.0),
                                /// Se modifico la libreria para darle el aligntop
                                child: SizedBox(
                                  width: double.infinity,
                                  child: Image.file(
                                    File(message.thumbnail!),
                                    alignment: Alignment.topCenter,
                                    fit: BoxFit.fitWidth,
                                  ),
                                ),
                              ),
                            ),
                          ),
              
                        Row(
                          children: [
                            FaIcon(
                              message.icon ?? FontAwesomeIcons.file, 
                              color: const Color(0xff65B05B).withOpacity(0.7)
                            ),
                            
                            const SizedBox(width: 10.0),
                            
                            Expanded(
                              child: Text(message.filename, maxLines: 2, style: TextStyles.messageTime),
                            )
                          ],
                        ),
              
                        if(!uploaded)
                          const Padding(
                            padding: EdgeInsets.only(top: 5.0),
                            child: LinearProgressIndicator(
                              backgroundColor: Color(0xffBBE3AC), 
                              color: Color(0xff78C272)
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 5.0),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(message.bytes.formatBytes(), style: const TextStyle(fontSize: 12, color: Color(0xff65B05B))),
                    _MessageStatus(message: message)
                  ],
                ),
              )
            ],
          ),
      ],
    );
  }
}

class _AudioTile extends StatefulWidget {
  final AudioMessage message;
  final bool uploaded;
  final bool downloaded;
  final VoidCallback upload;
  final VoidCallback download;

  const _AudioTile({
    Key? key,
    required this.message,
    required this.uploaded,
    required this.downloaded,
    required this.upload,
    required this.download
  }) : super(key: key);

  @override
  State<_AudioTile> createState() => __AudioTileState();
}

class __AudioTileState extends State<_AudioTile> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final String _time;

  static const _duration = Duration(milliseconds: 300);

  AudioMessage get _message => widget.message;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);
    _time = Duration(milliseconds: widget.message.duration).mmss();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  void _tooglePlayer() {
    final player = context.read<AudioProvider>();
    player.toggle(_message.path, _message.id, _controller);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        (!_message.exist) 
          ? Row(
            children: const [
              Icon(Icons.error_outline, color: Colors.redAccent),
              SizedBox(width: 10),
              Text('Audio not found')
            ],
          ) 
          : Row(
            children: [
              Material(
                clipBehavior: Clip.antiAlias,
                shape: const CircleBorder(),
                color: const Color(0Xff78C272),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: _tooglePlayer,
                  color: Colors.white,
                  icon: widget.uploaded 
                    ? AnimatedIcon(icon: AnimatedIcons.play_pause, progress: _controller)
                    : const CircularProgressIndicator(color: Colors.white),
                ),
              ),
              
              const SizedBox(width: 10.0),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: FutureBuilder<List<dynamic>?>(
                        future: _message.waveform,
                        initialData: null,
                        builder: (_, snapshot) {
                          if(!snapshot.hasData){
                            return const Center(
                              child: LinearProgressIndicator(
                                backgroundColor: Color(0xffBBE3AC), 
                                color: Color(0xff78C272)
                              )
                            );
                          }

                          final samples = List<int>.from(snapshot.data!);

                          return SliderTheme(
                            data: SliderThemeData(
                              thumbShape: SliderComponentShape.noThumb,
                              trackShape: WaveTrackShape(
                                samples: samples.normalize(),
                                activeColor: const Color(0xff78C272), //66BB6A
                                inactiveColor: const Color(0xffBBE3AC) //C5E1A5
                              )
                            ),
                            child: Consumer<AudioProvider>(
                              builder: (_, player, __) {
                                final value = (player.progress.inMilliseconds / (_message.duration)).clamp(0.0, 1.0);
                                final playing = player.selected == _message.id;
                          
                                return Slider(
                                  value: playing ? value : 0.0,
                                  onChanged: (_) {},
                                );
                              }
                            ),
                          );
                        },
                      ),
                    ),
    
                    Text('$_time ●', style: const TextStyle(fontSize: 12, color: Color(0xff65B05B)))
                  ],
                ),
              )
            ],
          ),

        Positioned(
          bottom: 0,
          right: 7,
          child: _MessageStatus(message: _message),
        )
      ],
    );
  }
}

class _MediaTile extends StatelessWidget {
  final MediaMessage mediaMessage;
  final ImageProvider<Object> image;
  final bool uploaded;
  final bool downloaded;
  final VoidCallback upload;
  final VoidCallback download;

  const _MediaTile({
    Key? key,
    required this.mediaMessage,
    required this.image,
    required this.uploaded,
    required this.downloaded,
    required this.upload,
    required this.download
    
  }) : super(key: key);

  String getTime(int millis) => Duration(milliseconds: millis).mmss();

  void _onTap(MediaMessage message, BuildContext context) {
    if (!message.exist || !uploaded) return;

    ///Podria aplicarse solo para el video pero como es tan rapido se deja para la imagen
    image.resolve(const ImageConfiguration()).addListener(ImageStreamListener((ImageInfo info, bool _) { 
      final video = message is VideoMessage ? File(message.path) : null;
      final duration = message is VideoMessage ? message.duration : null;

      final size = Size(info.image.width.toDouble(), info.image.height.toDouble());

      final route = FadeInRouteBuilder(
        child: MediViewerPage(
          id: message.id,
          image: image,
          size: size,
          video: video,
          duration: duration,
        )
      );

      Navigator.of(context).push(route);
    }));
  }

  @override
  Widget build(BuildContext context) {
    final message = mediaMessage;

    return GestureDetector(
      onTap: () => _onTap(message, context),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Hero(
            tag: message.id,
            createRectTween: (begin, end) => RectTween(begin: begin, end: end),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: !message.exist
                ? Image.asset("assets/images/no-image.jpg")
                : Image(image: image)
            ),
          ),
    
          Positioned(
            bottom: 5.0,
            right: 5.0,
            child: _MessageStatus(
              message: message, 
              transparent: false,
              padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
            ),
          ),

          if(message is VideoMessage)
            const DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black38,
                shape: BoxShape.circle
              ),
              child: Padding(
                padding: EdgeInsets.all(5.0),
                child: Icon(Icons.play_arrow, color: Colors.white)
              )
            ),
          
          if(message is VideoMessage)
            Positioned(
              top: 5.0,
              right: 5.0,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.all(Radius.circular(10.0))
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.5),
                  child: Text(getTime(message.duration), style: TextStyles.messageTimeWhite)
                )
              ),
            ),

          if(!uploaded) 
            const CircularProgressIndicator(color: Colors.white),

          // if(!downloaded) 
          //   const CircularProgressIndicator(color: Colors.white),

          // if(!loading) 
          //   const CircularProgressIndicator(color: Colors.white)
        ],
      ),
    );
  }
}