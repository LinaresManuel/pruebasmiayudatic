import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';
import '../models/staff_page.dart';
import 'package:provider/provider.dart';
import '../models/user_provider.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({Key? key}) : super(key: key);

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  final ApiService _apiService = ApiService();
  List<User> _staff = [];
  bool _isLoading = true;
  String? _error;
  String _searchCedula = '';
  int _currentPage = 0;
  int _totalStaff = 0;
  static const int _rowsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final page = await _apiService.getStaffPage(
        cedula: _searchCedula,
        page: _currentPage + 1,
        perPage: _rowsPerPage,
      );
      setState(() {
        _staff = page.data;
        _totalStaff = page.total;
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

  void _onSearchCedulaChanged(String value) {
    _searchCedula = value;
    _currentPage = 0;
    _loadStaff();
  }

  void _onPageChanged(int newPage) {
    setState(() {
      _currentPage = newPage;
    });
    _loadStaff();
  }

  void _showAddOrEditDialog({User? user}) async {
    final isEdit = user != null;
    final _formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(text: user?.nombre ?? '');
    final apellidoController = TextEditingController(text: user?.apellido ?? '');
    final cedulaController = TextEditingController(text: user?.cedula ?? '');
    final correoController = TextEditingController(text: user?.correo ?? '');
    final passwordController = TextEditingController();
    String? errorMsg;

    // Cargar roles antes de mostrar el diálogo
    List<Map<String, dynamic>> roles = [];
    String selectedRolId = '';
    try {
      roles = await _apiService.getRoles();
      if (isEdit && user != null) {
        final found = roles.firstWhere(
          (rol) => rol['nombre_rol'].toString().toLowerCase() == user.rol.toLowerCase(),
          orElse: () => roles.first,
        );
        selectedRolId = found['id_rol'].toString();
      } else if (roles.isNotEmpty) {
        selectedRolId = roles.first['id_rol'].toString();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar roles: $e')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isEdit ? 'Editar Personal TIC' : 'Agregar Personal TIC'),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nombreController,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
                    ),
                    TextFormField(
                      controller: apellidoController,
                      decoration: const InputDecoration(labelText: 'Apellido'),
                      validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
                    ),
                    TextFormField(
                      controller: cedulaController,
                      decoration: const InputDecoration(labelText: 'Cédula'),
                      validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
                    ),
                    TextFormField(
                      controller: correoController,
                      decoration: const InputDecoration(labelText: 'Correo electrónico'),
                      validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedRolId,
                      decoration: const InputDecoration(labelText: 'Rol'),
                      items: roles.map((rol) {
                        return DropdownMenuItem<String>(
                          value: rol['id_rol'].toString(),
                          child: Text(rol['nombre_rol']),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => selectedRolId = v!),
                      validator: (v) => v == null || v.isEmpty ? 'Seleccione un rol' : null,
                    ),
                    TextFormField(
                      controller: passwordController,
                      decoration: const InputDecoration(labelText: 'Contraseña (dejar vacío para no cambiar)'),
                      obscureText: true,
                      validator: (v) => isEdit ? null : (v == null || v.isEmpty ? 'Campo requerido' : null),
                    ),
                    if (errorMsg != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(errorMsg!, style: const TextStyle(color: Colors.red)),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    String? password;
                    if (passwordController.text.isNotEmpty) {
                      password = passwordController.text;
                    }
                    final data = {
                      'nombre': nombreController.text,
                      'apellido': apellidoController.text,
                      'cedula': cedulaController.text,
                      'correo_electronico': correoController.text,
                      'id_rol': int.tryParse(selectedRolId.toString()) ?? selectedRolId,
                      if (password != null) 'password': password,
                    };
                    try {
                      if (isEdit) {
                        await _apiService.updateStaffMember(user!.id, data);
                      } else {
                        await _apiService.createStaffMember(data);
                      }
                    } catch (e) {
                      // Ignorar cualquier error y continuar
                    }
                    Navigator.pop(context);
                    _loadStaff();
                  }
                },
                child: Text(isEdit ? 'Guardar' : 'Agregar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteDialog(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Personal'),
        content: Text('¿Está seguro de eliminar a ${user.nombre} ${user.apellido}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _apiService.deleteStaffMember(user.id);
        _loadStaff();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    final isSmallScreen = MediaQuery.of(context).size.width < 800;
    final isMediumScreen = MediaQuery.of(context).size.width < 1200;
    // Solo admin (id_rol=2) puede acceder
    if (user == null || user.rol != 'admin' && user.rol != 'Administrador' && user.rol != '2') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Configuración'),
        ),
        body: const Center(
          child: Text('Acceso denegado. Solo administradores pueden acceder a esta sección.', style: TextStyle(fontSize: 18, color: Colors.red)),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: isSmallScreen ? 80 : 100,
        backgroundColor: const Color(0xFF04324D),
        automaticallyImplyLeading: false,
        flexibleSpace: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8.0 : 16.0),
            child: Row(
              children: [
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
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
                    'Gestión de Personal TIC',
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
      drawer: const AppDrawer(currentRoute: '/configuracion'),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 320, // ancho fijo razonable para cédula
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade600.withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TextField(
                        maxLength: 20,
                        decoration: InputDecoration(
                          hintText: 'Buscar por cédula',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
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
                          counterText: '', // Oculta el contador de caracteres
                        ),
                        onChanged: _onSearchCedulaChanged,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _showAddOrEditDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error: $_error',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final int startIndex = _currentPage * _rowsPerPage;
                  final int endIndex = (_currentPage + 1) * _rowsPerPage;
                  final List<User> paginatedStaff = _staff.length > startIndex
                      ? _staff.sublist(startIndex, endIndex > _staff.length ? _staff.length : endIndex)
                      : [];
                  final totalPages = (_totalStaff / _rowsPerPage).ceil();
                  final isMobile = constraints.maxWidth < 600;
                  Widget paginationControls = Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _currentPage > 0 ? () => _onPageChanged(_currentPage - 1) : null,
                        child: const Icon(Icons.chevron_left),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'Página ${_currentPage + 1} de ${totalPages}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: endIndex < _staff.length ? () => _onPageChanged(_currentPage + 1) : null,
                        child: const Icon(Icons.chevron_right),
                      ),
                    ],
                  );
                  if (isMobile) {
                    // Vista tipo ficha para móvil
                    return Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: paginatedStaff.length,
                            itemBuilder: (context, index) {
                              final user = paginatedStaff[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                elevation: 4,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: Padding(
                                  padding: const EdgeInsets.all(18.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: Colors.teal[700],
                                            child: Text(user.nombre.isNotEmpty ? user.nombre[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white)),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              '${user.nombre} ${user.apellido}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 24, thickness: 1.2),
                                      Wrap(
                                        runSpacing: 8,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.badge, size: 20, color: Colors.grey),
                                              const SizedBox(width: 8),
                                              Expanded(child: Text('Cédula: ${user.cedula}', style: const TextStyle(fontSize: 15))),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              const Icon(Icons.email, size: 20, color: Colors.grey),
                                              const SizedBox(width: 8),
                                              Expanded(child: Text('Correo: ${user.correo}', style: const TextStyle(fontSize: 15))),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              const Icon(Icons.security, size: 20, color: Colors.grey),
                                              const SizedBox(width: 8),
                                              Expanded(child: Text('Rol: ${user.rol}', style: const TextStyle(fontSize: 15))),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.blue),
                                            onPressed: () => _showAddOrEditDialog(user: user),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () => _showDeleteDialog(user),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (totalPages > 1) Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: paginationControls,
                        ),
                      ],
                    );
                  } else {
                    // Vista de tabla para escritorio
                    return Column(
                      children: [
                        Expanded(
                          child: Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16.0),
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                  child: DataTable(
                                    headingRowColor: MaterialStateProperty.all(const Color(0xFF39A900)),
                                    columnSpacing: isSmallScreen ? 15 : 20,
                                    horizontalMargin: isSmallScreen ? 12 : 24,
                                    columns: [
                                      DataColumn(label: Text('ID', style: TextStyle(fontSize: isSmallScreen ? 15 : 16, fontWeight: FontWeight.bold)), numeric: true),
                                      DataColumn(label: Text('Nombre', style: TextStyle(fontSize: isSmallScreen ? 15 : 16, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Apellido', style: TextStyle(fontSize: isSmallScreen ? 15 : 16, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Cédula', style: TextStyle(fontSize: isSmallScreen ? 15 : 16, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Correo', style: TextStyle(fontSize: isSmallScreen ? 15 : 16, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Rol', style: TextStyle(fontSize: isSmallScreen ? 15 : 16, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Acciones', style: TextStyle(fontSize: isSmallScreen ? 15 : 16, fontWeight: FontWeight.bold))),
                                    ],
                                    rows: paginatedStaff.map((user) {
                                      return DataRow(
                                        cells: [
                                          DataCell(Text(user.id.toString(), style: TextStyle(fontSize: isSmallScreen ? 15 : 16))),
                                          DataCell(Text(user.nombre, style: TextStyle(fontSize: isSmallScreen ? 15 : 16))),
                                          DataCell(Text(user.apellido, style: TextStyle(fontSize: isSmallScreen ? 15 : 16))),
                                          DataCell(Text(user.cedula, style: TextStyle(fontSize: isSmallScreen ? 15 : 16))),
                                          DataCell(Text(user.correo, style: TextStyle(fontSize: isSmallScreen ? 15 : 16))),
                                          DataCell(Text(user.rol, style: TextStyle(fontSize: isSmallScreen ? 15 : 16))),
                                          DataCell(Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit, color: Colors.blue),
                                                onPressed: () => _showAddOrEditDialog(user: user),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete, color: Colors.red),
                                                onPressed: () => _showDeleteDialog(user),
                                              ),
                                            ],
                                          )),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (totalPages > 1) Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: paginationControls,
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
} 