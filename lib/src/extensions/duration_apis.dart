extension DurationApis on Duration {
  String _toTwoDigits(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }

  String mmss() {
    String minutes = _toTwoDigits(inMinutes.remainder(60));
    String seconds = _toTwoDigits(inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}