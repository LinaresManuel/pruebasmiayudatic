class User {
  final int id;
  final String nombre;
  final String cedula;
  final String rol;

  User({
    required this.id,
    required this.nombre,
    required this.cedula,
    required this.rol,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      nombre: json['nombre'],
      cedula: json['cedula'],
      rol: json['rol'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'cedula': cedula,
      'rol': rol,
    };
  }
} 


