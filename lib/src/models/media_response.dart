class MediaResponse {
  final int status;
  final String message;
  final String url;

  const MediaResponse({
    required this.status,
    required this.message,
    required this.url,
  });
   
  factory MediaResponse.fromJson(Map<String, dynamic> json) {
    return MediaResponse(
      status: json["status"],
      message: json["message"],
      url: json["payload"]["url"],
    );
  }
}
