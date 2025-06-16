import 'package:flutter/material.dart';

class EncuestaScreen extends StatefulWidget {
  @override
  _EncuestaScreenState createState() => _EncuestaScreenState();
}

class _EncuestaScreenState extends State<EncuestaScreen> {
  // Variables para almacenar las respuestas
  String solucionSolicitud = '';
  String satisfaccion = '';
  String tiempoRespuesta = '';
  String facilidadServicio = '';
  String recomendacion = '';

  Widget buildRadioGroup(String title, List<String> options, String groupValue, void Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        ...options.map((option) {
          return RadioListTile<String>(
            title: Text(option),
            value: option,
            groupValue: groupValue,
            onChanged: onChanged,
          );
        }).toList(),
        SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Evaluación de la Experiencia')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Apreciado usuario, de acuerdo con la ley 1581 de 2012... (resumen del aviso legal)',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 20),
            buildRadioGroup(
              '¿Le dimos solución a tu solicitud? (obligatoria)',
              ['Sí', 'No'],
              solucionSolicitud,
              (value) => setState(() => solucionSolicitud = value!),
            ),
            buildRadioGroup(
              '¿Qué tan satisfecho te encuentras con la atención brindada a tu solicitud? (obligatoria)',
              ['Muy insatisfecho', 'Insatisfecho', 'Neutral', 'Satisfecho', 'Muy satisfecho'],
              satisfaccion,
              (value) => setState(() => satisfaccion = value!),
            ),
            buildRadioGroup(
              '¿El tiempo de respuesta para tu solicitud fue acorde a lo pactado? (obligatoria)',
              [
                'Mucho más lento de lo pactado',
                'Un poco más lento de lo pactado',
                'A tiempo',
                'Un poco más rápido de lo pactado',
                'Mucho más rápido de lo pactado'
              ],
              tiempoRespuesta,
              (value) => setState(() => tiempoRespuesta = value!),
            ),
            buildRadioGroup(
              '¿Qué tan fácil fue para ti solicitar el servicio? (obligatoria)',
              ['Muy difícil', 'Difícil', 'Neutral', 'Fácil', 'Muy fácil'],
              facilidadServicio,
              (value) => setState(() => facilidadServicio = value!),
            ),
            buildRadioGroup(
              'En términos generales, ¿recomendarías la mesa de servicio? (obligatoria)',
              ['Sí', 'No'],
              recomendacion,
              (value) => setState(() => recomendacion = value!),
            ),
            ElevatedButton(
              onPressed: () {
                // Aquí podrías manejar el envío de datos o validaciones
                print('Encuesta enviada');
              },
              child: Text('Enviar'),
            ),
          ],
        ),
      ),
    );
  }
}
