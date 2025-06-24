import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  // El parámetro `currentRoute` nos ayudará a resaltar la pantalla actual en el menú.
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.black,
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
          const Divider(),
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
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
            onTap: () {
              // Eliminar todas las rutas anteriores y volver a la pantalla de inicio de sesión
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
          ),
        ],
      ),
    );
  }
} 