import 'package:intl/intl.dart';

import '../singlentons/sp.dart';

String generateFileName(String prefix, String ext){
  final _prefs = SP();

  final fileId = _prefs.fileId;

  final date = DateFormat('yyyyMMdd').format(DateTime.now());
  final fileName = '$prefix-$date-$fileId.$ext';

  _prefs.fileId = fileId + 1;
  return fileName;
}



