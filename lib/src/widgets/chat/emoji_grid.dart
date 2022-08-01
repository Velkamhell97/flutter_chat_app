// ignore_for_file: implementation_imports
import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:emoji_picker_flutter/src/category_emoji.dart';
// import 'package:sliver_tools/sliver_tools.dart';

class EmojiGrid extends EmojiPickerBuilder {
  EmojiGrid(Config config, EmojiViewState state, [Key? key]) : super(config, state, key: key);

  @override
  _EmojiGridState createState() => _EmojiGridState();
}

class _EmojiGridState extends State<EmojiGrid> {
  late final List<CategoryEmoji> _emojis;

  final _scrollController = ScrollController();
  final _categoryNotifier = ValueNotifier<int>(0);
  final _offsets = <double>[0];
  final _indices = <double, int>{};

  bool _animating = false;

  static const double _tileExtent = 100.0;
  static const double _headerExtent = 24.0;
  static const _headerStyle = TextStyle(color: Colors.white);

  @override
  void initState() {
    super.initState();

    _emojis = widget.state.categoryEmoji.skip(1).toList();

    /// Cada categoria se le suma el lenght + el header y obtenemos los puntos offset
    for (int i = 0; i < _emojis.length; i++) {
      final category = _emojis[i];
      final lenght = category.emoji.length;
      final tiles = (lenght / 4).ceil();

      ///Agreagamos el offset de cada categoria y luego el indice en el mapa
      _offsets.add(_offsets[i] + (tiles * _tileExtent) + _headerExtent);
      _indices[_offsets[i + 1]] = i;
    }

    _scrollController.addListener(() {
      if(!_animating) {
        final offset = _indices.keys.firstWhere((element) => _scrollController.offset < element);

        /// Si la categoria es diferente y no se esta animando, cambie de offset
        if(_categoryNotifier.value != _indices[offset] && !_animating){
          _categoryNotifier.value = _indices[offset]!;
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCategory(int index) {
    _animating = true;

    _categoryNotifier.value = index;

    _scrollController.animateTo(
      _offsets[index], 
      duration: const Duration(milliseconds: 500), 
      curve: Curves.easeOut
    ).then((_) => _animating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ///-----------------------------------
        /// CLOSE BUTTON
        ///-----------------------------------
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
          color: Colors.white
        ),

        ///-----------------------------------
        /// EMOJI LIST
        ///-----------------------------------
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 0.0),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              /// Para crear encabezados, duplicamos los elementos, no se sabe si es mas eficiente que 
              /// el MultiSliver
              slivers: List.generate((_emojis.length) * 2, (index) {
                final category = _emojis[index - (index / 2).ceil()];

                if(index.isEven){
                  final name = category.category.name;
                  final capitalize = name[0].toUpperCase() + name.substring(1);

                  return SliverToBoxAdapter(
                    child: SizedBox(
                      height: _headerExtent,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5.0),
                        child: FittedBox(
                          alignment: Alignment.centerLeft,
                          child: Text(capitalize, style: _headerStyle)
                        ),
                      )
                    ),
                  );
                } else {
                  final emojis = category.emoji;

                  return SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 20.0,
                      mainAxisExtent: _tileExtent,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (_, index) {
                        final emoji = emojis[index];
        
                        return GestureDetector(
                          onTap: () => Navigator.of(context).pop(emoji.emoji),
                          child: FittedBox(
                            child: Text(
                              emoji.emoji, 
                            ),
                          ),
                        );
                      },
                      childCount: emojis.length
                    )
                  );
                }
              }),
            ),
          ),
        ),

        ///-----------------------------------
        /// EMOJI CATEGORIES
        ///-----------------------------------
        Material(
          color: Colors.black54,
          child: ValueListenableBuilder<int>(
            valueListenable: _categoryNotifier,
            builder: (_, selected, __) {
              return Row(
                children: List.generate(_emojis.length, (index) {
                  final category = _emojis[index].category;
                  final active = index == selected;
                
                  return Expanded(
                    child: InkWell(
                      onTap: () => _scrollToCategory(index),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: active ? Colors.white24 : null,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Icon(
                            widget.config.getIconForCategory(category),
                            color: Colors.white,
                            size: 30.0,
                          ),
                        ),
                      ),
                    )
                  );
                }),
              );
            },
          ),
        )
      ],
    );
  }
}

// final category = _emojis[index];
// final name = category.category.name;
// final capitalize = name[0].toUpperCase() + name.substring(1);
//
// final emojis = category.emoji;
//
// return MultiSliver(
//   children: [
//     SliverToBoxAdapter(
//       child: SizedBox(
//         height: _headerExtent,
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 5.0),
//           child: FittedBox(
//             alignment: Alignment.centerLeft,
//             child: Text(capitalize, style: _headerStyle)
//           ),
//         )
//       ),
//     ),
//
//     SliverGrid(
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 4,
//         crossAxisSpacing: 20.0,
//         mainAxisExtent: _tileExtent
//       ),
//       delegate: SliverChildBuilderDelegate(
//         (_, index) {
//           final emoji = emojis[index];
//
//           return GestureDetector(
//             onTap: () => Navigator.of(context).pop(emoji.emoji),
//             child: FittedBox(
//               child: Text(
//                 emoji.emoji, 
//               ),
//             ),
//           );
//         },
//         childCount: emojis.length
//       )
//     ),
//   ]
// );