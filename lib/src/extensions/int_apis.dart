import 'dart:math' as math;

extension IntApis on int {
  static const sizes = ['Bytes', 'KB', 'MB'];

  String formatBytes() {
    if(this == 0) return '0 Bytes';

    const k = 1024;
    const dm = 2;

    final i = (math.log(this) / math.log(k)).floor();
    final value = (this / math.pow(k,i)).toStringAsFixed(dm);

    return '$value ${sizes[i]}';
  }
}