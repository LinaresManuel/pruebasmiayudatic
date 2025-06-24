import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/ticket_form_screen.dart';
import 'screens/support_dashboard_screen.dart';
import 'screens/details_screen.dart';
import 'screens/inicio_sesion_screen.dart';
import 'screens/solicitud_cerrada_screen.dart';
import 'screens/consultar_ticket_screen.dart';
import 'screens/estadisticas_personal_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Soporte',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/login': (context) => const InicioSesionScreen(),
        '/ticket-form': (context) => const TicketFormScreen(),
        '/support-dashboard': (context) => const SupportDashboardScreen(),
        '/solicitud-cerrada': (context) => const SolicitudCerradaScreen(),
        '/consultar-ticket': (context) => const ConsultarTicketScreen(),
        '/estadisticas-personal': (context) => const EstadisticasPersonalScreen(),
        '/case-details': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return DetailsScreen(caseId: args['caseId']);
        },
      },
    );
  }
}
