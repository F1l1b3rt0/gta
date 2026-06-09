enum NivelGerente { junior, senior, director }

class Gerente {
  final String id;
  final String userId;
  final String nombre;
  final String email;
  final NivelGerente nivel;
  final Map<String, bool> permisos;
  final bool activo;
  final DateTime createdAt;
  
  Gerente({
    required this.id,
    required this.userId,
    required this.nombre,
    required this.email,
    required this.nivel,
    required this.permisos,
    required this.activo,
    required this.createdAt,
  });
  
  factory Gerente.fromJson(Map<String, dynamic> json) {
    return Gerente(
      id: json['id'],
      userId: json['user_id'],
      nombre: json['nombre'],
      email: json['email'],
      nivel: _stringToNivel(json['nivel'] ?? 'senior'),
      permisos: Map<String, bool>.from(json['permisos'] ?? {}),
      activo: json['activo'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
  
  static NivelGerente _stringToNivel(String nivel) {
    switch (nivel) {
      case 'junior': return NivelGerente.junior;
      case 'senior': return NivelGerente.senior;
      case 'director': return NivelGerente.director;
      default: return NivelGerente.senior;
    }
  }
  
  static String nivelToString(NivelGerente nivel) {
    switch (nivel) {
      case NivelGerente.junior: return 'junior';
      case NivelGerente.senior: return 'senior';
      case NivelGerente.director: return 'director';
    }
  }
  
  bool tienePermiso(String permiso) {
    return permisos[permiso] ?? false;
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'nombre': nombre,
      'email': email,
      'nivel': nivelToString(nivel),
      'permisos': permisos,
      'activo': activo,
    };
  }
}