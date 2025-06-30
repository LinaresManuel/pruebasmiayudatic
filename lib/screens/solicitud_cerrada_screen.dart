import 'package:flutter/material.dart';
import '../models/ticket_model.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import '../widgets/app_drawer.dart';
import 'dart:typed_data';
import 'package:excel/excel.dart' as ex;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;

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
  bool _isAscending = true;
  int _currentPage = 0;
  static const int _rowsPerPage = 10;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

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
        _sortTicketsByDate();
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

  void _sortTicketsByDate() {
    setState(() {
      _ticketsCerrados.sort((a, b) {
        final comparison = a.fechaReporte.compareTo(b.fechaReporte);
        return _isAscending ? comparison : -comparison;
      });
    });
  }

  List<Ticket> get _ticketsFiltrados {
    if (_fechaInicio == null || _fechaFin == null) return _ticketsCerrados;
    return _ticketsCerrados.where((t) {
      if (t.fechaCierre == null) return false;
      return !t.fechaCierre!.isBefore(_fechaInicio!) && !t.fechaCierre!.isAfter(_fechaFin!);
    }).toList();
  }

  Future<void> _selectFechaInicio() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _fechaInicio = picked;
      });
    }
  }

  Future<void> _selectFechaFin() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaFin ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _fechaFin = picked;
      });
    }
  }

  Future<void> _exportarExcel() async {
    final excel = ex.Excel.createExcel();
    final sheet = excel['Solicitudes Cerradas'];
    // Encabezados
    sheet.appendRow([
      'ID', 'Fecha de Reporte', 'Solicitante', 'Correo', 'Contacto', 'Dependencia', 'Estado', 'Tipo de Servicio', 'Personal Asignado', 'Fecha de Cierre', 'Descripción', 'Solución'
    ]);
    for (final t in _ticketsFiltrados) {
      sheet.appendRow([
        t.id,
        DateFormat('dd/MM/yyyy').format(t.fechaReporte),
        '${t.nombresSolicitante} ${t.apellidosSolicitante}',
        t.correoSolicitante,
        t.numeroContacto,
        t.dependencia,
        t.estado,
        t.tipoServicio,
        t.personalAsignado,
        t.fechaCierre != null ? DateFormat('dd/MM/yyyy').format(t.fechaCierre!) : '',
        t.descripcion,
        t.descripcionSolucion ?? '',
      ]);
    }
    final fileBytes = excel.encode();
    if (fileBytes != null) {
      await Printing.sharePdf(bytes: Uint8List.fromList(fileBytes), filename: 'solicitudes_cerradas.xlsx');
    }
  }

  Future<void> _exportarPDF() async {
    final pdf = pw.Document();
    final logoBytes = await rootBundle.load('assets/sena_logo.png');
    final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Row(
            children: [
              pw.Image(logo, height: 60),
              pw.SizedBox(width: 20),
              pw.Text('Solicitudes Cerradas', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            _fechaInicio != null && _fechaFin != null
                ? 'Desde: \\${DateFormat('dd/MM/yyyy').format(_fechaInicio!)}  Hasta: \\${DateFormat('dd/MM/yyyy').format(_fechaFin!)}'
                : '',
            style: pw.TextStyle(fontSize: 14),
          ),
          pw.SizedBox(height: 12),
          pw.Table.fromTextArray(
            headers: [
              'ID', 'Fecha de Reporte', 'Solicitante', 'Correo', 'Contacto', 'Dependencia', 'Estado', 'Tipo de Servicio', 'Personal Asignado', 'Fecha de Cierre', 'Descripción', 'Solución'
            ],
            data: _ticketsFiltrados.map((t) => [
              t.id,
              DateFormat('dd/MM/yyyy').format(t.fechaReporte),
              '${t.nombresSolicitante} ${t.apellidosSolicitante}',
              t.correoSolicitante,
              t.numeroContacto,
              t.dependencia,
              t.estado,
              t.tipoServicio,
              t.personalAsignado,
              t.fechaCierre != null ? DateFormat('dd/MM/yyyy').format(t.fechaCierre!) : '',
              t.descripcion,
              t.descripcionSolucion ?? '',
            ]).toList(),
            cellStyle: pw.TextStyle(fontSize: 8),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
          ),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 800;
    final isMediumScreen = MediaQuery.of(context).size.width < 1200;
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
      drawer: const AppDrawer(currentRoute: '/solicitud-cerrada'),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '/ Inicio / Solicitudes Cerradas',
                  style: TextStyle(fontSize: isSmallScreen ? 12 : 14, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    if (isMobile) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Solicitudes Cerradas',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _selectFechaInicio,
                                  icon: const Icon(Icons.date_range),
                                  label: Text(_fechaInicio == null ? 'Fecha inicio' : DateFormat('dd/MM/yyyy').format(_fechaInicio!)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _selectFechaFin,
                                  icon: const Icon(Icons.date_range),
                                  label: Text(_fechaFin == null ? 'Fecha fin' : DateFormat('dd/MM/yyyy').format(_fechaFin!)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _ticketsFiltrados.isNotEmpty ? _exportarExcel : null,
                                  icon: const Icon(Icons.download),
                                  label: const Text('Excel'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green[400], foregroundColor: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _ticketsFiltrados.isNotEmpty ? _exportarPDF : null,
                                  icon: const Icon(Icons.picture_as_pdf),
                                  label: const Text('PDF'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red[400], foregroundColor: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: _loadTicketsCerrados,
                                icon: const Icon(Icons.refresh),
                                tooltip: 'Actualizar',
                              ),
                            ],
                          ),
                        ],
                      );
                    } else {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Solicitudes Cerradas',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 18 : 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              OutlinedButton.icon(
                                onPressed: _selectFechaInicio,
                                icon: const Icon(Icons.date_range),
                                label: Text(_fechaInicio == null ? 'Fecha inicio' : DateFormat('dd/MM/yyyy').format(_fechaInicio!)),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: _selectFechaFin,
                                icon: const Icon(Icons.date_range),
                                label: Text(_fechaFin == null ? 'Fecha fin' : DateFormat('dd/MM/yyyy').format(_fechaFin!)),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: _ticketsFiltrados.isNotEmpty ? _exportarExcel : null,
                                icon: const Icon(Icons.download),
                                label: const Text('Excel'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green[400], foregroundColor: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: _ticketsFiltrados.isNotEmpty ? _exportarPDF : null,
                                icon: const Icon(Icons.picture_as_pdf),
                                label: const Text('PDF'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red[400], foregroundColor: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: _loadTicketsCerrados,
                                icon: const Icon(Icons.refresh),
                                tooltip: 'Actualizar',
                              ),
                            ],
                          ),
                        ],
                      );
                    }
                  },
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
                  if (isSmallScreen) {
                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: _ticketsFiltrados.length,
                      itemBuilder: (context, index) {
                        final ticket = _ticketsFiltrados[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('ID: ${ticket.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text('Cerrada', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('${ticket.nombresSolicitante} ${ticket.apellidosSolicitante}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 2),
                                Text(ticket.dependencia, style: TextStyle(color: Colors.grey[700], fontSize: 15)),
                                const SizedBox(height: 8),
                                Text(ticket.descripcion, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    if (ticket.personalAsignado != null)
                                      Flexible(
                                        child: Chip(
                                          avatar: const Icon(Icons.person, size: 16),
                                          label: Text(ticket.personalAsignado!, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                                          backgroundColor: Colors.grey[200],
                                        ),
                                      )
                                    else
                                      const Text('Sin asignar', style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                                    const Spacer(),
                                    if (ticket.fechaCierre != null)
                                      Text(DateFormat('dd/MM/yyyy').format(ticket.fechaCierre!), style: const TextStyle(fontSize: 13)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () => _showTicketDetails(ticket),
                                    icon: const Icon(Icons.info, color: Colors.blue, size: 19),
                                    label: const Text('Detalles', style: TextStyle(fontSize: 15)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                  // PAGINACIÓN: calcular el rango de tickets a mostrar
                  final int startIndex = _currentPage * _rowsPerPage;
                  final int endIndex = (_currentPage + 1) * _rowsPerPage;
                  final List<Ticket> paginatedTickets = _ticketsFiltrados.length > startIndex
                      ? _ticketsFiltrados.sublist(startIndex, endIndex > _ticketsFiltrados.length ? _ticketsFiltrados.length : endIndex)
                      : [];
                  final totalPages = (_ticketsFiltrados.length / _rowsPerPage).ceil();
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
                          'Página ${_currentPage + 1} de ${totalPages}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: endIndex < _ticketsFiltrados.length ? () => setState(() => _currentPage++) : null,
                        child: const Icon(Icons.chevron_right),
                      ),
                    ],
                  );
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
                                  columnSpacing: isSmallScreen ? 15 : 20,
                                  horizontalMargin: isSmallScreen ? 12 : 24,
                                  columns: [
                                    DataColumn(
                                      label: Text('ID',
                                        style: TextStyle(fontSize: isSmallScreen ? 15 : 16, fontWeight: FontWeight.bold)),
                                      numeric: true
                                    ),
                                    if (!isSmallScreen)
                                      DataColumn(
                                        label: Text('Fecha', style: TextStyle(fontSize: isSmallScreen ? 15 : 16, fontWeight: FontWeight.bold)),
                                      ),
                                    DataColumn(
                                      label: Text('Solicitante', style: TextStyle(fontSize: isSmallScreen ? 15 : 16, fontWeight: FontWeight.bold)),
                                    ),
                                    if (!isSmallScreen)
                                      DataColumn(
                                        label: Text('Dependencia', style: TextStyle(fontSize: isSmallScreen ? 15 : 16, fontWeight: FontWeight.bold)),
                                      ),
                                    DataColumn(
                                      label: Text('Descripción', style: TextStyle(fontSize: isSmallScreen ? 15 : 16, fontWeight: FontWeight.bold)),
                                      tooltip: 'Haz clic en el ícono de información para ver la descripción completa',
                                    ),
                                    DataColumn(
                                      label: Text('Estado', style: TextStyle(fontSize: isSmallScreen ? 15 : 16, fontWeight: FontWeight.bold)),
                                    ),
                                    if (!isMediumScreen)
                                      DataColumn(
                                        label: Text('Tipo de Servicio', style: TextStyle(fontSize: isSmallScreen ? 15 : 16, fontWeight: FontWeight.bold)),
                                      ),
                                    DataColumn(
                                      label: Text('Personal Asignado', style: TextStyle(fontSize: isSmallScreen ? 15 : 16, fontWeight: FontWeight.bold)),
                                    ),
                                    DataColumn(
                                      label: Text('Fecha de Cierre', style: TextStyle(fontSize: isSmallScreen ? 15 : 16, fontWeight: FontWeight.bold)),
                                    ),
                                    DataColumn(
                                      label: Text('Acciones', style: TextStyle(fontSize: isSmallScreen ? 15 : 16, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                  rows: paginatedTickets.map((ticket) {
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Text(ticket.id.toString(), style: TextStyle(fontSize: isSmallScreen ? 15 : 16)),
                                        ),
                                        if (!isSmallScreen)
                                          DataCell(
                                            Text(DateFormat('dd/MM/yyyy').format(ticket.fechaReporte), style: TextStyle(fontSize: isSmallScreen ? 15 : 16)),
                                          ),
                                        DataCell(
                                          Text('${ticket.nombresSolicitante} ${ticket.apellidosSolicitante}', style: TextStyle(fontSize: isSmallScreen ? 15 : 16)),
                                        ),
                                        if (!isSmallScreen)
                                          DataCell(
                                            Text(ticket.dependencia, style: TextStyle(fontSize: isSmallScreen ? 15 : 16)),
                                          ),
                                        DataCell(
                                          SizedBox(
                                            width: isSmallScreen ? 120 : 220,
                                            child: Text(ticket.descripcion, overflow: TextOverflow.ellipsis, maxLines: 1, style: TextStyle(fontSize: isSmallScreen ? 15 : 16)),
                                          ),
                                        ),
                                        DataCell(
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 6 : 10, vertical: isSmallScreen ? 3 : 5),
                                            decoration: BoxDecoration(
                                              color: Colors.lightGreen,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(ticket.estado ?? 'Cerrada', style: TextStyle(color: Colors.white, fontSize: isSmallScreen ? 15 : 16)),
                                          ),
                                        ),
                                        if (!isMediumScreen)
                                          DataCell(
                                            Text(ticket.tipoServicio ?? '-', style: TextStyle(fontSize: isSmallScreen ? 15 : 16)),
                                          ),
                                        DataCell(
                                          Text(ticket.personalAsignado ?? '-', style: TextStyle(fontSize: isSmallScreen ? 15 : 16)),
                                        ),
                                        DataCell(
                                          ticket.fechaCierre != null
                                            ? Text(DateFormat('dd/MM/yyyy').format(ticket.fechaCierre!), style: TextStyle(fontSize: isSmallScreen ? 15 : 16))
                                            : Text('-', style: TextStyle(fontSize: isSmallScreen ? 15 : 16)),
                                        ),
                                        DataCell(
                                          IconButton(
                                            icon: Icon(Icons.info, color: Colors.blue, size: isSmallScreen ? 19 : 24),
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
                        ),
                      ),
                      if (totalPages > 1) Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: paginationControls,
                      ),
                    ],
                  );
                },
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
              if (ticket.descripcionSolucion != null && ticket.descripcionSolucion!.isNotEmpty) ...[
                const Divider(),
                const Text('Solución:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(ticket.descripcionSolucion!),
              ],
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

