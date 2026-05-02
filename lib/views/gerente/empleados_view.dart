import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _C {
  static const bg           = Color(0xFFFFFFFF);
  static const surface      = Color(0xFFF4F8FF);
  static const primary      = Color(0xFF1A6FE8);
  // ignore: unused_field
  static const primaryLight = Color(0xFF4D96FF);
  static const success      = Color(0xFF00C853);
  static const text         = Color(0xFF0D1B3E);
  static const textSub      = Color(0xFF6B80A3);
  static const divider      = Color(0xFFE0ECFF);
  static const shadow       = Color(0x201A6FE8);
}

class EmpleadosScreen extends StatefulWidget {
  const EmpleadosScreen({super.key});

  @override
  State<EmpleadosScreen> createState() => _EmpleadosScreenState();
}

class _EmpleadosScreenState extends State<EmpleadosScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _empleados = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filtroRol = 'todos';

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _cargarEmpleados();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarEmpleados() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('empleados')
          .select('*')
          .order('nombre');
      setState(() {
        _empleados = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _eliminarEmpleado(String id, String nombre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _C.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar Empleado',
            style: TextStyle(fontWeight: FontWeight.w700, color: _C.text)),
        content: Text('¿Eliminar a $nombre? Esta acción no se puede deshacer.',
            style: const TextStyle(color: _C.textSub)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: _C.textSub)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await Supabase.instance.client
            .from('empleados')
            .delete()
            .eq('id', id);
        await _cargarEmpleados();
        _showSnack('Empleado eliminado');
      } catch (_) {
        _showSnack('Error al eliminar', isError: true);
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _editarEmpleado(Map<String, dynamic> empleado) async {
    final nombreCtrl = TextEditingController(text: empleado['nombre']);
    final emailCtrl = TextEditingController(text: empleado['email']);
    final salarioCtrl = TextEditingController(
        text: empleado['salario_por_hora']?.toString() ?? '0');
    String rol = empleado['rol'];

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: _C.bg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Editar Empleado',
              style: TextStyle(fontWeight: FontWeight.w700, color: _C.text)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Field(controller: nombreCtrl, label: 'Nombre', icon: Icons.person_outline),
                const SizedBox(height: 12),
                _Field(controller: emailCtrl, label: 'Email', icon: Icons.email_outlined, enabled: false),
                const SizedBox(height: 12),
                _Field(
                  controller: salarioCtrl,
                  label: 'Salario por hora (\$)',
                  icon: Icons.attach_money_rounded,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: rol,
                  decoration: _fieldDecoration('Rol', Icons.badge_outlined),
                  dropdownColor: _C.bg,
                  items: const [
                    DropdownMenuItem(value: 'empleado', child: Text('Empleado')),
                    DropdownMenuItem(value: 'gerente', child: Text('Gerente')),
                  ],
                  onChanged: (v) => rol = v!,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar', style: TextStyle(color: _C.textSub)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      setState(() => _isLoading = true);
      try {
        await Supabase.instance.client
            .from('empleados')
            .update({
              'nombre': nombreCtrl.text.trim(),
              'salario_por_hora': double.parse(salarioCtrl.text),
              'rol': rol,
            })
            .eq('id', empleado['id']);
        await _cargarEmpleados();
        _showSnack('Empleado actualizado');
      } catch (_) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.redAccent : _C.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  List<Map<String, dynamic>> get _empleadosFiltrados {
    return _empleados.where((emp) {
      if (_filtroRol != 'todos' && emp['rol'] != _filtroRol) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return emp['nombre'].toLowerCase().contains(q) ||
            emp['email'].toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          children: [
            _buildSearch(),
            _buildFiltros(),
            // Contador
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_empleadosFiltrados.length} resultado${_empleadosFiltrados.length != 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 12, color: _C.textSub),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: _C.primary))
                  : _empleadosFiltrados.isEmpty
                      ? _buildEmpty()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: _empleadosFiltrados.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final emp = _empleadosFiltrados[index];
                            return _EmpleadoTile(
                              empleado: emp,
                              onEdit: () => _editarEmpleado(emp),
                              onDelete: () => _eliminarEmpleado(emp['id'], emp['nombre']),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _C.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _C.text, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Empleados',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: _C.text,
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _C.primary,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: _C.primary.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 18),
            ),
            onPressed: () {/* TODO */},
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _C.divider),
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(color: _C.text),
        decoration: InputDecoration(
          hintText: 'Buscar empleado...',
          hintStyle: const TextStyle(color: _C.textSub, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: _C.primary, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: _C.textSub, size: 18),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
              : null,
          filled: true,
          fillColor: _C.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _C.divider, width: 1.2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _C.divider, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _C.primary, width: 1.8),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFiltros() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          _FilterBtn('Todos', 'todos'),
          const SizedBox(width: 8),
          _FilterBtn('Empleados', 'empleado'),
          const SizedBox(width: 8),
          _FilterBtn('Gerentes', 'gerente'),
        ],
      ),
    );
  }

  Widget _FilterBtn(String label, String value) {
    final sel = _filtroRol == value;
    return GestureDetector(
      onTap: () => setState(() => _filtroRol = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: sel ? _C.primary : _C.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? _C.primary : _C.divider, width: 1.3),
          boxShadow: sel
              ? [BoxShadow(color: _C.primary.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 3))]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: sel ? Colors.white : _C.textSub,
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _C.surface,
              shape: BoxShape.circle,
              border: Border.all(color: _C.divider, width: 1.5),
            ),
            child: const Icon(Icons.group_off_rounded, color: _C.primary, size: 36),
          ),
          const SizedBox(height: 16),
          const Text('Sin resultados', style: TextStyle(
            fontSize: 17, fontWeight: FontWeight.w600, color: _C.text,
          )),
          const SizedBox(height: 6),
          const Text('Prueba con otro filtro o búsqueda', style: TextStyle(
            fontSize: 13, color: _C.textSub,
          )),
        ],
      ),
    );
  }
}

// ─── Tile empleado ───────────────────────────────────────────────────────────

class _EmpleadoTile extends StatelessWidget {
  final Map<String, dynamic> empleado;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EmpleadoTile({
    required this.empleado,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final esGerente = empleado['rol'] == 'gerente';
    final roleColor = esGerente ? _C.primary : _C.success;
    final initial = (empleado['nombre'] as String).isNotEmpty
        ? (empleado['nombre'] as String)[0].toUpperCase()
        : '?';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.divider, width: 1.2),
        boxShadow: const [
          BoxShadow(color: _C.shadow, blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [roleColor, roleColor.withOpacity(0.70)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: roleColor.withOpacity(0.30),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(initial,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    )),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    empleado['nombre'],
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _C.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    empleado['email'],
                    style: const TextStyle(fontSize: 12, color: _C.textSub),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          esGerente ? 'Gerente' : 'Empleado',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: roleColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '\$${empleado['salario_por_hora']}/hr',
                        style: const TextStyle(fontSize: 11, color: _C.textSub),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Acciones
            Column(
              children: [
                _ActionBtn(
                  icon: Icons.edit_rounded,
                  color: _C.primary,
                  onTap: onEdit,
                ),
                const SizedBox(height: 6),
                _ActionBtn(
                  icon: Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                  onTap: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

// ─── Campo de texto personalizado ────────────────────────────────────────────

InputDecoration _fieldDecoration(String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: _C.textSub, fontSize: 14),
    prefixIcon: Icon(icon, color: _C.primary, size: 20),
    filled: true,
    fillColor: _C.surface,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _C.divider)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _C.divider, width: 1.2)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _C.primary, width: 1.8)),
  );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool enabled;
  final TextInputType keyboardType;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      style: const TextStyle(color: _C.text),
      decoration: _fieldDecoration(label, icon),
    );
  }
}