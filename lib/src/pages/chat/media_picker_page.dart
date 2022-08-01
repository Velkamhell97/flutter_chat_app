import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:typed_data';

import '../../widgets/transitions/page_routes.dart';
import 'chat.dart';

class MediaPickerPage extends StatefulWidget {
  const MediaPickerPage({Key? key}) : super(key: key);

  @override
  State<MediaPickerPage> createState() => _MediaPickerPageState();
}

class _MediaPickerPageState extends State<MediaPickerPage> {
  late final List<AssetPathEntity> _albums;

  final DraggableScrollableController _controller = DraggableScrollableController();
  final List<Future<Uint8List?>> _futuresList = [];
  final List<AssetEntity> _mediaList = [];
  final Map<int, int> _selected = {};
  final List<Uint8List> _thumbnails = [];

  int _currentPage = 0;
  int _lastPage = 0;
  bool _fetching = false;
  bool _multiple = false;
  bool _closing = false;

  static const _debounce = Duration(milliseconds: 50);
  static const _round = 30;

  @override
  void initState() {
    super.initState();

    _fetchAlbums();

    _controller.addListener(_listener);
  }

  @override
  void didChangeDependencies() {
    FocusManager.instance.primaryFocus?.unfocus();
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _listener() {
    if(_controller.size < 0.3 && !_closing){
      _closing = true;
      Future.delayed(_debounce, () => Navigator.of(context).pop());
    }
  }

  Future<void> _fetchAlbums() async {
    final permission = await PhotoManager.requestPermissionExtend();

    if(permission.isAuth) {
      _albums = await PhotoManager.getAssetPathList(onlyAll: true);

      _lastPage = (_albums[0].assetCount / _round).ceil();

      _fetchMedia();
    } else {
      debugPrint("Permissions Denied");
    }
  }

  Future<void> _fetchMedia() async {
    if(_currentPage == _lastPage) return;

    _fetching = true;

    final media = await _albums[0].getAssetListPaged(page: _currentPage, size: _round);

    final futures = media.map((e) => e.thumbnailDataWithSize(const ThumbnailSize.square(500))).toList();

    _fetching = false;

    setState(() {
      _futuresList.addAll(futures);
      _mediaList.addAll(media);
      _currentPage++;
    });
  }

  void _onSelected(int index, Uint8List bytes) {
    /// Si esta seleccionado, se elimina los media y los thumbnail, sino, los agrega
    if(_selected.keys.contains(index)){
      final value = _selected[index]!;

      _selected.remove(index);
      _thumbnails.removeAt(value - 1);

      /// Si queda vacio se limpian las listas
      if(_selected.isEmpty){
        setState(() {
          _selected.clear();
          _thumbnails.clear();
          _multiple = false;
        });

        return;
      }

      for(MapEntry<int, int> entry in  _selected.entries) {
        /// Cando quitamos un elemento las numeraciones superiores se reducen en 1
        if(entry.value > value) {
          _selected[entry.key] = entry.value - 1;
        }
      }

      setState(() {});
    } else {
      _selected[index] = _selected.length + 1;
      _thumbnails.add(bytes);

      setState(() {});
    }
  }

  /// Si hay un error se elimina este elemento
  void onError(int index) {
    _mediaList.removeAt(index);
    _futuresList.removeAt(index);
    
    setState(() {});
  }

  bool _onNotification(ScrollNotification scroll) {
    /// Si el scroll esta cerca del final y no se esta haciendo peticion carga mas
    if (scroll.metrics.pixels / scroll.metrics.maxScrollExtent > 0.33 && !_fetching) {
      _fetchMedia();
    }

    return true;
  }

  void _sendOne(AssetEntity asset, Uint8List bytes) {
    Widget child;

    if(asset.type == AssetType.image) {
      child = ImageEditionPage(
        bytes: bytes, 
        asset: asset,
      );
    } else {
      child = VideoEditionPage(
        bytes: bytes,
        asset: asset,
      );
    }

    final route = FadeInRouteBuilder(child: child);

    Navigator.of(context).push(route);
  }

  void _sendMultiple() {
    List<AssetEntity> assets = [];

    for(int index in _selected.keys){
      assets.add(_mediaList[index]);
    }

    final route = FadeInRouteBuilder(
      child: MediaEditionPage(
        thumbnails: _thumbnails,
        assets: assets,
      ),
    );

    Navigator.of(context).push(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: NotificationListener<ScrollNotification>(
          onNotification: _onNotification,
          child: DraggableScrollableSheet(
            controller: _controller,
            builder: (context, scrollController){
              return DecoratedBox(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12.0))
                ),
                child: Stack(
                  children: [
                    ///---------------------------------------
                    /// MEDIA LIST
                    ///---------------------------------------
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: GridView.builder(
                          padding: EdgeInsets.zero,
                          controller: scrollController,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                          ),
                          itemCount: _mediaList.length,
                          itemBuilder: (context, index) {
                            final future = _futuresList[index];
                            final asset = _mediaList[index];
                                    
                            return _MediaAsset(
                              future: future, 
                              asset: asset,
                              consecutive: _selected[index],
                              onError: () => onError(index),
                              onLongPress: (bytes) {
                                if(!_multiple) {
                                  setState(() => _multiple = true);
                                  _onSelected(index, bytes);
                                }
                              },
                              onSelected: (bytes) async {
                                if(_multiple){
                                  _onSelected(index, bytes);
                                } else {
                                  _sendOne(asset, bytes);
                                }
                              },
                            );
                          }
                        ),
                      ),
                    ),
    
                    ///---------------------------------------
                    /// MULTIPLE SEND BUTTON
                    ///---------------------------------------
                    Positioned(
                      right: 25,
                      bottom: 16,
                      child: AnimatedScale(
                        scale: _multiple ? 1.0 : 0.0,
                        duration: kThemeAnimationDuration,
                        curve: Curves.bounceInOut,
                        child: Material(
                          clipBehavior: Clip.antiAlias,
                          shape: const CircleBorder(),
                          color: Colors.blue,
                          child: IconButton(
                            padding: const EdgeInsets.all(15.0),
                            color: Colors.white,
                            icon: const Icon(Icons.send),
                            onPressed: _sendMultiple,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MediaAsset extends StatelessWidget {
  final Future<Uint8List?> future;
  final AssetEntity asset;
  final int? consecutive;
  final Function(Uint8List thumbBytes) onLongPress;
  final Function(Uint8List thumbBytes) onSelected;
  final VoidCallback onError;

  const _MediaAsset({
    Key? key,
    required this.future,
    required this.asset,
    this.consecutive,
    required this.onLongPress,
    required this.onSelected,
    required this.onError
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: future,
      builder: (context, snapshot) {
        if(snapshot.connectionState == ConnectionState.waiting){
          return const SizedBox();
        }

        if(!snapshot.hasData) {
          Future.microtask(onError);
          return const SizedBox();
        }

        final bytes = snapshot.data!;
        final fit = asset.width > asset.height ? BoxFit.fitHeight : BoxFit.fitWidth;

        return GestureDetector(
          onLongPress: () => onLongPress(bytes),
          onTap: () => onSelected(bytes),
          child: Hero(
            tag: asset.id,
            createRectTween: (begin, end) => RectTween(begin: begin, end: end),
            placeholderBuilder: (_, __, ___) => const DecoratedBox(decoration: BoxDecoration(color: Colors.black)),
            flightShuttleBuilder: (_, animation, direction, from, to) {
              ///Para hacer una transicion del fill de aqui y el fit del edition page (util)
              if(direction == HeroFlightDirection.push) return to.widget;
              return Image.memory(bytes, fit: fit);
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                ///---------------------------------------
                /// THUMNAIL
                ///---------------------------------------
                Image.memory(
                  bytes,
                  fit: BoxFit.cover,
                ),
                  
                ///---------------------------------------
                /// CONSECUTIVE BADGE
                ///---------------------------------------
                if(consecutive != null)
                  Align(
                    alignment: const Alignment(0.9, -0.9),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2
                        ),
                        color: Colors.blue
                      ),
                      child: SizedBox.square(
                        dimension: 24,
                        child: Padding(
                          padding: const EdgeInsets.all(3.0),
                          child: FittedBox(
                            child: Text(
                              '$consecutive',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                ///---------------------------------------
                /// VIDEO ICON
                ///---------------------------------------
                if(asset.type == AssetType.video)
                  const Align(
                    alignment: Alignment(0.9,0.95),
                    child: Icon(
                      Icons.videocam, 
                      color: Colors.white, 
                      shadows: [
                        Shadow(
                          color: Colors.black38,
                          blurRadius: 10
                        )
                      ],
                    ),
                  )
              ],
            ),
          ),
        );
      }
    );
  }
}