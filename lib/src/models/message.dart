class Message {
  String? id;
  String from;
  String to;
  String? text;
  String? time;
  String? image;
  String? audio;
  String? tempUrl;
  bool read;

  Message({this.id, required this.from, required this.to, this.text, this.time, this.image, this.audio, this.tempUrl, this.read = false});

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json["_id"],
    from: json["from"],
    to: json["to"],
    text: json["text"],
    time: json["time"],
    image: json["image"],
    audio: json["audio"],
    tempUrl: json["tempUrl"],
    read: json["read"]
  );

  Message copyWith({String? text, String? image, String? audio, String? tempUrl}) => Message(
    id: id,
    from: from, 
    to: to, 
    text: text ?? this.text, 
    time: time,
    image: image ?? this.image,
    audio: audio ?? this.audio,
    tempUrl: tempUrl ?? this.tempUrl,
    read: read
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'from': from,
    'to': to,
    'text': text,
    'time': time,
    'image': image,
    'audio': audio,
    'tempUrl': tempUrl,
    'read': read
  };
}