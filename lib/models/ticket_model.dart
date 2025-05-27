class Ticket {
  final int? id;
  final DateTime fechaReporte;
  final String nombresSolicitante;
  final String apellidosSolicitante;
  final String correoSolicitante;
  final String numeroContacto;
  final String descripcion;
  final String dependencia;
  final String? estado;
  final String? tipoServicio;
  final String? personalAsignado;
  final DateTime? fechaCreacion;
  final DateTime? fechaCierre;

  Ticket({
    this.id,
    required this.fechaReporte,
    required this.nombresSolicitante,
    required this.apellidosSolicitante,
    required this.correoSolicitante,
    required this.numeroContacto,
    required this.descripcion,
    required this.dependencia,
    this.estado,
    this.tipoServicio,
    this.personalAsignado,
    this.fechaCreacion,
    this.fechaCierre,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: int.tryParse(json['id_solicitud']?.toString() ?? ''),
      fechaReporte: DateTime.parse(json['fecha_reporte']),
      nombresSolicitante: json['nombres_solicitante'],
      apellidosSolicitante: json['apellidos_solicitante'],
      correoSolicitante: json['correo_institucional_solicitante'],
      numeroContacto: json['numero_contacto_solicitante'],
      descripcion: json['descripcion_solicitud'],
      dependencia: json['nombre_dependencia'] ?? json['dependencia'],
      estado: json['nombre_estado'] ?? json['estado'],
      tipoServicio: json['nombre_tipo_servicio'] ?? json['tipo_servicio'],
      personalAsignado: json['personal_asignado'],
      fechaCreacion: json['fecha_creacion_registro'] != null 
        ? DateTime.parse(json['fecha_creacion_registro'])
        : null,
      fechaCierre: json['fecha_cierre'] != null 
        ? DateTime.parse(json['fecha_cierre'])
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fecha_reporte': fechaReporte.toIso8601String().split('T')[0],
      'nombres_solicitante': nombresSolicitante,
      'apellidos_solicitante': apellidosSolicitante,
      'correo_institucional_solicitante': correoSolicitante,
      'numero_contacto_solicitante': numeroContacto,
      'descripcion_solicitud': descripcion,
      'id_dependencia': int.parse(dependencia),
    };
  }

  Map<String, dynamic> toUpdateJson() {
    final Map<String, dynamic> data = {};
    if (estado != null) data['id_estado'] = int.parse(estado!);
    if (tipoServicio != null) data['id_tipo_servicio'] = int.parse(tipoServicio!);
    if (personalAsignado != null) data['id_personal_ti_asignado'] = int.parse(personalAsignado!);
    if (fechaCierre != null) data['fecha_cierre'] = fechaCierre!.toIso8601String();
    return data;
  }
} 