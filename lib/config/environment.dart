import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  static Future<void> init() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // .env no encontrado — se usarán --dart-define o defaults
    }
  }

  // Lee de dotenv de forma segura (no lanza si no está inicializado)
  static String? _get(String key) {
    try {
      return dotenv.maybeGet(key);
    } catch (_) {
      return null;
    }
  }

  static String get supabaseUrl {
    const defined = String.fromEnvironment('SUPABASE_URL');
    if (defined.isNotEmpty) return defined;
    final url = _get('SUPABASE_URL');
    if (url == null || url.isEmpty) throw Exception('SUPABASE_URL no está configurada');
    return url;
  }

  static String get supabaseAnonKey {
    const defined = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (defined.isNotEmpty) return defined;
    final key = _get('SUPABASE_ANON_KEY');
    if (key == null || key.isEmpty) throw Exception('SUPABASE_ANON_KEY no está configurada');
    return key;
  }

  static String get appName => _get('APP_NAME') ?? 'GTA';
  static String get appVersion => _get('APP_VERSION') ?? '1.0.0';
  static String get appEnvironment => _get('APP_ENVIRONMENT') ?? 'development';

  static double get defaultLatitude {
    final lat = _get('LOCATION_LAT_DEFAULT');
    return lat != null ? double.tryParse(lat) ?? 19.432608 : 19.432608;
  }

  static double get defaultLongitude {
    final lon = _get('LOCATION_LON_DEFAULT');
    return lon != null ? double.tryParse(lon) ?? -99.133209 : -99.133209;
  }

  static double get defaultRadius {
    final radius = _get('LOCATION_RADIUS_DEFAULT');
    return radius != null ? double.tryParse(radius) ?? 100.0 : 100.0;
  }

  static String get timezone => _get('TIMEZONE') ?? 'America/Mexico_City';

  static int get defaultHoursDay {
    final hours = _get('DEFAULT_HOURS_DAY');
    return hours != null ? int.tryParse(hours) ?? 8 : 8;
  }

  static int get defaultHoursWeek {
    final hours = _get('DEFAULT_HOURS_WEEK');
    return hours != null ? int.tryParse(hours) ?? 40 : 40;
  }

  static bool get isProduction => appEnvironment.toLowerCase() == 'production';
  static bool get isDevelopment => appEnvironment.toLowerCase() == 'development';

  static String get anthropicApiKey {
    const defined = String.fromEnvironment('ANTHROPIC_API_KEY');
    if (defined.isNotEmpty) return defined;
    final key = _get('ANTHROPIC_API_KEY');
    if (key == null || key.isEmpty) throw Exception('ANTHROPIC_API_KEY no está configurada');
    return key;
  }
}
