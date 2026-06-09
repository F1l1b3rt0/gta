import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  // Inicializar entorno
  static Future<void> init() async {
    await dotenv.load(fileName: '.env');
  }

  // Getters para Supabase
  static String get supabaseUrl {
    final url = dotenv.env['SUPABASE_URL'];
    if (url == null) {
      throw Exception('SUPABASE_URL no está configurada');
    }
    return url;
  }

  static String get supabaseAnonKey {
    final key = dotenv.env['SUPABASE_ANON_KEY'];
    if (key == null) {
      throw Exception('SUPABASE_ANON_KEY no está configurada');
    }
    return key;
  }

  // App configuration
  static String get appName {
    return dotenv.env['APP_NAME'] ?? 'GTA';
  }

  static String get appVersion {
    return dotenv.env['APP_VERSION'] ?? '1.0.0';
  }

  static String get appEnvironment {
    return dotenv.env['APP_ENVIRONMENT'] ?? 'development';
  }

  // Location configuration
  static double get defaultLatitude {
    final lat = dotenv.env['LOCATION_LAT_DEFAULT'];
    if (lat == null) {
      return 19.432608; // Valor por defecto
    }
    return double.parse(lat);
  }

  static double get defaultLongitude {
    final lon = dotenv.env['LOCATION_LON_DEFAULT'];
    if (lon == null) {
      return -99.133209; // Valor por defecto
    }
    return double.parse(lon);
  }

  static double get defaultRadius {
    final radius = dotenv.env['LOCATION_RADIUS_DEFAULT'];
    if (radius == null) {
      return 100.0; // Valor por defecto
    }
    return double.parse(radius);
  }

  // Time configuration
  static String get timezone {
    return dotenv.env['TIMEZONE'] ?? 'America/Mexico_City';
  }

  static int get defaultHoursDay {
    final hours = dotenv.env['DEFAULT_HOURS_DAY'];
    if (hours == null) {
      return 8;
    }
    return int.parse(hours);
  }

  static int get defaultHoursWeek {
    final hours = dotenv.env['DEFAULT_HOURS_WEEK'];
    if (hours == null) {
      return 40;
    }
    return int.parse(hours);
  }

  // Validar si está en producción
  static bool get isProduction {
    return appEnvironment.toLowerCase() == 'production';
  }

  static bool get isDevelopment {
    return appEnvironment.toLowerCase() == 'development';
  }

  static String get anthropicApiKey {
    final key = dotenv.env['ANTHROPIC_API_KEY'];
    if (key == null) {
      throw Exception('ANTHROPIC_API_KEY no está configurada');
    }
    return key;
  }
}
