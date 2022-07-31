import 'package:flutter/material.dart';

import '../../models/models.dart';

class CountriesList extends StatefulWidget {
  final List<Country> countries;
  final List<ListItem> grouped;
  final ValueChanged<Country> onCountryChanged;

  const CountriesList({Key? key, required this.countries, required this.grouped, required this.onCountryChanged}) : super(key: key);

  @override
  State<CountriesList> createState() => _CountriesListState();
}

class _CountriesListState extends State<CountriesList> {
  late final ValueNotifier<List<ListItem>> _contriesNotifier;

  @override
  void initState() {
    super.initState();
    _contriesNotifier = ValueNotifier<List<ListItem>>(widget.grouped);
  }

  void _onChanged(String value) {
    if (value.isEmpty) {
      _contriesNotifier.value = widget.grouped;
      return;
    }

    final matches = widget.countries.where((c) {
      return c.name.toLowerCase().startsWith(value.toLowerCase());
    });

    _contriesNotifier.value = List.from(matches.map((c) => CountryItem(c)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ///------------------------------
        /// Close BottomSheet Chip
        ///------------------------------
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: DecoratedBox(
              decoration: ShapeDecoration(color: Colors.grey.shade300, shape: const StadiumBorder()),
              child: const SizedBox(
                width: 60,
                height: 8,
              ),
            ),
          ),
        ),

        ///------------------------------
        /// Search Textfield
        ///------------------------------
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Search', filled: true, suffixIcon: Icon(Icons.search)),
            onChanged: _onChanged,
          ),
        ),

        ///------------------------------
        /// Countries List
        ///------------------------------
        Expanded(
          child: ValueListenableBuilder<List<ListItem>>(
            valueListenable: _contriesNotifier,
            builder: (context, countries, __) {
              return ListView.builder(
                itemCount: countries.length,
                itemBuilder: (context, index) {
                  final item = countries[index];

                  /// 1 forma de crear una lista con diferentes elementos en este caso headers
                  /// en otras ocasiones el child cambia mucho con respecto a otro y se utiliza ternario (no se)
                  return ListTile(
                    title: item.buildTitle(context),
                    leading: item.buildLeading(context),
                    trailing: item.buildTrailing(context),
                    onTap: () {
                      if (item is CountryItem) {
                        widget.onCountryChanged(item.country);
                      }
                    },
                  );
                }
              );
            },
          ),
        )
      ],
    );
  }
}
