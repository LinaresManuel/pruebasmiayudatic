import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_provider.dart';

class AppDrawer extends StatelessWidget {
  // El parámetro `currentRoute` nos ayudará a resaltar la pantalla actual en el menú.
  final String currentRoute;

  const AppDrawer({Key? key, required this.currentRoute}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF04324D),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/sena_logo.png',
                  height: 80,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Menú de Servicios',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.assignment),
            title: const Text('Tickets Abiertos'),
            selected: currentRoute == '/support-dashboard',
            selectedTileColor: Colors.cyan.withOpacity(0.1),
            onTap: () {
              // No hacer nada si ya estamos en la pantalla de incidentes
              if (currentRoute == '/support-dashboard') {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, '/support-dashboard');
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.check_circle),
            title: const Text('Tickets Cerrados'),
            selected: currentRoute == '/solicitud-cerrada',
            selectedTileColor: Colors.cyan.withOpacity(0.1),
            onTap: () {
              if (currentRoute == '/solicitud-cerrada') {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, '/solicitud-cerrada');
              }
            },
          ),
                    ListTile(
            leading: const Icon(Icons.assignment),
            title: const Text('Consultar N° de Ticket'),
            selected: currentRoute == '/consultar-ticket',
            selectedTileColor: Colors.cyan.withOpacity(0.1),
            onTap: () {
              if (currentRoute == '/consultar-ticket') {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, '/consultar-ticket');
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Estadísticas de Personal TIC'),
            selected: currentRoute == '/estadisticas-personal',
            selectedTileColor: Colors.cyan.withOpacity(0.1),
            onTap: () {
               if (currentRoute == '/estadisticas-personal') {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, '/estadisticas-personal');
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Estadísticas Dependencias'),
            selected: currentRoute == '/estadisticas-dependencias',
            selectedTileColor: Colors.cyan.withOpacity(0.1),
            onTap: () {
              if (currentRoute == '/estadisticas-dependencias') {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, '/estadisticas-dependencias');
              }
            },
          ),
          const Divider(),
          if (user != null && (user.rol == 'admin' || user.rol == 'Administrador' || user.rol == '2'))
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configuración'),
              selected: currentRoute == '/configuracion',
              selectedTileColor: Colors.cyan.withOpacity(0.1),
              onTap: () {
                if (currentRoute == '/configuracion') {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacementNamed(context, '/configuracion');
                }
              },
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesión'),
            onTap: () {
              Provider.of<UserProvider>(context, listen: false).logout();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
          ),
        ],
      ),
    );
  }
} 