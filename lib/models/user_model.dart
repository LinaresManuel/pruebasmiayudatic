class User {
  final int id;
  final String nombre;
  final String apellido;
  final String cedula;
  final String correo;
  final String rol;
  final String? fechaCreacion;
  final String? ultimaSesion;

  User({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.cedula,
    required this.correo,
    required this.rol,
    this.fechaCreacion,
    this.ultimaSesion,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id_usuario'] is int
          ? json['id_usuario']
          : int.tryParse(json['id_usuario'].toString()) ?? 0,
      nombre: json['nombre'] ?? '',
      apellido: json['apellido'] ?? '',
      cedula: json['cedula'] ?? '',
      correo: json['correo_electronico'] ?? json['correo'] ?? '',
      rol: json['nombre_rol'] ?? json['rol'] ?? '',
      fechaCreacion: json['fecha_creacion'],
      ultimaSesion: json['ultima_sesion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_usuario': id,
      'nombre': nombre,
      'apellido': apellido,
      'cedula': cedula,
      'correo_electronico': correo,
      'nombre_rol': rol,
      'fecha_creacion': fechaCreacion,
      'ultima_sesion': ultimaSesion,
    };
  }
} 


