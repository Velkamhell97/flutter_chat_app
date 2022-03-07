class User {
  //-Se colocan finales porque en esta app, no se podra actualizar la informacion del usuario
  //-pero si se necesitara, se deberian dejar sin el final
  final String name;
  final String email;
  final bool online;
  final Role role;
  final bool google;
  final String uid;
  Map<String, int> unread;

  User({
    required this.name,
    required this.email,
    required this.online,
    required this.role,
    required this.google,
    required this.uid,
    this.unread = const {}
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    name: json["name"],
    email: json["email"],
    online: json["online"],
    role: Role.fromJson(json["role"]),
    google: json["google"],
    uid: json["uid"],
    unread:  Map<String, int>.from(json["unread"])
  );

  //-No se necesita el metodo porque no se necesitara modificar el usuario
  // User copyWith({bool? online, String? email, String? name, String? uid}) {
  //   return User(
  //     online: online ?? this.online,
  //     email: email ?? this.email,
  //     name: name ?? this.name,
  //     uid: uid ?? this.uid
  //   );
  // }
}

class Role {
  final String id;
  final String name;

  const Role({
    required this.id,
    required this.name,
  });

  factory Role.fromJson(Map<String, dynamic> json) => Role(
    id: json["_id"],
    name: json["name"],
  );
}