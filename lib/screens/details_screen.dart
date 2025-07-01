import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/ticket_model.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../widgets/app_drawer.dart';

class DetailsScreen extends StatefulWidget {
  final String caseId;

  const DetailsScreen({
    Key? key,
    required this.caseId,
  }) : super(key: key);

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _error;
  Ticket? _ticketDetails;

  TextEditingController _nombreContratistaController = TextEditingController();
  TextEditingController _contactoContratistaController =
      TextEditingController();
  TextEditingController _descripcionSolucionController =
      TextEditingController();
  List<String> _evidenciasCargadas = [];

  @override
  void initState() {
    super.initState();
    _loadTicketDetails();
  }

  Future<void> _loadTicketDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final details =
          await _apiService.getTicketDetails(int.parse(widget.caseId));

      setState(() {
        _ticketDetails = details;
        // Pre-llenar el nombre del contratista si hay personal asignado
        _nombreContratistaController.text =
            details.personalAsignado ?? "Nombre del Técnico";
        _contactoContratistaController.text = "";
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
  void dispose() {
    _nombreContratistaController.dispose();
    _contactoContratistaController.dispose();
    _descripcionSolucionController.dispose();
    super.dispose();
  }

  void _pickFiles() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seleccionar tipo de evidencia'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tomar foto'),
                onTap: () async {
                  Navigator.pop(context);
                  final ImagePicker picker = ImagePicker();
                  final XFile? photo =
                      await picker.pickImage(source: ImageSource.camera);
                  if (photo != null) {
                    setState(() {
                      _evidenciasCargadas.add(photo.name);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Foto adjuntada correctamente'),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder),
                title: const Text('Seleccionar archivo'),
                onTap: () async {
                  Navigator.pop(context);
                  FilePickerResult? result =
                      await FilePicker.platform.pickFiles();
                  if (result != null) {
                    setState(() {
                      _evidenciasCargadas.add(result.files.single.name);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Archivo adjuntado correctamente'),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showConfirmationDialog() async {
    if (_ticketDetails == null) return;

    if (_descripcionSolucionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingrese la descripción de la solución.'),
        ),
      );
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Cierre de Caso'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Por favor confirme la siguiente información antes de cerrar el caso:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text('ID del Caso: ${widget.caseId}'),
                const SizedBox(height: 8),
                const Text('Descripción de la Solución:'),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(_descripcionSolucionController.text),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirmar Cierre'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _processClosure();
    }
  }

  Future<void> _processClosure() async {
    try {
      await _apiService.cerrarCasoYEnviarCorreo(
        idSolicitud: _ticketDetails!.id!,
        descripcionSolucion: _descripcionSolucionController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Caso cerrado y correos enviados exitosamente'),
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.of(context).pushReplacementNamed('/support-dashboard');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar el caso: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: const Color(0xFF04324D),
        automaticallyImplyLeading: false,
        flexibleSpace: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 400;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  Image.asset(
                    'assets/sena_logo.png',
                    height: isMobile ? 32 : 50,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: isMobile ? 32 : 50,
                        height: isMobile ? 32 : 50,
                        color: Colors.grey[800],
                        child: const Icon(Icons.business, color: Colors.white),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Servicios TIC Sena Regional Guainía',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 14 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      drawer: const AppDrawer(currentRoute: '/details'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error'),
                      ElevatedButton(
                        onPressed: _loadTicketDetails,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),

                      // TARJETA DE INFORMACIÓN DEL CASO
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.info_outline, color: Colors.teal),
                                  SizedBox(width: 10),
                                  Text(
                                    'Información del Caso',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              if (_ticketDetails != null) ...[
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isMobile = constraints.maxWidth < 700;
                                    if (isMobile) {
                                      // Vista vertical tipo ficha/tabla para móvil
                                      return Table(
                                        columnWidths: const {
                                          0: IntrinsicColumnWidth(),
                                          1: FlexColumnWidth(),
                                        },
                                        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                                        children: [
                                          TableRow(children: [
                                            const Padding(
                                              padding: EdgeInsets.symmetric(vertical: 4),
                                              child: Text('Fecha de Reporte:', style: TextStyle(fontWeight: FontWeight.bold)),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 4),
                                              child: Text(DateFormat('dd/MM/yyyy HH:mm').format(_ticketDetails!.fechaReporte)),
                                            ),
                                          ]),
                                          TableRow(children: [
                                            const Padding(
                                              padding: EdgeInsets.symmetric(vertical: 4),
                                              child: Text('Solicitante:', style: TextStyle(fontWeight: FontWeight.bold)),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 4),
                                              child: Text('${_ticketDetails!.nombresSolicitante} ${_ticketDetails!.apellidosSolicitante}'),
                                            ),
                                          ]),
                                          TableRow(children: [
                                            const Padding(
                                              padding: EdgeInsets.symmetric(vertical: 4),
                                              child: Text('Correo:', style: TextStyle(fontWeight: FontWeight.bold)),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 4),
                                              child: Text(_ticketDetails!.correoSolicitante),
                                            ),
                                          ]),
                                          TableRow(children: [
                                            const Padding(
                                              padding: EdgeInsets.symmetric(vertical: 4),
                                              child: Text('Contacto:', style: TextStyle(fontWeight: FontWeight.bold)),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 4),
                                              child: Text(_ticketDetails!.numeroContacto),
                                            ),
                                          ]),
                                          TableRow(children: [
                                            const Padding(
                                              padding: EdgeInsets.symmetric(vertical: 4),
                                              child: Text('Dependencia:', style: TextStyle(fontWeight: FontWeight.bold)),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 4),
                                              child: Text(_ticketDetails!.dependencia),
                                            ),
                                          ]),
                                          TableRow(children: [
                                            const Padding(
                                              padding: EdgeInsets.symmetric(vertical: 4),
                                              child: Text('Descripción:', style: TextStyle(fontWeight: FontWeight.bold)),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 4),
                                              child: Text(_ticketDetails!.descripcion),
                                            ),
                                          ]),
                                          TableRow(children: [
                                            const Padding(
                                              padding: EdgeInsets.symmetric(vertical: 4),
                                              child: Text('Estado:', style: TextStyle(fontWeight: FontWeight.bold)),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 4),
                                              child: Text(_ticketDetails!.estado ?? 'No asignado'),
                                            ),
                                          ]),
                                          if (_ticketDetails!.tipoServicio != null)
                                            TableRow(children: [
                                              const Padding(
                                                padding: EdgeInsets.symmetric(vertical: 4),
                                                child: Text('Tipo de Servicio:', style: TextStyle(fontWeight: FontWeight.bold)),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 4),
                                                child: Text(_ticketDetails!.tipoServicio!),
                                              ),
                                            ]),
                                          if (_ticketDetails!.personalAsignado != null)
                                            TableRow(children: [
                                              const Padding(
                                                padding: EdgeInsets.symmetric(vertical: 4),
                                                child: Text('Personal Asignado:', style: TextStyle(fontWeight: FontWeight.bold)),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 4),
                                                child: Text(_ticketDetails!.personalAsignado!),
                                              ),
                                            ]),
                                        ],
                                      );
                                    } else {
                                      // Vista horizontal (actual) para escritorio
                                      return Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(child: _infoColumn('Fecha de Reporte', DateFormat('dd/MM/yyyy HH:mm').format(_ticketDetails!.fechaReporte))),
                                          Expanded(child: _infoColumn('Solicitante', '${_ticketDetails!.nombresSolicitante} ${_ticketDetails!.apellidosSolicitante}')),
                                          Expanded(child: _infoColumn('Correo', _ticketDetails!.correoSolicitante)),
                                          Expanded(child: _infoColumn('Contacto', _ticketDetails!.numeroContacto)),
                                          Expanded(child: _infoColumn('Dependencia', _ticketDetails!.dependencia)),
                                          Expanded(child: _infoColumn('Descripción', _ticketDetails!.descripcion)),
                                          Expanded(child: _infoColumn('Estado', _ticketDetails!.estado ?? 'No asignado')),
                                          if (_ticketDetails!.tipoServicio != null)
                                            Expanded(child: _infoColumn('Tipo de Servicio', _ticketDetails!.tipoServicio!)),
                                          if (_ticketDetails!.personalAsignado != null)
                                            Expanded(child: _infoColumn('Personal Asignado', _ticketDetails!.personalAsignado!)),
                                        ],
                                      );
                                    }
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // TARJETA DE CIERRE DE CASO
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.lock, color: Colors.teal),
                                  SizedBox(width: 10),
                                  Text(
                                    'Cierre del Caso',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // CAJA: Nombre del Contratista
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.teal.shade300, width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.teal.withOpacity(0.18),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.7),
                                      blurRadius: 0,
                                      offset: const Offset(-2, -2),
                                    ),
                                  ],
                                ),
                                margin: const EdgeInsets.only(bottom: 14),
                                child: TextFormField(
                                  controller: _nombreContratistaController,
                                  enabled: false,
                                  decoration: InputDecoration(
                                    labelText: 'Nombre del Contratista',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    prefixIcon: const Icon(Icons.person),
                                    filled: true,
                                    fillColor: Colors.transparent,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                                  ),
                                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                                ),
                              ),
                              // CAJA: Teléfono / Extensión
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.teal.shade300, width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.teal.withOpacity(0.18),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.7),
                                      blurRadius: 0,
                                      offset: const Offset(-2, -2),
                                    ),
                                  ],
                                ),
                                margin: const EdgeInsets.only(bottom: 14),
                                child: TextFormField(
                                  controller: _contactoContratistaController,
                                  decoration: InputDecoration(
                                    labelText: 'Teléfono / Extensión',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    prefixIcon: const Icon(Icons.phone),
                                    filled: true,
                                    fillColor: Colors.transparent,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                                  ),
                                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                                ),
                              ),
                              // CAJA: Descripción de la Solución
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.teal.shade300, width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.teal.withOpacity(0.18),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.7),
                                      blurRadius: 0,
                                      offset: const Offset(-2, -2),
                                    ),
                                  ],
                                ),
                                margin: const EdgeInsets.only(bottom: 2),
                                child: TextFormField(
                                  controller: _descripcionSolucionController,
                                  maxLength: 500,
                                  decoration: InputDecoration(
                                    labelText: 'Descripción de la Solución',
                                    hintText: 'Explique cómo se resolvió el problema',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    prefixIcon: const Icon(Icons.description),
                                    filled: true,
                                    fillColor: Colors.transparent,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                                    counterText: '', // Oculta el contador por defecto
                                  ),
                                  maxLines: 5,
                                  minLines: 3,
                                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                                  onChanged: (_) {
                                    setState(() {});
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 8, bottom: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${500 - _descripcionSolucionController.text.length} caracteres restantes',
                                      style: TextStyle(
                                        color: (500 - _descripcionSolucionController.text.length) < 50 ? Colors.red : Colors.grey.shade700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              // BOTONES DE ACCIÓN Y EVIDENCIAS
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isMobile = constraints.maxWidth < 600;
                                  final buttonSpacing = isMobile ? const SizedBox(height: 12) : const SizedBox(width: 12);
                                  final List<Widget> buttonList = [
                                    ElevatedButton.icon(
                                      onPressed: _pickFiles,
                                      icon: const Icon(Icons.attach_file),
                                      label: const Text('Adjuntar Evidencia'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue.shade700,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        elevation: 2,
                                      ),
                                    ),
                                    if (_evidenciasCargadas.isNotEmpty)
                                      Flexible(
                                        child: Wrap(
                                          spacing: 6,
                                          children: _evidenciasCargadas.map((file) {
                                            return Chip(
                                              label: Text(file),
                                              avatar: const Icon(
                                                Icons.insert_drive_file,
                                                size: 16,
                                              ),
                                              backgroundColor: Colors.blue.shade50,
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    if (!isMobile) buttonSpacing,
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        if (Navigator.of(context).canPop()) {
                                          Navigator.of(context).pop();
                                        } else {
                                          Navigator.pushReplacementNamed(context, '/support-dashboard');
                                        }
                                      },
                                      icon: const Icon(Icons.cancel),
                                      label: const Text('Cancelar'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        side: const BorderSide(color: Colors.red),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                    if (!isMobile) buttonSpacing,
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Borrador guardado (simulado)!'),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.save_alt),
                                      label: const Text('Guardar Borrador'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.teal,
                                        side: const BorderSide(color: Colors.teal),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                    if (!isMobile) buttonSpacing,
                                    ElevatedButton.icon(
                                      onPressed: _showConfirmationDialog,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade700,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        elevation: 2,
                                      ),
                                      icon: const Icon(Icons.check_circle, color: Colors.white),
                                      label: const Text(
                                        'Cerrar Caso',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ];
                                  if (isMobile) {
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        ...buttonList.expand((w) => [w, buttonSpacing]).toList()..removeLast(),
                                      ],
                                    );
                                  } else {
                                    return Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: buttonList,
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Center(
                        child: Text(
                          '© 2025 SENA. Todos los derechos reservados.',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _infoColumn(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Text(value, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

