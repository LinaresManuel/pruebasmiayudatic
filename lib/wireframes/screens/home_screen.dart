import 'package:flutter/material.dart';
import 'details_screen.dart';

void main() {
  runApp(const HomeScreen());
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sena Regional Guainía',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const ConsoleScreen(),
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
      'assigned_to': null,
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
      'assigned_to': null,
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
      'assigned_to': null,
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
                                          builder: (context) => DetailsScreen(
                                            caseId: caseId,
                                            assignedTo: caseData['assigned_to'],
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
