import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/ticket_model.dart';
import '../models/staff_page.dart';

class ApiService {
  static const String baseUrl = 'https://ducjin.space/miayudatic';

  // Auth API
  Future<User?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth.php'),
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return User.fromJson(data['user']);
      }
      throw Exception(data['message'] ?? 'Error en el inicio de sesión');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Master Data API
  Future<List<Map<String, dynamic>>> getDependencies() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/master_data.php?action=dependencies'));
      final data = jsonDecode(response.body);
      
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      throw Exception('Error al obtener las dependencias');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getServiceTypes() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/master_data.php?action=service-types'));
      final data = jsonDecode(response.body);
      
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      throw Exception('Error al obtener los tipos de servicio');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getSupportStaff() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/master_data.php?action=support-staff'));
      final data = jsonDecode(response.body);
      
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      throw Exception('Error al obtener el personal de soporte');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getRoles() async {
    final response = await http.get(Uri.parse('$baseUrl/master_data.php?action=roles'));
    final data = jsonDecode(response.body);
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    throw Exception('Error al obtener los roles');
  }

  // Tickets API
  Future<List<Ticket>> getTickets({int? estado}) async {
    try {
      String url = '$baseUrl/tickets.php';
      if (estado != null) {
        url += '?estado=$estado';
      }
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);
      
      if (data is List) {
        final tickets = data.map((json) => Ticket.fromJson(json)).toList();
        // Ordenar por fecha de creación (las más antiguas primero)
        tickets.sort((a, b) => a.fechaCreacion!.compareTo(b.fechaCreacion!));
        return tickets;
      }
      throw Exception('Error al obtener los tickets');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<Ticket> getTicketDetails(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/tickets.php?id=$id'));
      final data = jsonDecode(response.body);
      
      if (data is List) {
        // Buscar el ticket específico en la lista por su ID
        final ticketData = data.firstWhere(
          (ticket) => int.parse(ticket['id_solicitud'].toString()) == id,
          orElse: () => throw Exception('Ticket no encontrado'),
        );
        return Ticket.fromJson(ticketData);
      } else if (data is Map<String, dynamic>) {
        // Si el backend devuelve un objeto directamente
        return Ticket.fromJson(data);
      }
      throw Exception('Ticket no encontrado');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<Map<String, dynamic>> createTicket(Ticket ticket) async {
    try {
      print('Creando ticket con datos: \\${jsonEncode(ticket.toJson())}'); // Debug log
      final response = await http.post(
        Uri.parse('$baseUrl/tickets.php'),
        body: jsonEncode(ticket.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
      print('Respuesta del servidor: \\${response.body}'); // Debug log
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['ticket_id'] != null) {
        // Devolver los datos necesarios para el correo
        return {
          'id_solicitud': data['ticket_id'],
          'correo_usuario': ticket.correoSolicitante,
          'fecha_reporte': ticket.fechaReporte.toIso8601String().split('T')[0],
          'descripcion': ticket.descripcion,
        };
      }
      throw Exception(data['error'] ?? 'Error al crear el ticket');
    } catch (e) {
      print('Error en createTicket: \\${e}'); // Debug log
      throw Exception('Error al crear el ticket: \\${e}');
    }
  }

  Future<bool> enviarCorreoConfirmacion({
    required String correoUsuario,
    required String fechaReporte,
    required String idSolicitud,
    required String descripcion,
  }) async {
    final url = Uri.parse('$baseUrl/enviar_correo.php');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'correo_usuario': correoUsuario,
        'fecha_reporte': fechaReporte,
        'id_solicitud': idSolicitud,
        'descripcion': descripcion,
      }),
    );
    final data = jsonDecode(response.body);
    return data['success'] == true;
  }

  Future<void> updateTicket(int id, Map<String, dynamic> updates) async {
    try {
      if (updates.isEmpty) {
        throw Exception('No hay campos para actualizar');
      }

      print('Actualizando ticket: ID=$id, Updates=${jsonEncode(updates)}'); // Debug log
      
      final response = await http.put(
        Uri.parse('$baseUrl/tickets.php?id=$id'),
        body: jsonEncode(updates),
        headers: {'Content-Type': 'application/json'},
      );

      print('Respuesta del servidor: ${response.body}'); // Debug log

      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Error al actualizar el ticket');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Staff API
  Future<StaffPage> getStaffPage({String cedula = '', int page = 1, int perPage = 10}) async {
    final uri = Uri.parse('$baseUrl/staff.php')
        .replace(queryParameters: {
          if (cedula.isNotEmpty) 'cedula': cedula,
          'page': page.toString(),
          'perPage': perPage.toString(),
        });
    final response = await http.get(uri);
    final resp = jsonDecode(response.body);
    if (resp['success'] == true && resp['data'] != null) {
      return StaffPage(
        data: (resp['data'] as List).map((e) => User.fromJson(e)).toList(),
        total: resp['total'] ?? 0,
        page: resp['page'] ?? 1,
        perPage: resp['perPage'] ?? perPage,
      );
    } else {
      throw Exception(resp['error'] ?? 'Error al obtener el personal TIC');
    }
  }

  Future<User> getStaffMember(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/staff.php?id=$id'));
      final data = jsonDecode(response.body);
      
      if (data != null) {
        return User.fromJson(data);
      }
      throw Exception('Personal no encontrado');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<List<Ticket>> getClosedTickets() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/tickets.php?estado=cerrada'));
      final data = jsonDecode(response.body);
      
      if (data is List) {
        return data.map((ticket) => Ticket.fromJson(ticket)).toList();
      } else if (data is Map<String, dynamic>) {
        return [Ticket.fromJson(data)];
      }
      return [];
    } catch (e) {
      throw Exception('Error al obtener las solicitudes cerradas: $e');
    }
  }

  Future<bool> cerrarCasoYEnviarCorreo({
    required int idSolicitud,
    required String descripcionSolucion,
  }) async {
    final url = Uri.parse('$baseUrl/cerrar_caso_y_enviar_correo.php');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id_solicitud': idSolicitud,
        'descripcion_solucion': descripcionSolucion,
      }),
    );
    final data = jsonDecode(response.body);
    if (data['success'] == true) {
      return true;
    } else {
      throw Exception(data['message'] ?? 'Error al cerrar el caso y enviar correo');
    }
  }

  Future<User> createStaffMember(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/staff.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    final resp = jsonDecode(response.body);
    if (resp['success'] == true && resp['id'] != null) {
      return getStaffMember(resp['id']);
    } else {
      throw Exception(resp['error'] ?? 'Error al crear el personal');
    }
  }

  Future<User> updateStaffMember(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/staff.php?id=$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    final resp = jsonDecode(response.body);
    if (resp['success'] == true) {
      return getStaffMember(id);
    } else {
      throw Exception(resp['error'] ?? 'Error al actualizar el personal');
    }
  }

  Future<void> deleteStaffMember(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/staff.php?id=$id'),
    );
    final resp = jsonDecode(response.body);
    if (resp['success'] != true) {
      throw Exception(resp['error'] ?? 'Error al eliminar el personal');
    }
  }

  Future<String> generatePasswordHash(String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/generate_hash.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'password': password}),
    );
    final data = jsonDecode(response.body);
    if (data['success'] == true && data['hash'] != null) {
      return data['hash'];
    } else {
      throw Exception(data['error'] ?? 'Error al generar el hash de la contraseña');
    }
  }
} 