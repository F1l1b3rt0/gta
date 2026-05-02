import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../config/supabase_config.dart';

class AlertaService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  AlertaService() {
    _inicializarNotificaciones();
  }
  
  Future<void> _inicializarNotificaciones() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );
    
    await _notifications.initialize(settings);
  }
  
  // Enviar alerta de horas extra
  Future<void> enviarAlertaHorasExtras(String empleadoId, double horasTrabajadas) async {
    final empleado = await _supabase
        .from('empleados')
        .select('nombre, max_horas_diarias')
        .eq('id', empleadoId)
        .single();
    
    final maxHoras = empleado['max_horas_diarias'] ?? 8;
    
    if (horasTrabajadas > maxHoras) {
      // Notificación local
      await _notifications.show(
        1,
        '⚠️ Alerta de Horas Extra',
        '${empleado['nombre']} ha trabajado $horasTrabajadas horas (límite: $maxHoras)',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'horas_extra_channel',
            'Alertas de Horas Extra',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
      
      // Guardar alerta en BD
      await _supabase.from('alertas').insert({
        'empleado_id': empleadoId,
        'tipo': 'horas_extra',
        'mensaje': 'Ha trabajado $horasTrabajadas horas',
        'fecha': DateTime.now().toIso8601String(),
        'leida': false,
      });
    }
  }
  
  // Notificar nuevo horario
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
    
    await _notifications.show(
        2,
        '📅 Nuevo Horario Asignado',
        '${empleado['nombre']}, tienes turno el ${_formatDate(dia)} de ${_formatTime(entrada)} a ${_formatTime(salida)}',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'horarios_channel',
            'Nuevos Horarios',
            importance: Importance.high,
          ),
        ),
      );
  }
  
  // Verificar límites semanales
  Future<void> verificarLimiteSemanal(String empleadoId) async {
    final inicioSemana = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
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
    
    if (totalHoras > maxSemanal * 0.9) { // Alerta al 90%
      await _notifications.show(
        3,
        '⚠️ Límite Semanal Cercano',
        '${empleado['nombre']} has acumulado $totalHoras horas esta semana (límite: $maxSemanal)',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'limite_semanal_channel',
            'Límite de Horas Semanal',
            importance: Importance.high,
          ),
        ),
      );
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}