import 'package:flutter/material.dart';
import '../models/ticket_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class SupportDashboardScreen extends StatefulWidget {
  const SupportDashboardScreen({super.key});

  @override
  State<SupportDashboardScreen> createState() => _SupportDashboardScreenState();
}

class _SupportDashboardScreenState extends State<SupportDashboardScreen> {
  final ApiService _apiService = ApiService();
  List<Ticket> _tickets = [];
  List<Map<String, dynamic>> _serviceTypes = [];
  List<Map<String, dynamic>> _supportStaff = [];
  bool _isLoading = true;
  bool _loadingMasterData = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      await Future.wait([
        _loadTickets(),
        _loadServiceTypes(),
        _loadSupportStaff(),
      ]);
    } finally {
      if (mounted) {
        setState(() {
          _loadingMasterData = false;
        });
      }
    }
  }

  Future<void> _loadServiceTypes() async {
    try {
      final serviceTypes = await _apiService.getServiceTypes();
      if (mounted) {
        setState(() {
          _serviceTypes = serviceTypes;
        });
      }
    } catch (e) {
      print('Error loading service types: $e');
    }
  }

  Future<void> _loadSupportStaff() async {
    try {
      final staff = await _apiService.getSupportStaff();
      if (mounted) {
        setState(() {
          _supportStaff = staff;
        });
      }
    } catch (e) {
      print('Error loading support staff: $e');
    }
  }

  Future<void> _loadTickets() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final tickets = await _apiService.getTickets();
      setState(() {
        _tickets = tickets;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showTicketDetails(Ticket ticket) async {
    try {
      final details = await _apiService.getTicketDetails(ticket.id!);
      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Detalles de la Solicitud'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow('ID', details.id.toString()),
                _detailRow('Fecha de Reporte', DateFormat('dd/MM/yyyy').format(details.fechaReporte)),
                _detailRow('Solicitante', '${details.nombresSolicitante} ${details.apellidosSolicitante}'),
                _detailRow('Correo', details.correoSolicitante),
                _detailRow('Contacto', details.numeroContacto),
                _detailRow('Dependencia', details.dependencia),
                _detailRow('Estado', details.estado ?? 'No asignado'),
                _detailRow('Tipo de Servicio', details.tipoServicio ?? 'No asignado'),
                _detailRow('Personal Asignado', details.personalAsignado ?? 'No asignado'),
                if (details.fechaCreacion != null)
                  _detailRow('Fecha de Creación', DateFormat('dd/MM/yyyy HH:mm').format(details.fechaCreacion!)),
                if (details.fechaCierre != null)
                  _detailRow('Fecha de Cierre', DateFormat('dd/MM/yyyy HH:mm').format(details.fechaCierre!)),
                const Divider(),
                const Text('Descripción:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(details.descripcion),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      print('Error al cargar detalles: $e'); // Debug log
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar los detalles: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _closeTicket(Ticket ticket) async {
    try {
      final updates = {
        'id_estado': 3, // ID del estado 'Cerrada'
        'fecha_cierre': DateTime.now().toIso8601String(),
      };

      print('Cerrando ticket: ${ticket.id} con datos: $updates'); // Debug log
      await _apiService.updateTicket(ticket.id!, updates);
      await _loadTickets();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitud cerrada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      print('Error en _closeTicket: $e'); // Debug log
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cerrar la solicitud: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _assignTicket(Ticket ticket, String? serviceType, String? staffName) async {
    if (serviceType == null && staffName == null) return;

    try {
      final updates = <String, dynamic>{};
      
      if (serviceType != null) {
        // Buscar el ID del tipo de servicio por nombre
        final serviceTypeData = _serviceTypes.firstWhere(
          (type) => type['nombre_tipo_servicio'] == serviceType,
          orElse: () => throw Exception('Tipo de servicio no encontrado'),
        );
        updates['id_tipo_servicio'] = int.parse(serviceTypeData['id_tipo_servicio'].toString());
        
        // Actualizar el estado a "En Proceso" si no está cerrado
        if (ticket.estado != 'Cerrada') {
          updates['id_estado'] = 2; // 2 = En Proceso
        }
      }
      
      if (staffName != null) {
        // Buscar el ID del personal por nombre completo
        final staffData = _supportStaff.firstWhere(
          (staff) => staff['nombre_completo'] == staffName,
          orElse: () => throw Exception('Personal no encontrado'),
        );
        updates['id_personal_ti_asignado'] = int.parse(staffData['id_usuario'].toString());
        
        // Actualizar el estado a "En Proceso" si no está cerrado
        if (ticket.estado != 'Cerrada') {
          updates['id_estado'] = 2; // 2 = En Proceso
        }
      }

      print('Enviando actualización: $updates'); // Debug log
      await _apiService.updateTicket(ticket.id!, updates);
      await _loadTickets(); // Recargar la lista de tickets

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitud actualizada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      print('Error en _assignTicket: $e'); // Debug log
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar la solicitud: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Control'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInitialData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Staff Info Header
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  child: Icon(Icons.person, size: 40),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Juan Pérez', // TODO: Get from user state
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Cédula: 12345678',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Rol: Técnico de Soporte',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Tickets Table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Error al cargar las solicitudes: $_error',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadInitialData,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : _tickets.isEmpty
                        ? const Center(
                            child: Text('No hay solicitudes registradas'),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('ID')),
                                  DataColumn(label: Text('Estado')),
                                  DataColumn(label: Text('Tipo')),
                                  DataColumn(label: Text('Asignado a')),
                                  DataColumn(label: Text('Fecha Creación')),
                                  DataColumn(label: Text('Fecha Cierre')),
                                  DataColumn(label: Text('Descripción')),
                                  DataColumn(label: Text('Acciones')),
                                ],
                                rows: _tickets.map((ticket) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(ticket.id.toString())),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: ticket.estado == 'Cerrada'
                                                ? Colors.red
                                                : Colors.green,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            ticket.estado ?? 'Abierta',
                                            style: const TextStyle(
                                                color: Colors.white),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        _loadingMasterData
                                            ? const CircularProgressIndicator()
                                            : DropdownButton<String>(
                                                value: ticket.tipoServicio != null ? ticket.tipoServicio : null,
                                                hint: const Text('Seleccionar'),
                                                items: _serviceTypes.map((type) {
                                                  return DropdownMenuItem<String>(
                                                    value: type['nombre_tipo_servicio'],
                                                    child: Text(type['nombre_tipo_servicio']),
                                                  );
                                                }).toList(),
                                                onChanged: ticket.estado != 'Cerrada'
                                                    ? (String? newValue) {
                                                        _assignTicket(ticket, newValue, null);
                                                      }
                                                    : null,
                                              ),
                                      ),
                                      DataCell(
                                        _loadingMasterData
                                            ? const CircularProgressIndicator()
                                            : DropdownButton<String>(
                                                value: ticket.personalAsignado != null ? ticket.personalAsignado : null,
                                                hint: const Text('Asignar'),
                                                items: _supportStaff.map((staff) {
                                                  return DropdownMenuItem<String>(
                                                    value: staff['nombre_completo'],
                                                    child: Text(staff['nombre_completo']),
                                                  );
                                                }).toList(),
                                                onChanged: ticket.estado != 'Cerrada'
                                                    ? (String? newValue) {
                                                        _assignTicket(ticket, null, newValue);
                                                      }
                                                    : null,
                                              ),
                                      ),
                                      DataCell(Text(DateFormat('dd/MM/yyyy')
                                          .format(ticket.fechaCreacion!))),
                                      DataCell(Text(ticket.fechaCierre != null
                                          ? DateFormat('dd/MM/yyyy')
                                              .format(ticket.fechaCierre!)
                                          : '-')),
                                      DataCell(Text(
                                        ticket.descripcion,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      )),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.info),
                                              onPressed: () =>
                                                  _showTicketDetails(ticket),
                                              tooltip: 'Ver detalles',
                                            ),
                                            if (ticket.estado != 'Cerrada')
                                              IconButton(
                                                icon: const Icon(
                                                    Icons.check_circle_outline),
                                                onPressed: () =>
                                                    _closeTicket(ticket),
                                                tooltip: 'Cerrar ticket',
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
} 