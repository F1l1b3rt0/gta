// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class AppColors {
  // Colores base
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF4F8FF);
  static const surfaceCard = Color(0xFFFFFFFF);
  
  // Azules principales
  static const primary = Color(0xFF1A6FE8);
  static const primaryLight = Color(0xFF4D96FF);
  static const primaryDark = Color(0xFF0D47A1);
  static const accent = Color(0xFF00CFFF);
  
  // Texto
  static const textPrimary = Color(0xFF0D1B3E);
  static const textSecondary = Color(0xFF6B80A3);
  static const textHint = Color(0xFF90B4D8);
  static const textMuted = Color(0xFFB0C8E8);
  
  // Estados
  static const success = Color(0xFF00C853);
  static const warning = Color(0xFFFF9800);
  static const error = Color(0xFFE53935);
  static const info = Color(0xFF2196F3);
  
  // Bordes y dividers
  static const divider = Color(0xFFE0ECFF);
  static const border = Color(0xFFBDD8F5);
  
  // Sombras
  static const shadowLight = Color(0x201A6FE8);
  static const shadowMedium = Color(0x401A6FE8);
  static const shadowDark = Color(0x601A6FE8);
  
  // Fondos específicos
  static const bgCard = Color(0xFFF0F6FF);
  static const bgField = Color(0xFFEAF2FF);
  static const bgLogo = Color.fromARGB(255, 0, 0, 0);
  
  // Glows
  static const glow1 = Color(0x400099FF);
  static const glow2 = Color(0x200057D9);
}

// Extension para facilitar el uso de colores con opacidad
extension AppColorsExtension on Color {
  Color withOpacityCustom(double opacity) {
    return withOpacity(opacity);
  }
}