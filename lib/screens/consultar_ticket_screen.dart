import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ticket_model.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class ConsultarTicketScreen extends StatefulWidget {
  const ConsultarTicketScreen({super.key});

  @override
  State<ConsultarTicketScreen> createState() => _ConsultarTicketScreenState();
}

class _ConsultarTicketScreenState extends State<ConsultarTicketScreen> {
  final TextEditingController _ticketIdController = TextEditingController();
  final ApiService _apiService = ApiService();
  Ticket? _ticket;
  bool _isLoading = false;
  String? _error;
  bool _searched = false;

  Future<void> _searchTicket() async {
    if (_ticketIdController.text.isEmpty) {
      setState(() {
        _error = 'Por favor, ingrese un número de ticket.';
        _searched = true;
        _ticket = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _searched = true;
      _ticket = null;
    });

    try {
      final ticketId = int.parse(_ticketIdController.text);
      final ticket = await _apiService.getTicketDetails(ticketId);
      setState(() {
        _ticket = ticket;
      });
    } catch (e) {
      setState(() {
        _error = 'No se encontró el ticket o hubo un error al buscarlo.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 800;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: isSmallScreen ? 80 : 160,
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
        flexibleSpace: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8.0 : 16.0),
            child: Row(
              children: [
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
                SizedBox(width: isSmallScreen ? 8 : 16),
                Image.asset(
                  'assets/sena_logo.png',
                  height: isSmallScreen ? 40 : 120,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: isSmallScreen ? 40 : 120,
                      height: isSmallScreen ? 40 : 120,
                      color: Colors.grey[800],
                      child: const Icon(Icons.business, color: Colors.white),
                    );
                  },
                ),
                SizedBox(width: isSmallScreen ? 8 : 16),
                // Si tienes el logo de miayudaTIC, descomenta la siguiente línea y pon la ruta correcta:
                // Image.asset('assets/miayudatic_logo.png', height: isSmallScreen ? 40 : 120),
                Expanded(
                  child: Text(
                    'Servicios TIC Sena Regional Guainía',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 15 : 20,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 56 : 68),
              ],
            ),
          ),
        ),
      ),
      drawer: const AppDrawer(currentRoute: '/consultar-ticket'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _ticketIdController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Número de Ticket (ID)',
                hintText: 'Ingrese el ID del ticket a consultar',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchTicket,
                ),
              ),
              onSubmitted: (_) => _searchTicket(),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 16))
            else if (_searched && _ticket == null)
              const Text('No se encontró ningún ticket con ese ID.', style: TextStyle(fontSize: 16))
            else if (_ticket != null)
              _buildTicketDetails(_ticket!)
            else
              const Text('Ingrese un ID para buscar un ticket.', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketDetails(Ticket ticket) {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
          if (isMobile) {
            // Vista tipo ficha/tabla vertical para móvil
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Table(
                          columnWidths: const {
                            0: IntrinsicColumnWidth(),
                            1: FlexColumnWidth(),
                          },
                          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                          children: [
                            TableRow(children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Text('ID:', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Text(ticket.id.toString()),
                              ),
                            ]),
                            TableRow(children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Text('Fecha:', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Text(DateFormat('dd/MM/yyyy').format(ticket.fechaReporte)),
                              ),
                            ]),
                            TableRow(children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Text('Solicitante:', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Text('${ticket.nombresSolicitante} ${ticket.apellidosSolicitante}'),
                              ),
                            ]),
                            TableRow(children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Text('Dependencia:', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Text(ticket.dependencia),
                              ),
                            ]),
                            TableRow(children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Text('Estado:', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(ticket.estado),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(ticket.estado ?? 'No asignado', style: const TextStyle(color: Colors.white)),
                                ),
                              ),
                            ]),
                            TableRow(children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Text('Tipo de Servicio:', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Text(ticket.tipoServicio ?? 'No asignado'),
                              ),
                            ]),
                            TableRow(children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Text('Personal Asignado:', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Text(ticket.personalAsignado ?? 'No asignado'),
                              ),
                            ]),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text('Descripción:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(ticket.descripcion),
                        const Divider(),
                        if (ticket.fechaCreacion != null)
                          Text('Fecha de Creación: 	${DateFormat('dd/MM/yyyy HH:mm').format(ticket.fechaCreacion!)}'),
                        if (ticket.fechaCierre != null)
                          Text('Fecha de Cierre: 	${DateFormat('dd/MM/yyyy HH:mm').format(ticket.fechaCierre!)}'),
                      ],
                    ),
                  ),
                ),
              ),
            );
          } else {
            // Vista tipo tabla para escritorio
            return Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(const Color(0xFFE0F7F7)),
                          columns: const [
                            DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                            DataColumn(label: Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Solicitante', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Dependencia', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Descripción', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Tipo de Servicio', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Personal Asignado', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Fecha de Cierre', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: [
                            DataRow(
                              cells: [
                                DataCell(Text(ticket.id.toString())),
                                DataCell(Text(DateFormat('dd/MM/yyyy').format(ticket.fechaReporte))),
                                DataCell(Text('${ticket.nombresSolicitante} ${ticket.apellidosSolicitante}')),
                                DataCell(Text(ticket.dependencia)),
                                DataCell(
                                  Text(
                                    ticket.descripcion,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                DataCell(Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(ticket.estado),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(ticket.estado ?? 'No asignado', style: const TextStyle(color: Colors.white)),
                                )),
                                DataCell(Text(ticket.tipoServicio ?? 'No asignado')),
                                DataCell(Text(ticket.personalAsignado ?? 'No asignado')),
                                DataCell(ticket.fechaCierre != null
                                    ? Text(DateFormat('dd/MM/yyyy').format(ticket.fechaCierre!))
                                    : const Text('-')),
                                DataCell(
                                  IconButton(
                                    icon: const Icon(Icons.info, color: Colors.blue),
                                    tooltip: 'Ver detalles completos',
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Detalles del Ticket'),
                                          content: SingleChildScrollView(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                _detailRow('ID', ticket.id.toString()),
                                                _detailRow('Fecha', DateFormat('dd/MM/yyyy').format(ticket.fechaReporte)),
                                                _detailRow('Solicitante', '${ticket.nombresSolicitante} ${ticket.apellidosSolicitante}'),
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
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 900),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Descripción completa:', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(
                              ticket.descripcion,
                              style: const TextStyle(fontSize: 15),
                              softWrap: true,
                              overflow: TextOverflow.visible,
                            ),
                            const Divider(),
                            if (ticket.fechaCreacion != null)
                              Text('Fecha de Creación: ${DateFormat('dd/MM/yyyy HH:mm').format(ticket.fechaCreacion!)}'),
                            if (ticket.fechaCierre != null)
                              Text('Fecha de Cierre: ${DateFormat('dd/MM/yyyy HH:mm').format(ticket.fechaCierre!)}'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: color != null
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(value, style: const TextStyle(color: Colors.white)),
                  )
                : Text(value),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    return status == 'Cerrada' ? Colors.green : Colors.red;
  }
} 