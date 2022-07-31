import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/app_enums.dart';

/// Se podria crear como una clase singlenton pero se opto por una static
class Environment {
  static String getFileName(EnvironmentMode mode){
    switch(mode){
      case EnvironmentMode.production:
        return '.env.production';
      case EnvironmentMode.development:
        return '.env.development';
    }
  }

  static String get apiHost => dotenv.env['API_HOST']!;
}



