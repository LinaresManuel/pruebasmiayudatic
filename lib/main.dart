import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/ticket_form_screen.dart';
import 'screens/support_dashboard_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Soporte',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/ticket-form': (context) => const TicketFormScreen(),
        '/support-dashboard': (context) => const SupportDashboardScreen(),
      },
    );
  }
}
