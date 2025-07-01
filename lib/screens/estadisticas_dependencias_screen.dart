import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'dart:typed_data';
import 'dart:html' as html;
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class EstadisticasDependenciasScreen extends StatefulWidget {
  const EstadisticasDependenciasScreen({super.key});

  @override
  State<EstadisticasDependenciasScreen> createState() => _EstadisticasDependenciasScreenState();
}

class _EstadisticasDependenciasScreenState extends State<EstadisticasDependenciasScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _error;
  List<dynamic> _ticketsCerrados = [];
  Map<String, int> _cerradosPorDependencia = {};
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  DateTime? _fechaInicioTemp;
  DateTime? _fechaFinTemp;

  @override
  void initState() {
    super.initState();
    _loadData();
    _fechaInicioTemp = _fechaInicio;
    _fechaFinTemp = _fechaFin;
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final tickets = await _apiService.getTickets(estado: 3); // 3 = Cerrada
      setState(() {
        _ticketsCerrados = tickets;
      });
      _filtrarYContar();
    } catch (e) {
      setState(() {
        _error = 'Error al cargar datos: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filtrarYContar() {
    final inicio = _fechaInicio;
    final fin = _fechaFin;
    final Map<String, int> agrupados = {};
    for (var t in _ticketsCerrados) {
      final fechaCierre = t.fechaCierre;
      if (fechaCierre != null &&
          (inicio == null || !fechaCierre.isBefore(inicio)) &&
          (fin == null || !fechaCierre.isAfter(fin))) {
        final dependencia = t.dependencia ?? 'Sin dependencia';
        agrupados[dependencia] = (agrupados[dependencia] ?? 0) + 1;
      }
    }
    setState(() {
      _cerradosPorDependencia = agrupados;
    });
  }

  Future<void> _selectFechaInicio() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaInicioTemp ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _fechaInicioTemp = picked;
      });
    }
  }

  Future<void> _selectFechaFin() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaFinTemp ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _fechaFinTemp = picked;
      });
    }
  }

  void _aplicarFiltro() {
    setState(() {
      _fechaInicio = _fechaInicioTemp;
      _fechaFin = _fechaFinTemp;
    });
    _filtrarYContar();
  }

  void _exportarExcel() {
    final excel = Excel.createExcel();
    final sheet = excel['Estadísticas'];
    sheet.appendRow(['Dependencia', 'Órdenes Cerradas']);
    _cerradosPorDependencia.forEach((nombre, cantidad) {
      sheet.appendRow([nombre, cantidad]);
    });
    final fileBytes = excel.encode();
    if (fileBytes != null) {
      final blob = html.Blob([Uint8List.fromList(fileBytes)]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'estadisticas_dependencias_tic.xlsx')
        ..click();
      html.Url.revokeObjectUrl(url);
    }
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
      drawer: const AppDrawer(currentRoute: '/estadisticas-dependencias'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                : _cerradosPorDependencia.isEmpty
                    ? const Center(child: Text('No hay órdenes cerradas para mostrar.'))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Órdenes Cerradas por Dependencia',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isMobile = constraints.maxWidth < 600;
                              if (isMobile) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: _selectFechaInicio,
                                            icon: const Icon(Icons.date_range),
                                            label: Text(_fechaInicioTemp == null ? 'Fecha inicio' : DateFormat('dd/MM/yyyy').format(_fechaInicioTemp!)),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: _selectFechaFin,
                                            icon: const Icon(Icons.date_range),
                                            label: Text(_fechaFinTemp == null ? 'Fecha fin' : DateFormat('dd/MM/yyyy').format(_fechaFinTemp!)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: _aplicarFiltro,
                                            icon: const Icon(Icons.search),
                                            label: const Text('Buscar'),
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[400], foregroundColor: Colors.white),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: _exportarExcel,
                                            icon: const Icon(Icons.download),
                                            label: const Text('Exportar a Excel'),
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[400], foregroundColor: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              } else {
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: _selectFechaInicio,
                                      icon: const Icon(Icons.date_range),
                                      label: Text(_fechaInicioTemp == null ? 'Fecha inicio' : DateFormat('dd/MM/yyyy').format(_fechaInicioTemp!)),
                                    ),
                                    const SizedBox(width: 12),
                                    OutlinedButton.icon(
                                      onPressed: _selectFechaFin,
                                      icon: const Icon(Icons.date_range),
                                      label: Text(_fechaFinTemp == null ? 'Fecha fin' : DateFormat('dd/MM/yyyy').format(_fechaFinTemp!)),
                                    ),
                                    const SizedBox(width: 12),
                                    Row(
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: _aplicarFiltro,
                                          icon: const Icon(Icons.search),
                                          label: const Text('Buscar'),
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[400], foregroundColor: Colors.white),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          onPressed: _exportarExcel,
                                          icon: const Icon(Icons.download),
                                          label: const Text('Exportar a Excel'),
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green[400], foregroundColor: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 24),
                          Expanded(
                            child: _cerradosPorDependencia.isEmpty
                                ? const Center(child: Text('No hay datos para mostrar.'))
                                : BarChart(
                                    BarChartData(
                                      alignment: BarChartAlignment.spaceAround,
                                      maxY: (_cerradosPorDependencia.values.isEmpty ? 1 : _cerradosPorDependencia.values.reduce((a, b) => a > b ? a : b).toDouble() + 1),
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
                                              if (idx < 0 || idx >= _cerradosPorDependencia.keys.length) return const SizedBox();
                                              final nombre = _cerradosPorDependencia.keys.elementAt(idx);
                                              return Padding(
                                                padding: const EdgeInsets.only(top: 8.0),
                                                child: Text(
                                                  nombre.length > 10 ? nombre.substring(0, 10) + '…' : nombre,
                                                  style: const TextStyle(fontSize: 12),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      ),
                                      borderData: FlBorderData(show: false),
                                      barGroups: _cerradosPorDependencia.entries
                                          .toList()
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                        final idx = entry.key;
                                        final e = entry.value;
                                        final color = _barColors[idx % _barColors.length];
                                        return BarChartGroupData(
                                          x: idx,
                                          barRods: [
                                            BarChartRodData(
                                              toY: e.value.toDouble(),
                                              color: color,
                                              width: 28,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 24),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 16,
                            runSpacing: 8,
                            children: _cerradosPorDependencia.keys.map((nombre) {
                              final idx = _cerradosPorDependencia.keys.toList().indexOf(nombre);
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
                        ],
                      ),
      ),
    );
  }

  static const List<Color> _barColors = [
    Colors.blue, Color.fromARGB(255, 185, 194, 193), Colors.orange, Colors.yellow, Colors.red, Colors.cyan, Colors.teal, Colors.amber, Colors.pink, Colors.brown
  ];
} 