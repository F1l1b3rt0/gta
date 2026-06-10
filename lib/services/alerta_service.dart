import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../config/supabase_config.dart';

class AlertaService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  AlertaService() {
    if (!kIsWeb) _inicializarNotificaciones();
  }

  Future<void> _inicializarNotificaciones() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);
    await _notifications.initialize(settings);
  }

  Future<void> _mostrarNotificacion(
      int id, String titulo, String cuerpo) async {
    if (kIsWeb) return;
    await _notifications.show(
      id,
      titulo,
      cuerpo,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'gta_channel',
          'Alertas GTA',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<void> enviarAlertaHorasExtras(
      String empleadoId, double horasTrabajadas) async {
    final empleado = await _supabase
        .from('empleados')
        .select('nombre, max_horas_diarias')
        .eq('id', empleadoId)
        .single();

    final maxHoras = empleado['max_horas_diarias'] ?? 8;

    if (horasTrabajadas > maxHoras) {
      await _mostrarNotificacion(
        1,
        '⚠️ Alerta de Horas Extra',
        '${empleado['nombre']} ha trabajado $horasTrabajadas horas (límite: $maxHoras)',
      );

      await _supabase.from('alertas').insert({
        'empleado_id': empleadoId,
        'tipo': 'horas_extra',
        'mensaje': 'Ha trabajado $horasTrabajadas horas',
        'fecha': DateTime.now().toIso8601String(),
        'leida': false,
      });
    }
  }

  Future<void> notificarNuevoHorario(
    String empleadoId,
    DateTime dia,
    DateTime entrada,
    DateTime salida,
  ) async {
    final empleado = await _supabase
        .from('empleados')
        .select('nombre')
        .eq('id', empleadoId)
        .single();

    await _mostrarNotificacion(
      2,
      '📅 Nuevo Horario Asignado',
      '${empleado['nombre']}, tienes turno el ${_formatDate(dia)} de ${_formatTime(entrada)} a ${_formatTime(salida)}',
    );
  }

  Future<void> verificarLimiteSemanal(String empleadoId) async {
    final inicioSemana = DateTime.now()
        .subtract(Duration(days: DateTime.now().weekday - 1));
    final turnos = await _supabase
        .from('turnos')
        .select()
        .eq('empleado_id', empleadoId)
        .gte('entrada', inicioSemana.toIso8601String())
        .not('salida', 'is', null);

    double totalHoras = 0;
    for (var turno in turnos) {
      final entrada = DateTime.parse(turno['entrada']);
      final salida = DateTime.parse(turno['salida']);
      totalHoras += salida.difference(entrada).inHours;
    }

    final empleado = await _supabase
        .from('empleados')
        .select('max_horas_semanales, nombre')
        .eq('id', empleadoId)
        .single();

    final maxSemanal = empleado['max_horas_semanales'] ?? 40;

    if (totalHoras > maxSemanal * 0.9) {
      await _mostrarNotificacion(
        3,
        '⚠️ Límite Semanal Cercano',
        '${empleado['nombre']} ha acumulado $totalHoras horas esta semana (límite: $maxSemanal)',
      );
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';

  String _formatTime(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}
