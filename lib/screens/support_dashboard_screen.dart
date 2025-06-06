import 'package:flutter/material.dart';
import '../models/ticket_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import './details_screen.dart';

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
        'id_estado': 3, // ID del estado 'Cerrada' (3 = Cerrada, 1 = Abierta)
        'fecha_cierre': DateTime.now().toIso8601String(),
      };

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
      print('Error en _closeTicket: $e');
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
        final serviceTypeData = _serviceTypes.firstWhere(
          (type) => type['nombre_tipo_servicio'] == serviceType,
          orElse: () => throw Exception('Tipo de servicio no encontrado'),
        );
        updates['id_tipo_servicio'] = int.parse(serviceTypeData['id_tipo_servicio'].toString());
      }
      
      if (staffName != null) {
        final staffData = _supportStaff.firstWhere(
          (staff) => staff['nombre_completo'] == staffName,
          orElse: () => throw Exception('Personal no encontrado'),
        );
        updates['id_personal_ti_asignado'] = int.parse(staffData['id_usuario'].toString());
      }

      print('Enviando actualización: $updates'); // Log para debug
      await _apiService.updateTicket(ticket.id!, updates);
      await _loadTickets();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitud actualizada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      print('Error en _assignTicket: $e');
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
        toolbarHeight: 80,
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
        flexibleSpace: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/sena_logo.png',
                    height: 50,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[800],
                        child: const Icon(Icons.business, color: Colors.white),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Servicios TIC Sena Regional Guainía',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
              ),
            ],
          ),
        ),
      ),
      body: _loadingMasterData
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '/ Inicio / Consola de Servicios',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Gestión de Solicitudes',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _loadTickets,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Actualizar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.cyan[600],
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Error: $_error',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isSmallScreen = constraints.maxWidth < 800;
                          final isMediumScreen = constraints.maxWidth < 1200;
                          
                          return Card(
                            margin: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SingleChildScrollView(
                                child: Container(
                                  constraints: BoxConstraints(
                                    minWidth: isSmallScreen ? constraints.maxWidth : 800,
                                    maxWidth: isMediumScreen ? constraints.maxWidth : 1600,
                                  ),
                                  child: DataTable(
                                    headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
                                    columnSpacing: isSmallScreen ? 10 : 20,
                                    horizontalMargin: isSmallScreen ? 10 : 24,
                                    columns: [
                                      DataColumn(
                                        label: Text('ID', 
                                          style: TextStyle(fontSize: isSmallScreen ? 12 : 14)
                                        ), 
                                        numeric: true
                                      ),
                                      if (!isSmallScreen) 
                                        DataColumn(
                                          label: Text('Fecha',
                                            style: TextStyle(fontSize: isSmallScreen ? 12 : 14)
                                          )
                                        ),
                                      DataColumn(
                                        label: Text('Solicitante',
                                          style: TextStyle(fontSize: isSmallScreen ? 12 : 14)
                                        )
                                      ),
                                      if (!isSmallScreen) 
                                        DataColumn(
                                          label: Text('Dependencia',
                                            style: TextStyle(fontSize: isSmallScreen ? 12 : 14)
                                          )
                                        ),
                                      DataColumn(
                                        label: Text('Descripción',
                                          style: TextStyle(fontSize: isSmallScreen ? 12 : 14)
                                        ),
                                        tooltip: 'Haz clic en el ícono de información para ver la descripción completa',
                                      ),
                                      DataColumn(
                                        label: Text('Estado',
                                          style: TextStyle(fontSize: isSmallScreen ? 12 : 14)
                                        )
                                      ),
                                      if (!isMediumScreen)
                                        DataColumn(
                                          label: Text('Tipo de Servicio',
                                            style: TextStyle(fontSize: isSmallScreen ? 12 : 14)
                                          )
                                        ),
                                      DataColumn(
                                        label: Text('Personal Asignado',
                                          style: TextStyle(fontSize: isSmallScreen ? 12 : 14)
                                        )
                                      ),
                                      DataColumn(
                                        label: Text('Acciones',
                                          style: TextStyle(fontSize: isSmallScreen ? 12 : 14)
                                        )
                                      ),
                                    ],
                                    rows: _tickets.map((ticket) {
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            Text(
                                              ticket.id.toString(),
                                              style: TextStyle(fontSize: isSmallScreen ? 11 : 13),
                                            )
                                          ),
                                          if (!isSmallScreen)
                                            DataCell(
                                              Text(
                                                DateFormat('dd/MM/yyyy').format(ticket.fechaReporte),
                                                style: TextStyle(fontSize: isSmallScreen ? 11 : 13),
                                              )
                                            ),
                                          DataCell(
                                            Text(
                                              '${ticket.nombresSolicitante} ${ticket.apellidosSolicitante}',
                                              style: TextStyle(fontSize: isSmallScreen ? 11 : 13),
                                            )
                                          ),
                                          if (!isSmallScreen)
                                            DataCell(
                                              Text(
                                                ticket.dependencia,
                                                style: TextStyle(fontSize: isSmallScreen ? 11 : 13),
                                              )
                                            ),
                                          DataCell(
                                            Container(
                                              width: isSmallScreen ? 100 : 200,
                                              child: Text(
                                                ticket.descripcion,
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                                style: TextStyle(fontSize: isSmallScreen ? 11 : 13),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: isSmallScreen ? 4 : 8, 
                                                vertical: isSmallScreen ? 2 : 4
                                              ),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(ticket.estado),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                ticket.estado ?? 'Abierta',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: isSmallScreen ? 11 : 13
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (!isMediumScreen)
                                            DataCell(
                                              DropdownButton<String>(
                                                value: ticket.tipoServicio,
                                                hint: Text(
                                                  'Seleccionar',
                                                  style: TextStyle(fontSize: isSmallScreen ? 11 : 13),
                                                ),
                                                items: _serviceTypes.map((type) {
                                                  return DropdownMenuItem<String>(
                                                    value: type['nombre_tipo_servicio'],
                                                    child: Text(
                                                      type['nombre_tipo_servicio'],
                                                      style: TextStyle(fontSize: isSmallScreen ? 11 : 13),
                                                    ),
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
                                            DropdownButton<String>(
                                              value: ticket.personalAsignado,
                                              hint: Text(
                                                'Asignar',
                                                style: TextStyle(fontSize: isSmallScreen ? 11 : 13),
                                              ),
                                              items: _supportStaff.map((staff) {
                                                return DropdownMenuItem<String>(
                                                  value: staff['nombre_completo'],
                                                  child: Text(
                                                    staff['nombre_completo'],
                                                    style: TextStyle(fontSize: isSmallScreen ? 11 : 13),
                                                  ),
                                                );
                                              }).toList(),
                                              onChanged: ticket.estado != 'Cerrada'
                                                  ? (String? newValue) {
                                                      _assignTicket(ticket, null, newValue);
                                                    }
                                                  : null,
                                            ),
                                          ),
                                          DataCell(
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.info,
                                                    size: isSmallScreen ? 18 : 24,
                                                  ),
                                                  onPressed: () => _showTicketDetails(ticket),
                                                  color: Colors.blue,
                                                ),
                                                if (ticket.estado != 'Cerrada')
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.check_circle,
                                                      size: isSmallScreen ? 18 : 24,
                                                    ),
                                                    onPressed: () => Navigator.pushNamed(
                                                      context,
                                                      '/case-details',
                                                      arguments: {
                                                        'caseId': ticket.id.toString(),
                                                      },
                                                    ),
                                                    color: Colors.green,
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
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Color _getStatusColor(String? status) {
    return status == 'Cerrada' ? Colors.green : Colors.orange;
  }
} 