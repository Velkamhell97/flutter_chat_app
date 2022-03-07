class ChatFileResponse {
  final String msg;
  final ChatFile file;

  ChatFileResponse({
    required this.msg,
    required this.file,
  });

  factory ChatFileResponse.fromJson(Map<String, dynamic> json) => ChatFileResponse(
    msg: json["msg"],
    file: ChatFile.fromJson(json["file"]),
  );
}

class ChatFile {
  final String assetId;
  final String publicId;
  final int version;
  final String versionId;
  final String signature;
  final int width;
  final int height;
  final String format;
  final String resourceType;
  final DateTime createdAt;
  final List<dynamic> tags;
  final int bytes;
  final String type;
  final String etag;
  final bool placeholder;
  final String url;
  final String secureUrl;
  final String accessMode;
  final String originalFilename;
  final String apiKey;

  const ChatFile({
    required this.assetId,
    required this.publicId,
    required this.version,
    required this.versionId,
    required this.signature,
    required this.width,
    required this.height,
    required this.format,
    required this.resourceType,
    required this.createdAt,
    required this.tags,
    required this.bytes,
    required this.type,
    required this.etag,
    required this.placeholder,
    required this.url,
    required this.secureUrl,
    required this.accessMode,
    required this.originalFilename,
    required this.apiKey,
  });
    
  factory ChatFile.fromJson(Map<String, dynamic> json) => ChatFile(
    assetId: json["asset_id"],
    publicId: json["public_id"],
    version: json["version"],
    versionId: json["version_id"],
    signature: json["signature"],
    width: json["width"],
    height: json["height"],
    format: json["format"],
    resourceType: json["resource_type"],
    createdAt: DateTime.parse(json["created_at"]),
    tags: List<dynamic>.from(json["tags"].map((x) => x)),
    bytes: json["bytes"],
    type: json["type"],
    etag: json["etag"],
    placeholder: json["placeholder"],
    url: json["url"],
    secureUrl: json["secure_url"],
    accessMode: json["access_mode"],
    originalFilename: json["original_filename"],
    apiKey: json["api_key"],
  );
}
