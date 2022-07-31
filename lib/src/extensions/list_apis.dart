import 'dart:math' as math;

extension ListApis<T extends num> on List<T> {
  T max() => reduce(math.max<T>);
  T min() => reduce(math.min<T>);

  List<double> normalize() => map<double>((n) => (n - min()) / (max() - min())).toList();
}