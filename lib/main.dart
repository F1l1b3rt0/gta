import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/environment.dart';
import 'services/language_service.dart';
import 'services/notification_service.dart';
import 'services/theme_notifier.dart';
import 'views/auth/login_view.dart';
import 'views/empleado/empleado_home_view.dart';
import 'views/gerente/gerente_home_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Environment.init();

  await Supabase.initialize(
    url: Environment.supabaseUrl,
    anonKey: Environment.supabaseAnonKey,
  );

  if (!kIsWeb) await NotificationService().init();

  final languageService = await LanguageService.create();
  final themeNotifier = await ThemeNotifier.create();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<LanguageService>.value(value: languageService),
        ChangeNotifierProvider<ThemeNotifier>.value(value: themeNotifier),
      ],
      child: const GTAApp(),
    ),
  );
}

class GTAApp extends StatelessWidget {
  const GTAApp({super.key});

  @override
  Widget build(BuildContext context) {
    final langService = context.watch<LanguageService>();
    final themeNotifier = context.watch<ThemeNotifier>();
    return MaterialApp(
      title: 'GTA - Gestión de Turnos',
      debugShowCheckedModeBanner: false,
      locale: langService.locale,
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: themeNotifier.themeData,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      return FutureBuilder(
        future: Supabase.instance.client
            .from('empleados')
            .select('rol')
            .eq('id', session.user.id)
            .maybeSingle(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData && snapshot.data != null) {
            if (snapshot.data!['rol'] == 'gerente') {
              return const GerenteHomeView();
            }
          }
          return const EmpleadoHomeView();
        },
      );
    }
    return const LoginView();
  }
}
