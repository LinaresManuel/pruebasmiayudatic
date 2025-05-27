import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/ticket_model.dart';

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

  // Tickets API
  Future<List<Ticket>> getTickets() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/tickets.php'));
      final data = jsonDecode(response.body);
      
      if (data is List) {
        return data.map((json) => Ticket.fromJson(json)).toList();
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
      
      if (data != null) {
        return Ticket.fromJson(data);
      }
      throw Exception('Ticket no encontrado');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<int> createTicket(Ticket ticket) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tickets.php'),
        body: jsonEncode(ticket.toJson()),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['id'];
      }
      throw Exception(data['error'] ?? 'Error al crear el ticket');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<void> updateTicket(int id, Map<String, dynamic> updates) async {
    try {
      updates['id'] = id;
      final response = await http.put(
        Uri.parse('$baseUrl/tickets.php'),
        body: jsonEncode(updates),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Error al actualizar el ticket');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Staff API
  Future<List<User>> getAllStaff() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/staff.php'));
      final data = jsonDecode(response.body);
      
      if (data is List) {
        return data.map((json) => User.fromJson(json)).toList();
      }
      throw Exception('Error al obtener el personal');
    } catch (e) {
      throw Exception('Error de conexión: $e');
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
} 