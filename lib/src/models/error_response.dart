class ErrorResponse {
  final String error;
  final Details details;

  const ErrorResponse({
    required this.error,
    required this.details,
  });

  factory ErrorResponse.fromJson(Map<String, dynamic> json) => ErrorResponse(
    error: json["error"],
    details: Details.fromJson(json["details"]),
  );
}

class Details {
  final String msg;
  final String name;
  final int code;
  final String? extra;

  Details({
    required this.msg,
    required this.name,
    required this.code,
    required this.extra,
  });
  
  factory Details.fromJson(Map<String, dynamic> json) => Details(
    msg: json["msg"],
    name: json["name"],
    code: json["code"],
    extra: json["extra"],
  );
}
