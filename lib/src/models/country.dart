class Country {
  final String name;
  final String code;
  final String iso2;

  const Country({required this.name, required this.code, required this.iso2});

  factory Country.fromJson(Map<String, dynamic> json) => Country(
    name: json["name"], 
    code: json["code"], 
    iso2: json["iso2"]
  );
}