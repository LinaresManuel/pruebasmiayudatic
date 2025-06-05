import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sena Regional Guainía',
      theme: ThemeData(
        primarySwatch: Colors.green, // Assuming a green primary color
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const ConsoleScreen(),
    );
  }
}

// New screen for Case Details
class DetailsScreen extends StatefulWidget {
  final String caseId;
  final String? assignedTo;

  const DetailsScreen({Key? key, required this.caseId, this.assignedTo})
    : super(key: key);

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  TextEditingController _nombreContratistaController = TextEditingController();
  TextEditingController _contactoContratistaController =
      TextEditingController();
  TextEditingController _descripcionSolucionController =
      TextEditingController();

  String? _estadoFinalSeleccionado;
  List<String> _evidenciasCargadas = [];

  @override
  void initState() {
    super.initState();
    _nombreContratistaController.text = "Nombre del Técnico (pre-llenado)";
    _contactoContratistaController.text = "Ext: 12345";
  }

  @override
  void dispose() {
    _nombreContratistaController.dispose();
    _contactoContratistaController.dispose();
    _descripcionSolucionController.dispose();
    super.dispose();
  }

  void _pickFiles() {
    setState(() {
      _evidenciasCargadas.add("evidencia_foto_01.jpg");
      _evidenciasCargadas.add("informe_tecnico.pdf");
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Archivos de evidencia adjuntados (simulado)!'),
      ),
    );
  }

  void _simularNotificacionFuncionario() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('¡Notificación al funcionario!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mark_email_read, color: Colors.teal, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Estimado funcionario, su caso "${widget.caseId}" ha sido cerrado exitosamente.\n\nGracias por usar la plataforma de soporte. Si tiene más inquietudes, no dude en contactarnos.',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Aceptar'),
              ),
            ],
          ),
    );
  }

  void _closeCase() {
    if (_descripcionSolucionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingrese la descripción de la solución.'),
        ),
      );
      return;
    }
    if (_estadoFinalSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, seleccione el estado final del caso.'),
        ),
      );
      return;
    }

    print("Cerrando caso " + widget.caseId);
    print("Nombre: " + _nombreContratistaController.text);
    print("Contacto: " + _contactoContratistaController.text);
    print("Descripción Solución: " + _descripcionSolucionController.text);
    print("Estado Final: $_estadoFinalSeleccionado");
    print("Evidencias: $_evidenciasCargadas");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Caso ${widget.caseId} cerrado exitosamente!')),
    );

    Future.delayed(const Duration(milliseconds: 800), () {
      _simularNotificacionFuncionario();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.teal.shade800,
        title: const Text('Detalle del Caso'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        // Eliminado el banner de debug
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // HERO HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade800, Colors.teal.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.support_agent,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'CASO ID: "+widget.caseId+"',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Resumen del problema reportado y estado actual.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
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
                    const Text(
                      '31/05/2025 11:44 AM - Solicitud de mantenimiento preventivo aire acondicionado',
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: const [
                        Icon(Icons.flag, size: 20, color: Colors.orange),
                        SizedBox(width: 6),
                        Text(
                          'Estado: Pendiente',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
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
                        hintText: 'Explique cómo se resolvió el problema',
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
                                      backgroundColor: Colors.blue.shade50,
                                    );
                                  }).toList(),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _estadoFinalSeleccionado,
                      hint: const Text('Seleccione el estado final'),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.check_circle_outline),
                      ),
                      items:
                          <String>['Cerrado'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _estadoFinalSeleccionado = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
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
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _closeCase,
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Cerrar Caso'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
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
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Convert ConsoleScreen to StatefulWidget
class ConsoleScreen extends StatefulWidget {
  const ConsoleScreen({super.key});

  @override
  State<ConsoleScreen> createState() => _ConsoleScreenState();
}

class _ConsoleScreenState extends State<ConsoleScreen> {
  // Sample data for cases, now only containing 'Servicio' type
  // Added 'assigned_to' field, initialized to null
  List<Map<String, String?>> _cases = [
    {
      'id': 'SERV01',
      'tipo': 'Servicio',
      'estado': 'Cerrado',
      'creacion': '2025-05-14 09:00',
      'usuario_asig': 'Usuario 1',
      'descripcion': 'Solicitud de mantenimiento preventivo aire acondicionado',
      'funcionario_reporta': 'Pepito Perez',
      'dependencia': 'Ambiente DucjIn',
      'assigned_to': null, // Initially not assigned
    },
    {
      'id': 'SERV02',
      'tipo': 'Servicio',
      'estado': 'Abierto',
      'creacion': '2025-05-15 10:30',
      'usuario_asig': 'Usuario 2',
      'descripcion':
          'Configuración de software de contabilidad en equipo nuevo',
      'funcionario_reporta': 'Maria Lopez',
      'dependencia': 'Administración',
      'assigned_to': null, // Initially not assigned
    },
    {
      'id': 'SERV03',
      'tipo': 'Servicio',
      'estado': 'Pendiente',
      'creacion': '2025-05-16 11:00',
      'usuario_asig': 'Usuario 3',
      'descripcion': 'Asistencia para conexión a la red inalámbrica en aula 5',
      'funcionario_reporta': 'Juan Garcia',
      'dependencia': 'Aula 5',
      'assigned_to': null, // Initially not assigned
    },
  ];

  // List of possible assignees
  final List<String> _assigneeRoles = const [
    'DINAMIZADOR TIC',
    'SP (ANALISTA DE SOPORTE EN SITIO)',
    'ANALISTA DE REDES',
    'TEC AIRES ACONDICIONADO ENERGIA REGULADA',
  ];

  // Method to show the assignment dialog
  void _showAssignDialog(BuildContext context, String caseId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Asignar Caso $caseId'),
          content: SingleChildScrollView(
            child: ListBody(
              children:
                  _assigneeRoles.map((role) {
                    return GestureDetector(
                      onTap: () {
                        _assignCase(caseId, role);
                        Navigator.of(dialogContext).pop(); // Close the dialog
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(role, style: const TextStyle(fontSize: 16)),
                      ),
                    );
                  }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Method to update the assigned person for a case
  void _assignCase(String caseId, String assignedPerson) {
    setState(() {
      final index = _cases.indexWhere((caseItem) => caseItem['id'] == caseId);
      if (index != -1) {
        _cases[index]['assigned_to'] = assignedPerson;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80, // Adjust height as needed
        backgroundColor: Colors.black, // Background color of the AppBar
        flexibleSpace: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // Placeholder for your actual image asset
                  // Image.asset(
                  //   'assets/miayuda_tic_logo.png', // You'll need to add this image to your assets
                  //   height: 50, // Adjust size as needed
                  // ),
                  Container(
                    width: 50,
                    height: 50,
                    color: Colors.grey, // Placeholder for logo
                    child: const Icon(Icons.business, color: Colors.white),
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
              // Placeholder for your actual image asset
              // Image.asset(
              //   'assets/sena_logo.png', // You'll need to add this image to your assets
              //   height: 50, // Adjust size as needed
              // ),
              Container(
                width: 50,
                height: 50,
                color: Colors.grey, // Placeholder for logo
                child: const Icon(Icons.school, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '/ Inicio / Consola',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Consola de casos',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        SizedBox(
                          width: 200, // Adjust width as needed
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Buscar...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(5),
                                borderSide: const BorderSide(
                                  color: Colors.grey,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 0,
                                horizontal: 10,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        TextButton(
                          onPressed: () {
                            // TODO: Implement borrar filtros functionality
                          },
                          child: const Text(
                            'Borrar Filtros',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth:
                      MediaQuery.of(context).size.width -
                      32, // Adjust based on padding
                ),
                child: DataTable(
                  columnSpacing: 25, // Increased spacing for better readability
                  dataRowMinHeight: 48, // Minimum height for data rows
                  dataRowMaxHeight: 60, // Maximum height for data rows
                  headingRowColor: MaterialStateProperty.resolveWith<Color?>((
                    Set<MaterialState> states,
                  ) {
                    return Colors
                        .grey
                        .shade200; // Light grey for header background
                  }),
                  border: TableBorder.all(
                    color: Colors.grey.shade300,
                    width: 1,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  columns: const [
                    DataColumn(
                      label: Text(
                        'ID Caso',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Tipo',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Estado',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'F. Creación',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Usuario Asig.',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Descripción del caso',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Funcionario que reporta',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Dependencia',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Asignar',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  rows:
                      _cases.map((caseData) {
                        final String caseId = caseData['id']!;
                        final String? assignedTo = caseData['assigned_to'];

                        return DataRow(
                          cells: [
                            DataCell(Text(caseId)),
                            DataCell(Text(caseData['tipo']!)),
                            DataCell(Text(caseData['estado']!)),
                            DataCell(Text(caseData['creacion']!)),
                            DataCell(Text(caseData['usuario_asig']!)),
                            DataCell(
                              SizedBox(
                                width:
                                    250, // Fixed width for description to prevent overflow
                                child: Text(
                                  caseData['descripcion']!,
                                  overflow:
                                      TextOverflow
                                          .ellipsis, // Add ellipsis for long text
                                  maxLines: 2, // Allow text to wrap to 2 lines
                                ),
                              ),
                            ),
                            DataCell(Text(caseData['funcionario_reporta']!)),
                            DataCell(Text(caseData['dependencia']!)),
                            DataCell(
                              // Conditional display for 'Asignar' column
                              assignedTo != null
                                  ? InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => DetailsScreen(
                                                caseId: caseId,
                                                assignedTo: assignedTo,
                                              ),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      assignedTo,
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  )
                                  : IconButton(
                                    icon: const Icon(Icons.person),
                                    onPressed: () {
                                      _showAssignDialog(context, caseId);
                                    },
                                  ),
                            ),
                          ],
                          // Removed onSelectChanged from DataRow to prioritize 'Asignar' click
                          // If you want the whole row to be clickable AND the 'Asignar' cell
                          // you'd need more complex logic or decide which one takes precedence.
                          // For this request, we prioritize the 'Asignar' cell click after assignment.
                        );
                      }).toList(),
                ),
              ),
            ),
          ),
          // Adding a small padding at the bottom to ensure content doesn't get cut off if scrollbar is active
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
