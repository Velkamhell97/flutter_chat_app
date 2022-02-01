class User {
  final bool online;
  final String email;
  final String name;
  final String uid;

  const User({
    required this.online, 
    required this.email, 
    required this.name, 
    required this.uid
  });

  User copyWith({bool? online, String? email, String? name, String? uid}) {
    return User(
      online: online ?? this.online,
      email: email ?? this.email,
      name: name ?? this.name,
      uid: uid ?? this.uid
    );
  }

  static const List<User> test = [
    User(online: true,  email: 'user1@gmail.com',  name: 'User 1',  uid: '1'),
    User(online: false, email: 'user2@gmail.com',  name: 'User 2',  uid: '2'),
    User(online: true,  email: 'user3@gmail.com',  name: 'User 3',  uid: '3'),
    User(online: false, email: 'user4@gmail.com',  name: 'User 4',  uid: '4'),
    User(online: true,  email: 'user5@gmail.com',  name: 'User 5',  uid: '5'),
    User(online: false, email: 'user6@gmail.com',  name: 'User 6',  uid: '6'),
    User(online: true,  email: 'user7@gmail.com',  name: 'User 7',  uid: '7'),
    User(online: false, email: 'user8@gmail.com',  name: 'User 8',  uid: '8'),
    User(online: true,  email: 'user9@gmail.com',  name: 'User 9',  uid: '9'),
    User(online: false, email: 'user10@gmail.com', name: 'User 10', uid: '10'),
  ];

}