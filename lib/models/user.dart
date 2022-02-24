class User {
  //-Se colocan finales porque en esta app, no se podra actualizar la informacion del usuario
  //-pero si se necesitara, se deberian dejar sin el final
  final String name;
  final String email;
  final bool online;
  final Role role;
  final String uid;

  const User({
    required this.name,
    required this.email,
    required this.online,
    required this.role,
    required this.uid,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    name: json["name"],
    email: json["email"],
    online: json["online"],
    role: Role.fromJson(json["role"]),
    uid: json["uid"],
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

  static const List<User> test = [
    // User(online: true,  email: 'user1@gmail.com',  name: 'User 1',  role: Role(),  uid: '1'),
    // User(online: false, email: 'user2@gmail.com',  name: 'User 2',  role: Role(),  uid: '2'),
    // User(online: true,  email: 'user3@gmail.com',  name: 'User 3',  role: Role(),  uid: '3'),
    // User(online: false, email: 'user4@gmail.com',  name: 'User 4',  role: Role(),  uid: '4'),
    // User(online: true,  email: 'user5@gmail.com',  name: 'User 5',  role: Role(),  uid: '5'),
    // User(online: false, email: 'user6@gmail.com',  name: 'User 6',  role: Role(),  uid: '6'),
    // User(online: true,  email: 'user7@gmail.com',  name: 'User 7',  role: Role(),  uid: '7'),
    // User(online: false, email: 'user8@gmail.com',  name: 'User 8',  role: Role(),  uid: '8'),
    // User(online: true,  email: 'user9@gmail.com',  name: 'User 9',  role: Role(),  uid: '9'),
    // User(online: false, email: 'user10@gmail.com', name: 'User 10', uid: '10'),
  ];
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