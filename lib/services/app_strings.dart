import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'language_service.dart';

class AppStrings {
  final String lang;
  const AppStrings(this.lang);

  // Acceso rápido desde un BuildContext
  static AppStrings of(BuildContext context) =>
      AppStrings(context.watch<LanguageService>().languageCode);

  // ── Generales ──────────────────────────────────────────────────────────────
  bool get _en => lang == 'en';
  String get cancel => _en ? 'Cancel' : 'Cancelar';
  String get save => _en ? 'Save' : 'Guardar';
  String get close => _en ? 'Close' : 'Cerrar';
  String get logout => _en ? 'Log Out' : 'Cerrar Sesión';
  String get logoutTitle => _en ? 'Log Out' : 'Cerrar Sesión';
  String get logoutBody =>
      _en ? 'Are you sure you want to log out?' : '¿Estás seguro de que deseas cerrar sesión?';
  String get exit => _en ? 'Exit' : 'Salir';

  // ── Home empleado ───────────────────────────────────────────────────────────
  String get welcome => _en ? 'Welcome' : 'Bienvenido';
  String get myProfile => _en ? 'My Profile' : 'Mi Perfil';
  String get mySchedule => _en ? 'My Schedule' : 'Mi Horario';
  String get myHours => _en ? 'My Hours' : 'Mis Horas';
  String get chat => 'Chat';
  String get settings => _en ? 'Settings' : 'Configuración';

  // ── Chat ────────────────────────────────────────────────────────────────────
  String get teamChat => _en ? 'Team Chat' : 'Chat del Equipo';
  String get noMessages => _en ? 'No messages' : 'Sin mensajes';
  String get beFirst =>
      _en ? 'Be the first to write' : 'Sé el primero en escribir';
  String get typeMessage =>
      _en ? 'Write a message...' : 'Escribe un mensaje...';
  String get editMessage => _en ? 'Edit message' : 'Editar mensaje';
  String get deleteMessage => _en ? 'Delete message' : 'Eliminar mensaje';
  String get deleteConfirm => _en
      ? 'Are you sure you want to delete this message?'
      : '¿Estás seguro de que quieres eliminar este mensaje?';
  String get messageEdited => _en ? 'Message edited' : 'Mensaje editado';
  String get messageDeleted => _en ? 'Message deleted' : 'Mensaje eliminado';
  String get edited => _en ? 'edited' : 'editado';
  String messagesCount(int n) => _en ? '$n messages' : '$n mensajes';

  // ── Configuración ──────────────────────────────────────────────────────────
  String get configuration => _en ? 'Settings' : 'Configuración';
  String get appearance => _en ? 'Appearance' : 'Apariencia';
  String get theme => _en ? 'Theme' : 'Tema';
  String get themeLight => _en ? 'Light' : 'Claro';
  String get themeDark => _en ? 'Dark' : 'Oscuro';
  String get notifications => _en ? 'Notifications' : 'Notificaciones';
  String get pushNotifications =>
      _en ? 'Push Notifications' : 'Notificaciones Push';
  String get pushSubtitle =>
      _en ? 'Receive system alerts' : 'Recibir alertas del sistema';
  String get sound => _en ? 'Sound' : 'Sonido';
  String get soundSubtitle =>
      _en ? 'Play sound on notifications' : 'Reproducir sonido en notificaciones';
  String get vibration => _en ? 'Vibration' : 'Vibración';
  String get vibrationSubtitle =>
      _en ? 'Vibrate on notifications' : 'Vibrar al recibir notificaciones';
  String get preferences => _en ? 'Preferences' : 'Preferencias';
  String get language => _en ? 'Language' : 'Idioma';
  String get currentLangLabel => _en ? 'English' : 'Español';
  String get selectLanguage =>
      _en ? 'Select Language' : 'Seleccionar Idioma';
  String get spanish => _en ? 'Spanish' : 'Español';
  String get english => 'English';
  String get information => _en ? 'Information' : 'Información';
  String get aboutGta => _en ? 'About GTA' : 'Acerca de GTA';
  String get version => _en ? 'Version' : 'Versión';
  String get privacyPolicy => _en ? 'Privacy Policy' : 'Política de Privacidad';
  String get privacySubtitle =>
      _en ? 'View terms and conditions' : 'Ver términos y condiciones';
  // ── Mi Horario ─────────────────────────────────────────────────────────────
  String get myScheduleTitle => _en ? 'My Schedule' : 'Mi Horario';
  String get weekOf => _en ? 'Week of' : 'Semana del';
  String get noShiftsWeek => _en ? 'No shifts this week' : 'Sin turnos esta semana';
  String get noShiftsAssigned => _en ? 'No shifts assigned' : 'No tienes horarios asignados';
  String shiftsCount(int n) => _en ? '$n shift${n != 1 ? 's' : ''} this week' : '$n turno${n != 1 ? 's' : ''} esta semana';
  String get entryTime => _en ? 'Entry' : 'Entrada';
  String get exitTime => _en ? 'Exit' : 'Salida';
  String hoursCount(double h) => _en ? '${h.toStringAsFixed(1)} hours' : '${h.toStringAsFixed(1)} horas';

  // ── Mis Horas ──────────────────────────────────────────────────────────────
  String get myHoursTitle => _en ? 'My Hours' : 'Mis Horas';
  String get normalHours => _en ? 'Normal hours' : 'Horas normales';
  String get extraHours => _en ? 'Extra hours' : 'Horas extra';
  String get estimatedPay => _en ? 'Est. pay' : 'Pago estimado';
  String get month => _en ? 'Month' : 'Mes';
  String get week => _en ? 'Week' : 'Semana';
  String get year => _en ? 'Year' : 'Año';
  String get noHoursRecorded => _en ? 'No hours recorded' : 'Sin horas registradas';
  String get noHoursInPeriod => _en ? 'No worked hours in this period' : 'No hay horas trabajadas en este período';
  String get extra => _en ? 'Extra' : 'Extra';
  String get normal => _en ? 'Normal' : 'Normal';

  String get themeChanged =>
      _en ? '✓ Theme changed' : '✓ Tema cambiado correctamente';
  String languageChanged(String name) =>
      _en ? '✓ Language changed to $name' : '✓ Idioma cambiado a $name';
  String get privacyText => _en
      ? 'GTA is committed to protecting your privacy. Your personal data is used solely for schedule and attendance management. We do not share your information with third parties without your consent.\n\nYour data is protected with the highest security standards.'
      : 'GTA se compromete a proteger tu privacidad. Tus datos personales son utilizados únicamente para la gestión de horarios y asistencia. No compartimos tu información con terceros sin tu consentimiento.\n\nTus datos están protegidos con los más altos estándares de seguridad.';
}
