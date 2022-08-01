class NotificationTile {
  final String uid;
  final String name;
  final String? avatar;
  final List<String> last4;
  final String date;

  const NotificationTile({
    required this.uid, 
    required this.name,
    this.avatar,
    required this.last4,
    required this.date
  });

  factory NotificationTile.fromJson(Map<String, dynamic> json) {
    return NotificationTile(
      uid    : json["_id"], 
      name   : json["name"], 
      avatar : json["avatar"],
      last4  : List<String>.from(json["last4"]),
      date   : json["created"]
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "uid"    : uid,
      "name"   : name,
      "avatar" : avatar,
      "last4"  : last4,
      "date"   : date 
    };
  }
}