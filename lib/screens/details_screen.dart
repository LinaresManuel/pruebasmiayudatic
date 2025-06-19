import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/ticket_model.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

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
      final updates = {
        'id_estado': 3, // Estado "Cerrada"
        'fecha_cierre': DateTime.now().toIso8601String(),
        'descripcion_solucion': _descripcionSolucionController.text,
      };

      await _apiService.updateTicket(_ticketDetails!.id!, updates);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Caso cerrado exitosamente'),
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
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.pushReplacementNamed(context, '/support-dashboard');
            }
          },
        ),
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
            ],
          ),
        ),
      ),
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
                                _infoRow(
                                    'Fecha de Reporte:',
                                    DateFormat('dd/MM/yyyy HH:mm')
                                        .format(_ticketDetails!.fechaReporte)),
                                _infoRow('Solicitante:',
                                    '${_ticketDetails!.nombresSolicitante} ${_ticketDetails!.apellidosSolicitante}'),
                                _infoRow('Correo:',
                                    _ticketDetails!.correoSolicitante),
                                _infoRow('Contacto:',
                                    _ticketDetails!.numeroContacto),
                                _infoRow('Dependencia:',
                                    _ticketDetails!.dependencia),
                                _infoRow('Descripción:',
                                    _ticketDetails!.descripcion),
                                _infoRow('Estado:',
                                    _ticketDetails!.estado ?? 'No asignado'),
                                if (_ticketDetails!.tipoServicio != null)
                                  _infoRow('Tipo de Servicio:',
                                      _ticketDetails!.tipoServicio!),
                                if (_ticketDetails!.personalAsignado != null)
                                  _infoRow('Personal Asignado:',
                                      _ticketDetails!.personalAsignado!),
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
                              TextFormField(
                                controller: _nombreContratistaController,
                                enabled:
                                    false, // Deshabilitado porque viene de la asignación
                                decoration: const InputDecoration(
                                  labelText: 'Nombre del Contratista',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.person),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _contactoContratistaController,
                                decoration: const InputDecoration(
                                  labelText: 'Teléfono / Extensión',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.phone),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _descripcionSolucionController,
                                decoration: const InputDecoration(
                                  labelText: 'Descripción de la Solución',
                                  hintText:
                                      'Explique cómo se resolvió el problema',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.description),
                                ),
                                maxLines: 5,
                                minLines: 3,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _pickFiles,
                                    icon: const Icon(Icons.attach_file),
                                    label: const Text('Adjuntar Evidencia'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade700,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  if (_evidenciasCargadas.isNotEmpty)
                                    Expanded(
                                      child: Wrap(
                                        spacing: 6,
                                        children:
                                            _evidenciasCargadas.map((file) {
                                          return Chip(
                                            label: Text(file),
                                            avatar: const Icon(
                                              Icons.insert_drive_file,
                                              size: 16,
                                            ),
                                            backgroundColor:
                                                Colors.blue.shade50,
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      if (Navigator.of(context).canPop()) {
                                        Navigator.of(context).pop();
                                      } else {
                                        Navigator.pushReplacementNamed(
                                            context, '/support-dashboard');
                                      }
                                    },
                                    icon: const Icon(Icons.cancel),
                                    label: const Text('Cancelar'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Borrador guardado (simulado)!'),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.save_alt),
                                    label: const Text('Guardar Borrador'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.teal,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    onPressed: _showConfirmationDialog,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                    ),
                                    icon: const Icon(Icons.check_circle,
                                        color: Colors.white),
                                    label: const Text(
                                      'Cerrar Caso',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label ',
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
