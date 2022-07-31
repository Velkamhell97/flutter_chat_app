import '../models/models.dart';

class User {
  final String uid;
  final String? name;
  final String? email;
  final String? phone;
  final String? avatar;
  final String? token;
  final AuthMethod method;
  final bool verified;
  bool online;
  final bool google;
  Map<String, int> unreads;
  Map<String, String> latest;
  // Map<String, NotificationTile> pendings;

  // List<NotificationTile> get tiles => pendings.values.toList();

  User({
    required this.uid,
    this.name,
    this.email,
    this.phone,
    this.avatar,
    this.token,
    this.method = AuthMethod.email,
    this.verified = false,
    this.online = false,
    this.google = false,
    this.unreads = const {},
    this.latest = const {},
    // this.pendings = const {}
  });

  // void updatePendings(Map<String, dynamic> json) {
  //   final entries = Map<String, dynamic>.from(json).entries;
  //   pendings = {for(MapEntry<String, dynamic> entry in entries) entry.key: NotificationTile.fromJson(entry.value)};
  // }

  /// Para facilitar comparaciones
  @override
  int get hashCode => Object.hash(uid, email);

  @override
  bool operator ==(dynamic other) {
    return other is User && other.uid == uid;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    // final entries = Map<String, dynamic>.from(json["pendings"]).entries;
    // print(json);

    return User(
      uid: json["uid"],
      name: json["name"],
      email: json["email"],
      phone: json["phone"],
      avatar: json["avatar"],
      method: AuthMethod.values.byName(json["method"] ?? "email"),
      verified: json["verified"] ?? false,
      online: json["online"] ?? false,
      google: json["google"] ?? false,
      unreads: Map<String, int>.from(json["unreads"] ?? {}),
      latest: Map<String, String>.from(json["latest"] ?? {}),
      // pendings: {for(MapEntry<String, dynamic> entry in entries) entry.key: NotificationTile.fromJson(entry.value)}
    );
  }

  @override
  String toString() {
    return """User(
 uid: $uid, 
 name: $name, 
 email: $email, 
 phone: $phone 
 avatar: $avatar, 
 method: $method, 
 verified: $verified, 
 online: $online, 
 google: $google
)""";
  }
}