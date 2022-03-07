
import 'package:intl/intl.dart';

import 'sp.dart';

class Helpers {
  static final _prefs = SP();
  
  static String generateFileName(String prefix, String ext){
    final fileId = _prefs.fileId;

    final date = DateFormat('yyyyMMdd').format(DateTime.now());
    final fileName = '$prefix-$date-$fileId.$ext';

    _prefs.fileId = fileId + 1;
    return fileName;
  }
}