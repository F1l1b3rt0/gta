import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  static Future<void> init() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // Si no se encuentra .env, se usarán los valores de --dart-define o defaults
    }
  }

  static String get supabaseUrl {
    const defined = String.fromEnvironment('SUPABASE_URL');
    if (defined.isNotEmpty) return defined;
    final url = dotenv.maybeGet('SUPABASE_URL');
    if (url == null || url.isEmpty) throw Exception('SUPABASE_URL no está configurada');
    return url;
  }

  static String get supabaseAnonKey {
    const defined = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (defined.isNotEmpty) return defined;
    final key = dotenv.maybeGet('SUPABASE_ANON_KEY');
    if (key == null || key.isEmpty) throw Exception('SUPABASE_ANON_KEY no está configurada');
    return key;
  }

  static String get appName => dotenv.maybeGet('APP_NAME') ?? 'GTA';

  static String get appVersion => dotenv.maybeGet('APP_VERSION') ?? '1.0.0';

  static String get appEnvironment => dotenv.maybeGet('APP_ENVIRONMENT') ?? 'development';

  static double get defaultLatitude {
    final lat = dotenv.maybeGet('LOCATION_LAT_DEFAULT');
    return lat != null ? double.tryParse(lat) ?? 19.432608 : 19.432608;
  }

  static double get defaultLongitude {
    final lon = dotenv.maybeGet('LOCATION_LON_DEFAULT');
    return lon != null ? double.tryParse(lon) ?? -99.133209 : -99.133209;
  }

  static double get defaultRadius {
    final radius = dotenv.maybeGet('LOCATION_RADIUS_DEFAULT');
    return radius != null ? double.tryParse(radius) ?? 100.0 : 100.0;
  }

  static String get timezone => dotenv.maybeGet('TIMEZONE') ?? 'America/Mexico_City';

  static int get defaultHoursDay {
    final hours = dotenv.maybeGet('DEFAULT_HOURS_DAY');
    return hours != null ? int.tryParse(hours) ?? 8 : 8;
  }

  static int get defaultHoursWeek {
    final hours = dotenv.maybeGet('DEFAULT_HOURS_WEEK');
    return hours != null ? int.tryParse(hours) ?? 40 : 40;
  }

  static bool get isProduction => appEnvironment.toLowerCase() == 'production';

  static bool get isDevelopment => appEnvironment.toLowerCase() == 'development';

  static String get anthropicApiKey {
    const defined = String.fromEnvironment('ANTHROPIC_API_KEY');
    if (defined.isNotEmpty) return defined;
    final key = dotenv.maybeGet('ANTHROPIC_API_KEY');
    if (key == null || key.isEmpty) throw Exception('ANTHROPIC_API_KEY no está configurada');
    return key;
  }
}
