import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ticket_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import './details_screen.dart';
import '../widgets/app_drawer.dart';

class ComentariosModal extends StatefulWidget {
  final Ticket ticket;
  final ApiService? apiService;
  const ComentariosModal({Key? key, required this.ticket, this.apiService}) : super(key: key);

  @override
  State<ComentariosModal> createState() => _ComentariosModalState();
}

class _ComentariosModalState extends State<ComentariosModal> {
  List<Map<String, dynamic>> tecnicos = [];
  List<Map<String, dynamic>> comentarios = [];
  String? tecnicoSeleccionado;
  TextEditingController comentarioController = TextEditingController();
  bool isSaving = false;
  bool isLoading = true;
  String? errorMsg;

  ApiService get _apiService => widget.apiService ?? ApiService();

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    try {
      tecnicos = await _apiService.getSupportStaff().timeout(const Duration(seconds: 10));
      comentarios = await _apiService.getComentariosSolicitud(widget.ticket.id!).timeout(const Duration(seconds: 10));
      setState(() { isLoading = false; });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMsg = 'Error al cargar los datos: ' + e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const AlertDialog(
        content: SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
      );
    }
    if (errorMsg != null) {
      return AlertDialog(
        title: const Text('Error'),
        content: Text(errorMsg!),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      );
    }
    return AlertDialog(
      title: Text('Comentarios de la Solicitud #${widget.ticket.id}'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (comentarios.isEmpty)
              const Text('No hay comentarios aún.'),
            if (comentarios.isNotEmpty)
              SizedBox(
                height: 150,
                child: ListView.builder(
                  itemCount: comentarios.length,
                  itemBuilder: (context, index) {
                    final c = comentarios[index];
                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text('${c['nombre_tecnico'] ?? (c['nombre'] ?? '') + ' ' + (c['apellido'] ?? '')}'),
                      subtitle: Text(c['comentario'] ?? ''),
                      trailing: Text(c['fecha_comentario'] ?? ''),
                    );
                  },
                ),
              ),
            const Divider(),
            DropdownButtonFormField<String>(
              value: tecnicoSeleccionado,
              decoration: const InputDecoration(
                labelText: 'Seleccionar Técnico',
                border: OutlineInputBorder(),
              ),
              items: tecnicos.map((t) {
                final nombreCompleto = '${t['nombre']} ${t['apellido']}';
                return DropdownMenuItem<String>(
                  value: t['id_usuario'].toString(),
                  child: Text(nombreCompleto),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  tecnicoSeleccionado = value;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: comentarioController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Agregar comentario',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
        ElevatedButton(
          onPressed: isSaving
            ? null
            : () async {
                if (tecnicoSeleccionado == null || comentarioController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Seleccione un técnico y escriba un comentario.')),
                  );
                  return;
                }
                setState(() { isSaving = true; });
                final ok = await _apiService.addComentarioSolicitud(
                  widget.ticket.id!,
                  int.parse(tecnicoSeleccionado!),
                  comentarioController.text.trim(),
                );
                if (ok) {
                  comentarioController.clear();
                  tecnicoSeleccionado = null;
                  comentarios = await _apiService.getComentariosSolicitud(widget.ticket.id!);
                  setState(() { isSaving = false; });
                } else {
                  setState(() { isSaving = false; });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error al guardar el comentario.')),
                  );
                }
              },
          child: isSaving ? const CircularProgressIndicator() : const Text('Guardar'),
        ),
      ],
    );
  }
}

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
  int _currentPage = 0;
  static const int _rowsPerPage = 10;

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

      final tickets = await _apiService.getTickets(estado: 1);
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
              child: const Text('Copiar'),
              onPressed: () {
                final allDetails = StringBuffer()
                  ..writeln('ID: ${details.id}')
                  ..writeln('Fecha de Reporte: ${DateFormat('dd/MM/yyyy').format(details.fechaReporte)}')
                  ..writeln('Solicitante: ${details.nombresSolicitante} ${details.apellidosSolicitante}')
                  ..writeln('Correo: ${details.correoSolicitante}')
                  ..writeln('Contacto: ${details.numeroContacto}')
                  ..writeln('Dependencia: ${details.dependencia}')
                  ..writeln('Estado: ${details.estado ?? 'No asignado'}')
                  ..writeln('Tipo de Servicio: ${details.tipoServicio ?? 'No asignado'}')
                  ..writeln('Personal Asignado: ${details.personalAsignado ?? 'No asignado'}');

                if (details.fechaCreacion != null) {
                  allDetails.writeln('Fecha de Creación: ${DateFormat('dd/MM/yyyy HH:mm').format(details.fechaCreacion!)}');
                }
                if (details.fechaCierre != null) {
                  allDetails.writeln('Fecha de Cierre: ${DateFormat('dd/MM/yyyy HH:mm').format(details.fechaCierre!)}');
                }
                allDetails.writeln('Descripción: ${details.descripcion}');

                Clipboard.setData(ClipboardData(text: allDetails.toString()));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Detalles copiados al portapapeles')),
                );
              },
            ),
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
      String? tipoServicioNombre = ticket.tipoServicio;

      if (serviceType != null) {
        final serviceTypeData = _serviceTypes.firstWhere(
          (type) => type['nombre_tipo_servicio'] == serviceType,
          orElse: () => throw Exception('Tipo de servicio no encontrado'),
        );
        updates['id_tipo_servicio'] = int.parse(serviceTypeData['id_tipo_servicio'].toString());
        tipoServicioNombre = serviceTypeData['nombre_tipo_servicio'];
      }

      int? idPersonalAsignado;
      if (staffName != null) {
        if (tipoServicioNombre == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Primero seleccione el tipo de servicio antes de asignar técnico.'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        final staffData = _supportStaff.firstWhere(
          (staff) => staff['nombre_completo'] == staffName,
          orElse: () => throw Exception('Personal no encontrado'),
        );
        updates['id_personal_ti_asignado'] = int.parse(staffData['id_usuario'].toString());
        idPersonalAsignado = int.parse(staffData['id_usuario'].toString());
      }

      await _apiService.updateTicket(ticket.id!, updates);
      await _loadTickets();

      // Si se asignó técnico y hay tipo de servicio, enviar correo
      if (idPersonalAsignado != null && tipoServicioNombre != null) {
        await _apiService.enviarCorreoAsignacion(
          idSolicitud: ticket.id!,
          idPersonalAsignado: idPersonalAsignado,
          tipoServicio: tipoServicioNombre,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Correo de asignación enviado al técnico'),
            backgroundColor: Colors.blue,
          ),
        );
      }

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

  Widget _buildMobileTicketCard(Ticket ticket, bool isSmallScreen) {
    return Stack(
      children: [
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () => Navigator.pushNamed(
              context,
              '/case-details',
              arguments: {'caseId': ticket.id.toString()},
            ),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('ID: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(ticket.id.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      const Text('Estado: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(ticket.estado),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          (ticket.estado != null && ticket.estado!.isNotEmpty) ? ticket.estado! : 'Abierta',
                          style: TextStyle(
                            color: (ticket.estado == 'Abierta' || ticket.estado == null || ticket.estado!.isEmpty)
                                ? Colors.black
                                : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Solicitante: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(child: Text('${ticket.nombresSolicitante} ${ticket.apellidosSolicitante}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('Dependencia: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(child: Text(ticket.dependencia)),
                      const Text('Fecha: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(DateFormat('dd/MM/yyyy').format(ticket.fechaReporte)),
                    ],
                  ),
                  const Divider(height: 24),
                  const Text('Descripción:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    ticket.descripcion,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Tipo de Servicio',
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 14),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.teal.shade100),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.teal.shade100),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: ticket.tipoServicio,
                          hint: const Text('Seleccionar'),
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.teal),
                          items: _serviceTypes.map((type) {
                            return DropdownMenuItem<String>(
                              value: type['nombre_tipo_servicio'],
                              child: Text(type['nombre_tipo_servicio']),
                            );
                          }).toList(),
                          onChanged: ticket.estado != 'Cerrada'
                              ? (String? newValue) => _assignTicket(ticket, newValue, null)
                              : null,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Personal Técnico',
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 14),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.teal.shade100),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.teal.shade100),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: ticket.personalAsignado,
                          hint: const Text('Seleccionar'),
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.teal),
                          items: _supportStaff.map((staff) {
                            return DropdownMenuItem<String>(
                              value: staff['nombre_completo'],
                              child: Text(staff['nombre_completo']),
                            );
                          }).toList(),
                          onChanged: (ticket.estado != 'Cerrada' && ticket.tipoServicio != null)
                              ? (String? newValue) => _assignTicket(ticket, null, newValue)
                              : null,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _showTicketDetails(ticket),
                        child: const Text('Ver Detalles'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.comment),
                        onPressed: () => _showCommentsModal(ticket),
                        color: Colors.orange,
                        tooltip: 'Ver/Agregar comentarios',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        // Retraso en días en la esquina superior derecha
        if (ticket.estado != 'Cerrada')
          Positioned(
            top: 8,
            right: 24,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _colorSemaforo(_diasAbierta(ticket.fechaReporte, ticket.estado)),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 4,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                '${_diasAbierta(ticket.fechaReporte, ticket.estado)}',
                style: TextStyle(
                  color: _textColorSemaforo(_colorSemaforo(_diasAbierta(ticket.fechaReporte, ticket.estado))),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 800;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: isSmallScreen ? 80 : 100,
        backgroundColor: const Color(0xFF04324D),
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
                  height: isSmallScreen ? 60 : 120,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: isSmallScreen ? 60 : 120,
                      height: isSmallScreen ? 60 : 120,
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
                    'Soporte TIC SENA Regional Guainía',
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
      drawer: const AppDrawer(currentRoute: '/support-dashboard'),
      body: _loadingMasterData
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '/ Inicio / Consola de Servicios',
                        style: TextStyle(fontSize: isSmallScreen ? 12 : 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                           Text(
                            'Solicitudes Abiertas',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 20 : 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _loadTickets,
                            icon: const Icon(Icons.refresh),
                            label: Text(isSmallScreen ? '' : 'Actualizar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.cyan[600],
                              foregroundColor: Colors.black,
                              shape: isSmallScreen ? const CircleBorder() : RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: EdgeInsets.all(isSmallScreen ? 12 : 16)
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
                  const Expanded(child: Center(child: CircularProgressIndicator()))
                else
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isLayoutSmall = constraints.maxWidth < 800;
                        final isLayoutMedium = constraints.maxWidth < 1200;
                        
                        // PAGINACIÓN: calcular el rango de tickets a mostrar
                        final int startIndex = _currentPage * _rowsPerPage;
                        final int endIndex = (_currentPage + 1) * _rowsPerPage;
                        final List<Ticket> paginatedTickets = _tickets.length > startIndex
                            ? _tickets.sublist(startIndex, endIndex > _tickets.length ? _tickets.length : endIndex)
                            : [];

                        final totalPages = (_tickets.length / _rowsPerPage).ceil();

                        Widget paginationControls = Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                              child: const Icon(Icons.chevron_left),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                'Página ${_currentPage + 1} de $totalPages',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: endIndex < _tickets.length ? () => setState(() => _currentPage++) : null,
                              child: const Icon(Icons.chevron_right),
                            ),
                          ],
                        );

                        if (isLayoutSmall) {
                          return Column(
                            children: [
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  itemCount: paginatedTickets.length,
                                  itemBuilder: (context, index) {
                                    return _buildMobileTicketCard(paginatedTickets[index], isLayoutSmall);
                                  },
                                ),
                              ),
                              if (totalPages > 1) Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: paginationControls,
                              )
                            ],
                          );
                        }
                        
                        // VISTA DE TABLA PARA ESCRITORIO
                        return Column(
                          children: [
                            Expanded(
                              child: Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                                elevation: 6,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                      child: DataTable(
                                        headingRowColor: MaterialStateProperty.all(const Color(0xFF39A900)),
                                        columnSpacing: isLayoutSmall ? 10 : 20,
                                        horizontalMargin: isLayoutSmall ? 10 : 24,
                                        columns: [
                                          const DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                                          if (!isLayoutSmall) const DataColumn(label: Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold))),
                                          const DataColumn(label: Text('Solicitante', style: TextStyle(fontWeight: FontWeight.bold))),
                                          if (!isLayoutSmall) const DataColumn(label: Text('Dependencia', style: TextStyle(fontWeight: FontWeight.bold))),
                                          const DataColumn(label: Text('Descripción', style: TextStyle(fontWeight: FontWeight.bold))),
                                          const DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
                                          const DataColumn(label: Text('Retraso en días', style: TextStyle(fontWeight: FontWeight.bold))),
                                          if (!isLayoutMedium) const DataColumn(label: Text('Tipo de Servicio', style: TextStyle(fontWeight: FontWeight.bold))),
                                          const DataColumn(label: Text('Personal Asignado', style: TextStyle(fontWeight: FontWeight.bold))),
                                          const DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
                                        ],
                                        rows: paginatedTickets.map((ticket) {
                                          return DataRow(
                                            cells: [
                                              DataCell(Text(ticket.id.toString())),
                                              if (!isLayoutSmall) DataCell(Text(DateFormat('dd/MM/yyyy').format(ticket.fechaReporte))),
                                              DataCell(Text('${ticket.nombresSolicitante} ${ticket.apellidosSolicitante}')),
                                              if (!isLayoutSmall) DataCell(Text(ticket.dependencia)),
                                              DataCell(
                                                SizedBox(
                                                  width: isLayoutSmall ? 100 : 200,
                                                  child: Text(
                                                    ticket.descripcion,
                                                    overflow: TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: _getStatusColor(ticket.estado),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: ticket.estado == 'Abierta'
                                                        ? Border.all(color: const Color(0xFF04324D), width: 2)
                                                        : null,
                                                  ),
                                                  child: Text(
                                                    (ticket.estado != null && ticket.estado!.isNotEmpty) ? ticket.estado! : 'Abierta',
                                                    style: TextStyle(
                                                      color: (ticket.estado == 'Abierta' || ticket.estado == null || ticket.estado!.isEmpty)
                                                          ? Colors.black
                                                          : Colors.white,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                ticket.estado != 'Cerrada'
                                                  ? Container(
                                                      width: 32, height: 32,
                                                      decoration: BoxDecoration(
                                                        color: _colorSemaforo(_diasAbierta(ticket.fechaReporte, ticket.estado)),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      alignment: Alignment.center,
                                                      child: Text(
                                                        '${_diasAbierta(ticket.fechaReporte, ticket.estado)}',
                                                        style: TextStyle(
                                                          color: _textColorSemaforo(_colorSemaforo(_diasAbierta(ticket.fechaReporte, ticket.estado))),
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    )
                                                  : const Text('-'),
                                              ),
                                              if (!isLayoutMedium)
                                                DataCell(
                                                  DropdownButton<String>(
                                                    value: ticket.tipoServicio,
                                                    hint: const Text('Seleccionar'),
                                                    items: _serviceTypes.map((type) {
                                                      return DropdownMenuItem<String>(
                                                        value: type['nombre_tipo_servicio'],
                                                        child: Text(type['nombre_tipo_servicio']),
                                                      );
                                                    }).toList(),
                                                    onChanged: ticket.estado != 'Cerrada' ? (String? newValue) => _assignTicket(ticket, newValue, null) : null,
                                                  ),
                                                ),
                                              DataCell(
                                                Tooltip(
                                                  message: (ticket.tipoServicio == null)
                                                      ? 'Para asignar el personal técnico debe seleccionar primero el tipo de servicio'
                                                      : '',
                                                  child: DropdownButton<String>(
                                                    value: ticket.personalAsignado,
                                                    hint: const Text('Asignar'),
                                                    items: _supportStaff.map((staff) {
                                                      return DropdownMenuItem<String>(
                                                        value: staff['nombre_completo'],
                                                        child: Text(staff['nombre_completo']),
                                                      );
                                                    }).toList(),
                                                    onChanged: (ticket.estado != 'Cerrada' && ticket.tipoServicio != null)
                                                        ? (String? newValue) => _assignTicket(ticket, null, newValue)
                                                        : null,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(Icons.info),
                                                      onPressed: () => _showTicketDetails(ticket),
                                                      color: Colors.blue,
                                                      tooltip: 'Ver detalles completos',
                                                    ),
                                                    if (ticket.estado != 'Cerrada')
                                                      IconButton(
                                                        icon: const Icon(Icons.check_circle),
                                                        onPressed: () => Navigator.pushNamed(
                                                          context,
                                                          '/case-details',
                                                          arguments: {'caseId': ticket.id.toString()},
                                                        ),
                                                        color: Colors.green,
                                                        tooltip: 'Cerrar caso',
                                                      ),
                                                    IconButton(
                                                      icon: const Icon(Icons.comment),
                                                      onPressed: () => _showCommentsModal(ticket),
                                                      color: Colors.orange,
                                                      tooltip: 'Ver/Agregar comentarios',
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
                              ),
                            ),
                             if (totalPages > 1) Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: paginationControls,
                              )
                          ],
                        );
                      },
                    ),
                  ),
              ],
            ),
    );
  }

  Color _getStatusColor(String? status) {
    if (status == 'Cerrada') {
      return Colors.green;
    } else if (status == 'Abierta' || status == null || status.isEmpty) {
      return const Color(0xFF039900); // O usa Colors.grey[300] para un gris claro
    } else {
      return Colors.orange;
    }
  }

  // Calcula los días que lleva abierta una solicitud
  int _diasAbierta(DateTime fechaReporte, String? estado) {
    if (estado != 'Cerrada') {
      final ahora = DateTime.now();
      return ahora.difference(fechaReporte).inDays;
    }
    return 0;
  }

  Color _colorSemaforo(int dias) {
    if (dias >= 4) return Colors.red;
    if (dias >= 2) return Colors.orange;
    return Colors.green;
  }

  Color _textColorSemaforo(Color bg) {
    // Usa blanco para rojo y naranja, negro para verde claro
    return bg == Colors.green ? Colors.black : Colors.white;
  }

  void _showCommentsModal(Ticket ticket) {
    showDialog(
      context: context,
      builder: (context) => ComentariosModal(ticket: ticket, apiService: _apiService),
    );
  }
} 