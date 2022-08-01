import 'package:flutter/material.dart';

import '../styles/styles.dart';
import '../models/country.dart';

/// Implementacion propuesta por el cookbook de flutter, tambien se podria haber hecho una condicion
/// para devolver un widget u otro
abstract class ListItem {
  const ListItem();

  Widget buildTitle(BuildContext context);

  Widget? buildSubtitle(BuildContext context);

  Widget? buildLeading(BuildContext context);

  Widget? buildTrailing(BuildContext context);
}

class HeadingItem extends ListItem {
  final String heading;

  const HeadingItem(this.heading);

  @override
  Widget buildTitle(BuildContext context) {
    return Text(heading, style: TextStyles.sectionHeader);
  }

  @override
  Widget? buildSubtitle(BuildContext context) {
    return null;
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return null;
  }

  @override
  Widget? buildTrailing(BuildContext context) {
    return null;
  }
}

class CountryItem extends ListItem {
  final Country country;

  const CountryItem(this.country);

  @override
  Widget buildTitle(BuildContext context) {
    return Text(country.name);
  }

  @override
  Widget? buildSubtitle(BuildContext context) {
    return null;
  }

  @override
  Widget? buildLeading(BuildContext context) {
    final flag = country.iso2.toLowerCase();
    /// Se podria usar un AspectRatio para manejar una realcion de aspecto
    return SizedBox(
      height: 25,
      width: 35,
      /// Por alguna razon con svg da problemas
      // child: SvgPicture.asset('assets/flags/$flag.svg')
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3.0),
        child: Image.asset(
          'assets/flags/$flag.png',
          fit: BoxFit.cover,
        )
      ),
    );
  }

  @override
  Widget? buildTrailing(BuildContext context) {
    return Text(country.code);
  }
}