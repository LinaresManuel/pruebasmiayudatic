import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ticket_model.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class ConsultarEstadoScreen extends StatefulWidget {
  const ConsultarEstadoScreen({super.key});

  @override
  State<ConsultarEstadoScreen> createState() => _ConsultarEstadoScreenState();
}

class _ConsultarEstadoScreenState extends State<ConsultarEstadoScreen> {
  final TextEditingController _ticketIdController = TextEditingController();
  final ApiService _apiService = ApiService();
  Ticket? _ticket;
  List<Map<String, dynamic>> _comentarios = [];
  bool _isLoading = false;
  String? _error;
  bool _searched = false;
  late final DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    Future.delayed(const Duration(seconds: 90), () {
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  Future<void> _searchTicket() async {
    if (_ticketIdController.text.isEmpty) {
      setState(() {
        _error = 'Por favor, ingrese un número de ticket.';
        _searched = true;
        _ticket = null;
        _comentarios = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _searched = true;
      _ticket = null;
      _comentarios = [];
    });

    try {
      final ticketId = int.parse(_ticketIdController.text);
      final ticket = await _apiService.getTicketDetails(ticketId);
      final comentarios = await _apiService.getComentariosSolicitud(ticketId);
      setState(() {
        _ticket = ticket;
        _comentarios = comentarios;
      });
    } catch (e) {
      setState(() {
        _error = 'No se encontró el ticket o hubo un error al buscarlo.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
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
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8.0 : 16.0),
            child: Row(
              children: [
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 18),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF39A900).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF39A900), width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF39A900)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'El número de ticket se encuentra en el correo electrónico que recibió al momento de reportar la falla. Le recomendamos revisar también la carpeta de spam o correo no deseado.',
                      style: const TextStyle(color: Color(0xFF04324D), fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF39A900),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  elevation: 2,
                ),
                icon: const Icon(Icons.arrow_back, size: 20),
                label: const Text('Volver', style: TextStyle(fontSize: 15)),
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ),
            const Text(
              'Ingrese un N° de ticket para buscar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF04324D),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 300,
              margin: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade600.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _ticketIdController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 4,
                decoration: InputDecoration(
                  labelText: 'Número de Ticket',
                  hintText: '0000',
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Colors.black, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Colors.black, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Colors.black, width: 2),
                  ),
                  suffixIcon: Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: const Icon(Icons.search, color: Colors.black),
                      onPressed: _searchTicket,
                    ),
                  ),
                ),
                onSubmitted: (_) => _searchTicket(),
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 16))
            else if (_searched && _ticket == null)
              const Text('No se encontró ningún ticket con ese ID.', style: TextStyle(fontSize: 16))
            else if (_ticket != null)
              Expanded(child: _buildTicketDetails(_ticket!, _comentarios)),
          ],
        ),
      ),
      floatingActionButton: null,
    );
  }

  Widget _buildTicketDetails(Ticket ticket, List<Map<String, dynamic>> comentarios) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isMobile ? 900 : 1300),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if ((ticket.estado ?? '').toLowerCase() == 'cerrada')
                      Container(
                        margin: const EdgeInsets.only(bottom: 18),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF39A900).withOpacity(0.18),
                          border: Border.all(color: const Color(0xFF39A900), width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Color(0xFF39A900), size: 28),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'La orden de servicio técnico ya fue cerrada.',
                                style: TextStyle(
                                  color: Color(0xFF04324D),
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 16 : 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    _buildInfoCard(ticket, isMobile),
                    _buildCommentsCard(comentarios, isMobile),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if ((ticket.estado ?? '').toLowerCase() == 'cerrada')
                            Container(
                              margin: const EdgeInsets.only(bottom: 18),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF39A900).withOpacity(0.18),
                                border: Border.all(color: const Color(0xFF39A900), width: 2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Color(0xFF39A900), size: 28),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      'La orden de servicio técnico ya fue cerrada.',
                                      style: TextStyle(
                                        color: Color(0xFF04324D),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          _buildInfoCard(ticket, false),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      flex: 2,
                      child: _buildCommentsCard(comentarios, false),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(Ticket ticket, bool isMobile) {
    return Card(
      elevation: 6,
      margin: EdgeInsets.symmetric(vertical: isMobile ? 16 : 32, horizontal: isMobile ? 8 : 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 24.0 : 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF39A900),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.all(isMobile ? 8 : 16),
                  child: Icon(Icons.info, color: Colors.white, size: isMobile ? 28 : 40),
                ),
                SizedBox(width: isMobile ? 16 : 32),
                Text('Ticket #${ticket.id}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 22 : 32, color: Color(0xFF04324D))),
              ],
            ),
            SizedBox(height: isMobile ? 18 : 32),
            _infoRow('Fecha', DateFormat('dd/MM/yyyy').format(ticket.fechaReporte), isDesktop: !isMobile),
            _infoRow('Solicitante', '${ticket.nombresSolicitante} ${ticket.apellidosSolicitante}', isDesktop: !isMobile),
            _infoRow('Dependencia', ticket.dependencia, isDesktop: !isMobile),
            _infoRow('Estado', ticket.estado ?? 'No asignado', color: _getStatusColor(ticket.estado), isDesktop: !isMobile),
            _infoRow('Tipo de Servicio', ticket.tipoServicio ?? 'No asignado', isDesktop: !isMobile),
            _infoRow('Personal Asignado', ticket.personalAsignado ?? 'No asignado', isDesktop: !isMobile),
            if (ticket.fechaCreacion != null)
              _infoRow('Fecha de Creación', DateFormat('dd/MM/yyyy HH:mm').format(ticket.fechaCreacion!), isDesktop: !isMobile),
            if (ticket.fechaCierre != null)
              _infoRow('Fecha de Cierre', DateFormat('dd/MM/yyyy HH:mm').format(ticket.fechaCierre!), isDesktop: !isMobile),
            SizedBox(height: isMobile ? 18 : 32),
            const Divider(),
            Text('Descripción:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF04324D), fontSize: isMobile ? 16 : 22)),
            SizedBox(height: isMobile ? 6 : 12),
            Text(ticket.descripcion, style: TextStyle(fontSize: isMobile ? 15 : 20)),
            if (ticket.descripcionSolucion != null && ticket.descripcionSolucion!.trim().isNotEmpty) ...[
              SizedBox(height: isMobile ? 18 : 32),
              const Divider(),
              Text('Solución:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF39A900), fontSize:  isMobile ? 16 : 22)),
              SizedBox(height: isMobile ? 6 : 12),
              Text(ticket.descripcionSolucion!, style: TextStyle(fontSize: isMobile ? 15 : 20)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsCard(List<Map<String, dynamic>> comentarios, bool isMobile) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: isMobile ? 8 : 20, horizontal: isMobile ? 8 : 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 20.0 : 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF04324D),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.all(isMobile ? 8 : 16),
                  child: Icon(Icons.comment, color: Colors.white, size: isMobile ? 24 : 32),
                ),
                SizedBox(width: isMobile ? 12 : 24),
                Text('Comentarios', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF04324D), fontSize: isMobile ? 18 : 24)),
              ],
            ),
            SizedBox(height: isMobile ? 12 : 20),
            if (comentarios.isEmpty)
              Text('No hay comentarios para esta solicitud.', style: TextStyle(color: Colors.grey, fontSize: isMobile ? 15 : 18)),
            if (comentarios.isNotEmpty)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: comentarios.length,
                separatorBuilder: (context, idx) => const Divider(height: 18),
                itemBuilder: (context, index) {
                  final c = comentarios[index];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.person, color: Color(0xFF39A900), size: isMobile ? 24 : 32),
                      SizedBox(width: isMobile ? 10 : 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  c['nombre_tecnico'] ?? '${c['nombre'] ?? ''} ${c['apellido'] ?? ''}',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF04324D), fontSize: isMobile ? 15 : 18),
                                ),
                                SizedBox(width: isMobile ? 8 : 16),
                                if (c['fecha_comentario'] != null)
                                  Text(
                                    c['fecha_comentario'].replaceFirst('T', ' '),
                                    style: TextStyle(fontSize: isMobile ? 12 : 15, color: Colors.grey),
                                  ),
                              ],
                            ),
                            SizedBox(height: isMobile ? 2 : 8),
                            Text(c['comentario'] ?? '', style: TextStyle(fontSize: isMobile ? 15 : 18)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? color, bool isDesktop = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isDesktop ? 8 : 4),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF04324D), fontSize: isDesktop ? 18 : 15)),
          if (color != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 12 : 8, vertical: isDesktop ? 6 : 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(value, style: TextStyle(color: Colors.white, fontSize: isDesktop ? 16 : 14)),
            )
          else
            Text(value, style: TextStyle(color: Colors.black87, fontSize: isDesktop ? 16 : 14)),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    return status == 'Cerrada' ? const Color(0xFF39A900) : const Color(0xFF04324D);
  }
} 