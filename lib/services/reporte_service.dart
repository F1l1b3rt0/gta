import 'dart:io';
import 'dart:convert';  // ← Agrega esta línea con los otros imports
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../config/supabase_config.dart';

class ReporteService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  
  // Generar reporte CSV para un empleado
  Future<File> generarReporteNomina(DateTime mes, String empleadoId) async {
    final inicio = DateTime(mes.year, mes.month, 1);
    final fin = DateTime(mes.year, mes.month + 1, 0);
    
    // Obtener turnos del mes
    final turnos = await _supabase
        .from('turnos')
        .select('*, empleados(nombre, salario_por_hora)')
        .eq('empleado_id', empleadoId)
        .gte('entrada', inicio.toIso8601String())
        .lte('entrada', fin.toIso8601String())
        .not('salida', 'is', null);
    
    if (turnos.isEmpty) {
      throw Exception('No hay turnos para el período seleccionado');
    }
    
    // Calcular horas
    double totalHorasNormales = 0;
    double totalHorasExtras = 0;
    final lineas = <String>[];
    
    // Encabezados CSV
    lineas.add('Fecha,Entrada,Salida,Horas,Tipo');
    
    for (var turno in turnos) {
      final entrada = DateTime.parse(turno['entrada']);
      final salida = DateTime.parse(turno['salida']);
      final horas = salida.difference(entrada).inHours;
      final esExtra = turno['es_extra'] ?? false;
      
      if (esExtra) {
        totalHorasExtras += horas;
      } else {
        totalHorasNormales += horas;
      }
      
      lineas.add(
        '${DateFormat('dd/MM/yyyy').format(entrada)},'
        '${DateFormat('HH:mm').format(entrada)},'
        '${DateFormat('HH:mm').format(salida)},'
        '$horas,'
        '${esExtra ? "Extra" : "Normal"}'
      );
    }
    
    final empleado = turnos[0]['empleados'];
    final salarioPorHora = (empleado['salario_por_hora'] ?? 0).toDouble();
    final totalNormal = totalHorasNormales * salarioPorHora;
    final totalExtra = totalHorasExtras * salarioPorHora * 1.5;
    final total = totalNormal + totalExtra;
    
    // Agregar resumen
    lineas.add('');
    lineas.add('RESUMEN');
    lineas.add('Empleado,${empleado['nombre']}');
    lineas.add('Mes,${DateFormat('MMMM yyyy').format(mes)}');
    lineas.add('Horas Normales,$totalHorasNormales');
    lineas.add('Horas Extras,$totalHorasExtras');
    lineas.add('Total Horas,${totalHorasNormales + totalHorasExtras}');
    lineas.add('Pago Normal,\$${totalNormal.toStringAsFixed(2)}');
    lineas.add('Pago Extra,\$${totalExtra.toStringAsFixed(2)}');
    lineas.add('TOTAL,\$${total.toStringAsFixed(2)}');
    
    // Guardar archivo
    final content = lineas.join('\n');
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/reporte_${empleado['nombre']}_${DateFormat('yyyyMM').format(mes)}.csv');
    await file.writeAsString(content, encoding: utf8);
    
    return file;
  }
  
  // Generar reporte general de todos los empleados
  Future<File> generarReporteGeneral(DateTime mes) async {
    final empleados = await _supabase
        .from('empleados')
        .select('id, nombre, salario_por_hora')
        .neq('rol', 'gerente');
    
    final lineas = <String>[];
    lineas.add('REPORTE GENERAL DE NÓMINA');
    lineas.add('Mes: ${DateFormat('MMMM yyyy').format(mes)}');
    lineas.add('');
    lineas.add('Empleado,Horas Normales,Horas Extras,Total Horas,Pago Normal,Pago Extra,TOTAL');
    
    for (var empleado in empleados) {
      final resumen = await _calcularResumenEmpleado(empleado['id'], mes);
      lineas.add(
        '${empleado['nombre']},'
        '${resumen['horasNormales']},'
        '${resumen['horasExtras']},'
        '${resumen['totalHoras']},'
        '\$${resumen['pagoNormal'].toStringAsFixed(2)},'
        '\$${resumen['pagoExtra'].toStringAsFixed(2)},'
        '\$${resumen['total'].toStringAsFixed(2)}'
      );
    }
    
    final content = lineas.join('\n');
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/reporte_general_${DateFormat('yyyyMM').format(mes)}.csv');
    await file.writeAsString(content, encoding: utf8);
    
    return file;
  }
  
  Future<Map<String, dynamic>> _calcularResumenEmpleado(String empleadoId, DateTime mes) async {
    final inicio = DateTime(mes.year, mes.month, 1);
    final fin = DateTime(mes.year, mes.month + 1, 0);
    
    final turnos = await _supabase
        .from('turnos')
        .select()
        .eq('empleado_id', empleadoId)
        .gte('entrada', inicio.toIso8601String())
        .lte('entrada', fin.toIso8601String())
        .not('salida', 'is', null);
    
    final empleado = await _supabase
        .from('empleados')
        .select('salario_por_hora')
        .eq('id', empleadoId)
        .single();
    
    final salarioPorHora = (empleado['salario_por_hora'] ?? 0).toDouble();
    double horasNormales = 0;
    double horasExtras = 0;
    
    for (var turno in turnos) {
      final entrada = DateTime.parse(turno['entrada']);
      final salida = DateTime.parse(turno['salida']);
      final horas = salida.difference(entrada).inHours;
      
      if (turno['es_extra'] == true) {
        horasExtras += horas;
      } else {
        horasNormales += horas;
      }
    }
    
    final pagoNormal = horasNormales * salarioPorHora;
    final pagoExtra = horasExtras * salarioPorHora * 1.5;
    
    return {
      'horasNormales': horasNormales,
      'horasExtras': horasExtras,
      'totalHoras': horasNormales + horasExtras,
      'pagoNormal': pagoNormal,
      'pagoExtra': pagoExtra,
      'total': pagoNormal + pagoExtra,
    };
  }
  
  // Guardar y compartir archivo
  Future<void> guardarYCompartirExcel(File file, String nombreArchivo) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Reporte de nómina GTA',
    );
  }
}