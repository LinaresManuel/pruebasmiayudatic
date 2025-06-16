import 'package:flutter/material.dart';
import '../models/ticket_model.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class SolicitudCerradaScreen extends StatefulWidget {
  const SolicitudCerradaScreen({super.key});

  @override
  State<SolicitudCerradaScreen> createState() => _SolicitudCerradaScreenState();
}

class _SolicitudCerradaScreenState extends State<SolicitudCerradaScreen> {
  final ApiService _apiService = ApiService();
  List<Ticket> _ticketsCerrados = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTicketsCerrados();
  }

  Future<void> _loadTicketsCerrados() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final tickets = await _apiService.getTickets(estado: 3);
      setState(() {
        _ticketsCerrados = tickets;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 160,
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        flexibleSpace: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Image.asset(
                'assets/sena_logo.png',
                height: 120,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 120,
                    height: 120,
                    color: Colors.grey[800],
                    child: const Icon(Icons.business, color: Colors.white),
                  );
                },
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    'Servicios TIC Sena Regional Guainía',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '/ Inicio / Solicitudes Cerradas',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Solicitudes Cerradas',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _loadTicketsCerrados,
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
                              headingRowColor: MaterialStateProperty.all(const Color(0xFFE0F7F7)),
                              columnSpacing: isSmallScreen ? 10 : 20,
                              horizontalMargin: isSmallScreen ? 10 : 24,
                              columns: [
                                DataColumn(
                                  label: Text('ID', 
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 12 : 14,
                                      fontWeight: FontWeight.bold
                                    )
                                  ), 
                                  numeric: true
                                ),
                                if (!isSmallScreen) 
                                  DataColumn(
                                    label: Text('Fecha',
                                      style: TextStyle(fontSize: isSmallScreen ? 12 : 14,
                                      fontWeight: FontWeight.bold
                                      )
                                    )
                                  ),
                                DataColumn(
                                  label: Text('Solicitante',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 12 : 14,
                                      fontWeight: FontWeight.bold
                                    )
                                  )
                                ),
                                if (!isSmallScreen) 
                                  DataColumn(
                                    label: Text('Dependencia',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 12 : 14,
                                        fontWeight: FontWeight.bold
                                      )
                                    )
                                  ),
                                DataColumn(
                                  label: Text('Descripción',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 12 : 14,
                                      fontWeight: FontWeight.bold
                                    )
                                  ),
                                  tooltip: 'Haz clic en el ícono de información para ver la descripción completa',
                                ),
                                DataColumn(
                                  label: Text('Estado',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 12 : 14,
                                      fontWeight: FontWeight.bold
                                    )
                                  )
                                ),
                                if (!isMediumScreen)
                                  DataColumn(
                                    label: Text('Tipo de Servicio',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 12 : 14,
                                        fontWeight: FontWeight.bold
                                      )
                                    )
                                  ),
                                DataColumn(
                                  label: Text('Personal Asignado',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 12 : 14,
                                      fontWeight: FontWeight.bold
                                    )
                                  )
                                ),
                                DataColumn(
                                  label: Text('Acciones',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 12 : 14,
                                      fontWeight: FontWeight.bold
                                    )
                                  )
                                ),
                              ],
                              rows: _ticketsCerrados.map((ticket) {
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
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          ticket.estado ?? 'Cerrada',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: isSmallScreen ? 11 : 13
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (!isMediumScreen)
                                      DataCell(
                                        Text(
                                          ticket.tipoServicio ?? '-',
                                          style: TextStyle(fontSize: isSmallScreen ? 11 : 13),
                                        )
                                      ),
                                    DataCell(
                                      Text(
                                        ticket.personalAsignado ?? '-',
                                        style: TextStyle(fontSize: isSmallScreen ? 11 : 13),
                                      )
                                    ),
                                    DataCell(
                                      IconButton(
                                        icon: Icon(Icons.info, color: Colors.blue, size: isSmallScreen ? 18 : 24),
                                        onPressed: () => _showTicketDetails(ticket),
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

  void _showTicketDetails(Ticket ticket) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles de la Solicitud Cerrada'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('ID', ticket.id.toString()),
              _detailRow('Fecha de Reporte', DateFormat('dd/MM/yyyy').format(ticket.fechaReporte)),
              _detailRow('Solicitante', '${ticket.nombresSolicitante} ${ticket.apellidosSolicitante}'),
              _detailRow('Correo', ticket.correoSolicitante),
              _detailRow('Contacto', ticket.numeroContacto),
              _detailRow('Dependencia', ticket.dependencia),
              _detailRow('Estado', ticket.estado ?? 'No asignado'),
              _detailRow('Tipo de Servicio', ticket.tipoServicio ?? 'No asignado'),
              _detailRow('Personal Asignado', ticket.personalAsignado ?? 'No asignado'),
              if (ticket.fechaCreacion != null)
                _detailRow('Fecha de Creación', DateFormat('dd/MM/yyyy HH:mm').format(ticket.fechaCreacion!)),
              if (ticket.fechaCierre != null)
                _detailRow('Fecha de Cierre', DateFormat('dd/MM/yyyy HH:mm').format(ticket.fechaCierre!)),
              const Divider(),
              const Text('Descripción:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(ticket.descripcion),
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
}
