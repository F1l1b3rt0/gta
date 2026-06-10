import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'language_service.dart';

/// Translate inline. Call ONLY inside build() — uses context.watch for reactivity.
/// Usage: tr(context, 'Español', 'English')
String tr(BuildContext context, String es, String en) {
  final lang = context.watch<LanguageService>().languageCode;
  return lang == 'en' ? en : es;
}

/// Non-reactive version for use outside build() (callbacks, etc.)
String trStatic(BuildContext context, String es, String en) {
  final lang = context.read<LanguageService>().languageCode;
  return lang == 'en' ? en : es;
}
