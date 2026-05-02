import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppConstants {
  // Animaciones
  static const Duration animShort = Duration(milliseconds: 200);
  static const Duration animMedium = Duration(milliseconds: 500);
  static const Duration animLong = Duration(milliseconds: 800);
  
  // Tamaños
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusXLarge = 20.0;
  
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 20.0;
  static const double iconSizeLarge = 24.0;
  static const double iconSizeXLarge = 32.0;
  
  // Fuentes
  static const double fontSizeSmall = 11.0;
  static const double fontSizeMedium = 13.0;
  static const double fontSizeLarge = 16.0;
  static const double fontSizeXLarge = 20.0;
  static const double fontSizeXXLarge = 24.0;
  
  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration snackBarDuration = Duration(seconds: 3);
  
  // Límites
  static const int minPasswordLength = 6;
  static const int defaultMaxHorasDiarias = 8;
  static const int defaultMaxHorasSemanales = 40;
  static const double defaultSalarioMinimo = 50.0;
  
  // rutas de navegación
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeEmpleadoHome = '/empleado_home';
  static const String routeGerenteHome = '/gerente_home';
  static const String routeMiHorario = '/mi_horario';
  static const String routeMisHoras = '/mis_horas';
  static const String routeQRScanner = '/qr_scanner';
  static const String routeEmpleados = '/empleados';
  static const String routeGestionHorarios = '/gestion_horarios';
  static const String routeReportesNomina = '/reportes_nomina';
  static const String routeConfiguracion = '/configuracion';
  static const String routeAlertas = '/alertas';
  static const String routeEstadisticas = '/estadisticas';
}

// Roles de usuario
enum UserRole {
  empleado,
  gerente,
  none,
}

extension UserRoleExtension on UserRole {
  String get stringValue {
    switch (this) {
      case UserRole.empleado:
        return 'empleado';
      case UserRole.gerente:
        return 'gerente';
      case UserRole.none:
        return 'none';
    }
  }
  
  static UserRole fromString(String role) {
    switch (role) {
      case 'empleado':
        return UserRole.empleado;
      case 'gerente':
        return UserRole.gerente;
      default:
        return UserRole.none;
    }
  }
}

// Tipos de notificaciones
enum NotificationType {
  horasExtra,
  limiteSemanal,
  nuevoHorario,
  sistema,
}

extension NotificationTypeExtension on NotificationType {
  String get stringValue {
    switch (this) {
      case NotificationType.horasExtra:
        return 'horas_extra';
      case NotificationType.limiteSemanal:
        return 'limite_semanal';
      case NotificationType.nuevoHorario:
        return 'nuevo_horario';
      case NotificationType.sistema:
        return 'sistema';
    }
  }
  
  IconData get icon {
    switch (this) {
      case NotificationType.horasExtra:
        return Icons.timer_rounded;
      case NotificationType.limiteSemanal:
        return Icons.warning_amber_rounded;
      case NotificationType.nuevoHorario:
        return Icons.event_available_rounded;
      case NotificationType.sistema:
        return Icons.notifications_rounded;
    }
  }
  
  Color get color {
    switch (this) {
      case NotificationType.horasExtra:
        return AppColors.warning;
      case NotificationType.limiteSemanal:
        return AppColors.error;
      case NotificationType.nuevoHorario:
        return AppColors.success;
      case NotificationType.sistema:
        return AppColors.primary;
    }
  }
}