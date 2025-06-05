import 'package:flutter/material.dart';

class ReportarFallaScreen extends StatefulWidget {
  const ReportarFallaScreen({super.key});

  @override
  State<ReportarFallaScreen> createState() => _ReportarFallaScreenState();
}

class _ReportarFallaScreenState extends State<ReportarFallaScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _ubicacionController = TextEditingController();
  final TextEditingController _contactoController = TextEditingController();
  String? _selectedTipoFalla;

  final List<String> _tiposFalla = [
    'Hardware',
    'Software',
    'Redes',
    'Equipos especializados',
    'Otros',
  ];

  @override
  void dispose() {
    _descripcionController.dispose();
    _ubicacionController.dispose();
    _contactoController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Aquí iría la lógica para enviar el reporte
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reporte enviado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reportar Falla TIC')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Complete el formulario para reportar una falla',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Campo para tipo de falla
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Tipo de falla',
                  border: OutlineInputBorder(),
                ),
                value: _selectedTipoFalla,
                items:
                    _tiposFalla.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedTipoFalla = newValue;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Por favor seleccione un tipo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Campo para descripción
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción detallada',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese una descripción';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Campo para ubicación
              TextFormField(
                controller: _ubicacionController,
                decoration: const InputDecoration(
                  labelText: 'Ubicación/Dependencia',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese la ubicación';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Campo para contacto
              TextFormField(
                controller: _contactoController,
                decoration: const InputDecoration(
                  labelText: 'Número de contacto',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese un contacto';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 25),

              // Botón de enviar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Enviar Reporte',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Texto institucional
              const Text(
                'SENA Regional Guainía - Centro Ambiental y Ecoturístico'
                'del Nororiente Amazónico',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}