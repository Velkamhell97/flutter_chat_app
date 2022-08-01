import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'dart:io';

import '../models/models.dart';

/// Para precargar la lista de paises y no cargarlas en cada formulario con telefono, puede que no sea necesario
/// utilzar un singlenton para esta operacion se podria utilizar un loding en el widget, asi evitando el uso
/// de clases singlentons
class LocalesService {
  LocalesService._internal();

  static final LocalesService _instance = LocalesService._internal();

  factory LocalesService() => _instance;

  late final List<Country> countries;
  late final List<ListItem> grouped;
  late final Country? country;

  static const abc = ['A','B','C','D','E','F','G','H','I','J','K','L','M','N','S','T','U','V','W','X','Y','Z'];

  Future<void> init() async {
    final data = await rootBundle.loadString('assets/data/countries.json');

    final list = json.decode(data) ;

    countries = List.from(list.map((country) => Country.fromJson(country)));

    /// Deben hacerse pruebas, este al parecer devuelve el iso del pais del telefono
    final code = Platform.localeName.substring(3,5);

    ///Se utiliza este porque el singleWhere lanza una excepcion al no encontrar match,
    ///tambien se puede usar el indexWhere para no evalutar todos
    final matches = countries.where((c) => c.iso2 == code);

    if(matches.isEmpty) {
      country = null;
    } else {
      country = matches.elementAt(0);
    }

    List<ListItem> sections = List.from(countries.map((c) => CountryItem(c)));

    int total = 0;

    for (var i = 0; i < abc.length; i++) {
      final sublist = countries.where((c) => c.name[0] == abc[i]);

      if(sublist.isNotEmpty){
        total += sublist.length;
        /// Como la lista va creciendo con la insercion debe tener en cuent esto
        sections.insert(total - sublist.length + i, HeadingItem(abc[i]));
      }
    }

    grouped = sections;
  }
}