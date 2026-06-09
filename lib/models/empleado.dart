class Empleado {
  final String id;
  final String userId;
  final String nombre;
  final String email;
  final double salarioPorHora;
  final int maxHorasDiarias;
  final int maxHorasSemanales;
  final Map<String, dynamic>? disponibilidad;
  final DateTime fechaContratacion;
  final bool activo;
  
  Empleado({
    required this.id,
    required this.userId,
    required this.nombre,
    required this.email,
    required this.salarioPorHora,
    required this.maxHorasDiarias,
    required this.maxHorasSemanales,
    this.disponibilidad,
    required this.fechaContratacion,
    required this.activo,
  });
  
 factory Empleado.fromJson(Map<String, dynamic> json) {
  return Empleado(
    id: json['id'] ?? '',
    userId: json['user_id'] ?? json['id'] ?? '',
    nombre: json['nombre'] ?? '',
    email: json['email'] ?? '',
    salarioPorHora: (json['salario_por_hora'] as num?)?.toDouble() ?? 0,
    maxHorasDiarias: json['max_horas_diarias'] ?? 8,
    maxHorasSemanales: json['max_horas_semanales'] ?? 40,
    disponibilidad: json['disponibilidad'] is Map
        ? Map<String, dynamic>.from(json['disponibilidad'])
        : null,
    fechaContratacion: json['fecha_contratacion'] != null
        ? DateTime.parse(json['fecha_contratacion'])
        : DateTime.now(),
    activo: json['activo'] ?? true,
  );
}
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'nombre': nombre,
      'email': email,
      'salario_por_hora': salarioPorHora,
      'max_horas_diarias': maxHorasDiarias,
      'max_horas_semanales': maxHorasSemanales,
      'disponibilidad': disponibilidad,
      'fecha_contratacion': fechaContratacion.toIso8601String().split('T')[0],
      'activo': activo,
    };
  }
}