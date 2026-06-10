import 'dart:io';
import 'package:flutter/material.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class PerfilService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  
  // Obtener datos del empleado
  Future<Map<String, dynamic>> obtenerPerfil(String empleadoId) async {
    final response = await _supabase
        .from('empleados')
        .select('id, nombre, email, avatar_url, salario_por_hora, rol, created_at')
        .eq('id', empleadoId)
        .single();
    return response;
  }
  
  // Actualizar nombre
  Future<bool> actualizarNombre(String empleadoId, String nuevoNombre) async {
    try {
      await _supabase
          .from('empleados')
          .update({
            'nombre': nuevoNombre,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', empleadoId);
      return true;
    } catch (e) {
      debugPrint('Error al actualizar nombre: $e');
      return false;
    }
  }
  
  // Subir foto de perfil
  Future<String?> subirFotoPerfil(String empleadoId, File imagen) async {
    try {
      final extension = imagen.path.split('.').last;
      final fileName = '$empleadoId/${DateTime.now().millisecondsSinceEpoch}.$extension';
      
      await _supabase.storage
          .from('avatars')
          .upload(fileName, imagen);
      
      final url = _supabase.storage
          .from('avatars')
          .getPublicUrl(fileName);
      
      await _supabase
          .from('empleados')
          .update({
            'avatar_url': url,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', empleadoId);
      
      return url;
    } catch (e) {
      debugPrint('Error al subir foto: $e');
      return null;
    }
  }
}

// Servicio de Chat
class ChatService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  RealtimeChannel? _channel;
  
  // Obtener mensajes
  Future<List<Map<String, dynamic>>> obtenerMensajes() async {
    final response = await _supabase
        .from('mensajes_chat')
        .select()
        .order('created_at', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(response);
  }
  
  // Enviar mensaje
  Future<void> enviarMensaje(String empleadoId, String nombre, String avatar, String mensaje) async {
    await _supabase.from('mensajes_chat').insert({
      'empleado_id': empleadoId,
      'empleado_nombre': nombre,
      'empleado_avatar': avatar,
      'mensaje': mensaje,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
  
  // ✅ VERSIÓN CORREGIDA - Suscribirse a nuevos mensajes
  void suscribirMensajes(Function(Map<String, dynamic>) onNuevoMensaje) {
    _channel = _supabase
        .channel('chat')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'mensajes_chat',
          callback: (payload) {
            final nuevoMensaje = payload.newRecord;
            onNuevoMensaje(nuevoMensaje);
          },
        )
        .subscribe();
  }
  
  // Editar mensaje
  Future<bool> editarMensaje(String mensajeId, String nuevoTexto) async {
    try {
      // Intenta actualizar con la bandera 'editado' (requiere columna en BD)
      await _supabase
          .from('mensajes_chat')
          .update({'mensaje': nuevoTexto, 'editado': true})
          .eq('id', mensajeId);
      return true;
    } catch (_) {
      try {
        // Fallback: actualiza solo el texto si la columna 'editado' no existe
        await _supabase
            .from('mensajes_chat')
            .update({'mensaje': nuevoTexto})
            .eq('id', mensajeId);
        return true;
      } catch (e) {
        debugPrint('Error al editar mensaje: $e');
        return false;
      }
    }
  }

  // Eliminar mensaje
  Future<bool> eliminarMensaje(String mensajeId) async {
    try {
      await _supabase.from('mensajes_chat').delete().eq('id', mensajeId);
      return true;
    } catch (e) {
      debugPrint('Error al eliminar mensaje: $e');
      return false;
    }
  }

  // Cancelar suscripción
  void cancelarSuscripcion() {
    _channel?.unsubscribe();
  }
}