import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'dart:typed_data';
import 'dart:html' as html;
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';
import '../models/ticket_model.dart';
import 'package:flutter/foundation.dart';

class SolicitudesCerradasDependenciasScreen extends StatefulWidget {
  const SolicitudesCerradasDependenciasScreen({super.key});

  @override
  State<SolicitudesCerradasDependenciasScreen> createState() => _SolicitudesCerradasDependenciasScreenState();
}

class _SolicitudesCerradasDependenciasScreenState extends State<SolicitudesCerradasDependenciasScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _error;
  List<Ticket> _ticketsCerrados = [];
  List<Map<String, dynamic>> _dependencias = [];
  final ValueNotifier<String> _dependenciaSeleccionada = ValueNotifier('');
  final ValueNotifier<DateTime?> _fechaInicio = ValueNotifier(null);
  final ValueNotifier<DateTime?> _fechaFin = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _dependenciaSeleccionada.dispose();
    _fechaInicio.dispose();
    _fechaFin.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final deps = await _apiService.getDependencies();
      final tickets = await _apiService.getTickets(estado: 3); // 3 = Cerrada
      setState(() {
        _dependencias = deps;
        _ticketsCerrados = tickets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar datos: $e';
        _isLoading = false;
      });
    }
  }

  List<Ticket> _filtrarTickets(List<Ticket> tickets, String dep, DateTime? inicio, DateTime? fin) {
    return tickets.where((t) {
      final fechaCierre = t.fechaCierre;
      final d = t.dependencia ?? 'Sin dependencia';
      return fechaCierre != null &&
        (inicio == null || !fechaCierre.isBefore(inicio)) &&
        (fin == null || !fechaCierre.isAfter(fin)) &&
        (dep == '' || d == dep);
    }).toList();
  }

  Map<String, int> _agrupadosPorDependencia(List<Ticket> tickets) {
    final Map<String, int> agrupados = {};
    for (var t in tickets) {
      final dep = t.dependencia ?? 'Sin dependencia';
      agrupados[dep] = (agrupados[dep] ?? 0) + 1;
    }
    return agrupados;
  }

  void _exportarExcel(List<Ticket> tickets) {
    final excel = Excel.createExcel();
    final sheet = excel['Estadísticas'];
    sheet.appendRow(['ID', 'Fecha Cierre', 'Dependencia', 'Solicitante', 'Descripción', 'Tipo Servicio', 'Personal Asignado', 'Solución']);
    for (var t in tickets) {
      sheet.appendRow([
        t.id?.toString() ?? '',
        t.fechaCierre != null ? DateFormat('dd/MM/yyyy').format(t.fechaCierre!) : '-',
        t.dependencia ?? '-',
        '${t.nombresSolicitante} ${t.apellidosSolicitante}',
        t.descripcion,
        t.tipoServicio ?? '-',
        t.personalAsignado ?? '-',
        t.descripcionSolucion ?? '-',
      ]);
    }
    final fileBytes = excel.encode();
    if (fileBytes != null) {
      final blob = html.Blob([Uint8List.fromList(fileBytes)]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'solicitudes_cerradas_dependencias.xlsx')
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  Future<void> _selectFecha(ValueNotifier<DateTime?> target, DateTime? initial) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      target.value = picked;
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
      drawer: const AppDrawer(currentRoute: '/solicitudes-cerradas-dependencias'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                : ValueListenableBuilder3<String, DateTime?, DateTime?>(
                    _dependenciaSeleccionada, _fechaInicio, _fechaFin,
                    builder: (context, dep, inicio, fin, _) {
                      final ticketsFiltrados = _filtrarTickets(_ticketsCerrados, dep, inicio, fin);
                      final cerradosPorDep = _agrupadosPorDependencia(ticketsFiltrados);
                      return ticketsFiltrados.isEmpty
                          ? const Center(child: Text('No hay órdenes cerradas para mostrar.'))
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'Órdenes Cerradas por Dependencia',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () => _selectFecha(_fechaInicio, inicio),
                                        icon: const Icon(Icons.date_range),
                                        label: Text(inicio != null ? DateFormat('dd/MM/yyyy').format(inicio) : 'Fecha inicio'),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        onPressed: () => _selectFecha(_fechaFin, fin),
                                        icon: const Icon(Icons.date_range),
                                        label: Text(fin != null ? DateFormat('dd/MM/yyyy').format(fin) : 'Fecha fin'),
                                      ),
                                      const SizedBox(width: 8),
                                      DropdownButton<String>(
                                        value: dep,
                                        hint: const Text('Todas las dependencias'),
                                        items: [
                                          const DropdownMenuItem<String>(
                                            value: '',
                                            child: Text('Todas las dependencias'),
                                          ),
                                          ..._dependencias.map((d) => DropdownMenuItem<String>(
                                                value: d['nombre_dependencia'],
                                                child: Text(d['nombre_dependencia']),
                                              )),
                                        ],
                                        onChanged: (value) => _dependenciaSeleccionada.value = value ?? '',
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        onPressed: () => _exportarExcel(ticketsFiltrados),
                                        icon: const Icon(Icons.download),
                                        label: const Text('Exportar Excel'),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  height: 300,
                                  child: BarChart(
                                    BarChartData(
                                      alignment: BarChartAlignment.spaceAround,
                                      maxY: (cerradosPorDep.values.isNotEmpty ? cerradosPorDep.values.reduce((a, b) => a > b ? a : b) + 2 : 10).toDouble(),
                                      barTouchData: BarTouchData(enabled: true),
                                      titlesData: FlTitlesData(
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                                        ),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget: (double value, TitleMeta meta) {
                                              final idx = value.toInt();
                                              if (idx < 0 || idx >= cerradosPorDep.keys.length) return const SizedBox();
                                              final nombre = cerradosPorDep.keys.elementAt(idx);
                                              return Padding(
                                                padding: const EdgeInsets.only(top: 8.0),
                                                child: Text(nombre, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                                              );
                                            },
                                          ),
                                        ),
                                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      ),
                                      borderData: FlBorderData(show: false),
                                      barGroups: List.generate(cerradosPorDep.length, (idx) {
                                        final nombre = cerradosPorDep.keys.elementAt(idx);
                                        final cantidad = cerradosPorDep[nombre] ?? 0;
                                        return BarChartGroupData(
                                          x: idx,
                                          barRods: [
                                            BarChartRodData(
                                              toY: cantidad.toDouble(),
                                              color: _barColors[idx % _barColors.length],
                                              width: 24,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                          ],
                                        );
                                      }),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 16,
                                  runSpacing: 8,
                                  children: cerradosPorDep.keys.map((nombre) {
                                    final idx = cerradosPorDep.keys.toList().indexOf(nombre);
                                    final color = _barColors[idx % _barColors.length];
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(width: 16, height: 16, color: color),
                                        const SizedBox(width: 6),
                                        Text(nombre, style: const TextStyle(fontSize: 14)),
                                      ],
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 32),
                                const Text('Detalle de tickets filtrados', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: isSmallScreen
                                      ? ListView(
                                          children: ticketsFiltrados.map<Widget>((t) => Card(
                                            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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
                                                      Text('ID: ${t.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                                                  Text('${t.nombresSolicitante} ${t.apellidosSolicitante}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                                                  const SizedBox(height: 2),
                                                  Text(t.dependencia, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                                                  const SizedBox(height: 8),
                                                  Text(t.descripcion, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      if (t.personalAsignado != null)
                                                        Flexible(
                                                          child: Chip(
                                                            avatar: const Icon(Icons.person, size: 16),
                                                            label: Text(t.personalAsignado!, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                                                            backgroundColor: Colors.grey[200],
                                                          ),
                                                        )
                                                      else
                                                        const Text('Sin asignar', style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                                                      const Spacer(),
                                                      if (t.fechaCierre != null)
                                                        Text(DateFormat('dd/MM/yyyy').format(t.fechaCierre!), style: const TextStyle(fontSize: 13)),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Align(
                                                    alignment: Alignment.centerRight,
                                                    child: TextButton.icon(
                                                      onPressed: () {
                                                        showDialog(
                                                          context: context,
                                                          builder: (context) => AlertDialog(
                                                            title: const Text('Detalles de la Solicitud Cerrada'),
                                                            content: SingleChildScrollView(
                                                              child: Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: [
                                                                  _detailRow('ID', t.id.toString()),
                                                                  _detailRow('Fecha de Cierre', t.fechaCierre != null ? DateFormat('dd/MM/yyyy').format(t.fechaCierre!) : '-'),
                                                                  _detailRow('Dependencia', t.dependencia),
                                                                  _detailRow('Solicitante', '${t.nombresSolicitante} ${t.apellidosSolicitante}'),
                                                                  _detailRow('Correo', t.correoSolicitante),
                                                                  _detailRow('Contacto', t.numeroContacto),
                                                                  _detailRow('Tipo de Servicio', t.tipoServicio ?? '-'),
                                                                  _detailRow('Personal Asignado', t.personalAsignado ?? '-'),
                                                                  if (t.descripcionSolucion != null && t.descripcionSolucion!.isNotEmpty)
                                                                    ...[
                                                                      const Divider(),
                                                                      const Text('Solución:', style: TextStyle(fontWeight: FontWeight.bold)),
                                                                      const SizedBox(height: 8),
                                                                      Text(t.descripcionSolucion!),
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
                                                      },
                                                      icon: const Icon(Icons.info, color: Colors.blue, size: 19),
                                                      label: const Text('Detalles', style: TextStyle(fontSize: 15)),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )).toList(),
                                        )
                                      : SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: DataTable(
                                            columns: const [
                                              DataColumn(label: Text('ID')),
                                              DataColumn(label: Text('Fecha Cierre')),
                                              DataColumn(label: Text('Dependencia')),
                                              DataColumn(label: Text('Solicitante')),
                                              DataColumn(label: Text('Descripción')),
                                              DataColumn(label: Text('Tipo Servicio')),
                                              DataColumn(label: Text('Personal Asignado')),
                                              DataColumn(label: Text('Solución')),
                                            ],
                                            rows: ticketsFiltrados.map<DataRow>((t) => DataRow(
                                              cells: [
                                                DataCell(Text(t.id?.toString() ?? '')),
                                                DataCell(Text(t.fechaCierre != null ? DateFormat('dd/MM/yyyy').format(t.fechaCierre!) : '-')),
                                                DataCell(Text(t.dependencia ?? '-')),
                                                DataCell(Text('${t.nombresSolicitante} ${t.apellidosSolicitante}')),
                                                DataCell(Text(t.descripcion, maxLines: 2, overflow: TextOverflow.ellipsis)),
                                                DataCell(Text(t.tipoServicio ?? '-')),
                                                DataCell(Text(t.personalAsignado ?? '-')),
                                                DataCell(Text(t.descripcionSolucion ?? '-')),
                                              ],
                                            )).toList(),
                                          ),
                                        ),
                                ),
                              ],
                            );
                    }),
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

  static const List<Color> _barColors = [
    Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red, Colors.cyan, Colors.teal, Colors.amber, Colors.pink, Colors.brown
  ];
}

/// Helper para ValueListenableBuilder con 3 listenables
class ValueListenableBuilder3<A, B, C> extends StatelessWidget {
  final ValueListenable<A> first;
  final ValueListenable<B> second;
  final ValueListenable<C> third;
  final Widget Function(BuildContext, A, B, C, Widget?) builder;
  final Widget? child;
  const ValueListenableBuilder3(this.first, this.second, this.third, {required this.builder, this.child, super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: first,
      builder: (context, a, _) => ValueListenableBuilder<B>(
        valueListenable: second,
        builder: (context, b, _) => ValueListenableBuilder<C>(
          valueListenable: third,
          builder: (context, c, _) => builder(context, a, b, c, child),
        ),
      ),
    );
  }
} 