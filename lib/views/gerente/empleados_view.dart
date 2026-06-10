// ignore_for_file: unused_field, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../services/language_service.dart';
import '../../services/tr.dart';

class _C {
  static const bg = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF4F8FF);
  static const primary = Color(0xFF0F2DA6);
  static const primaryLight = Color(0xFF1A4FD8);
  static const success = Color(0xFF00C853);
  static const textPrimary = Color(0xFF1A2A4A);
  static const textSecondary = Color(0xFF5A7DBA);
  static const textHint = Color(0xFFAABFE0);
  static const border = Color(0xFFC8DEFF);
  static const divider = Color(0xFFDDEEFF);
  static const shadowSm = Color(0x201A4FD8);
}

class EmpleadosView extends StatefulWidget {
  EmpleadosView({super.key});
  @override
  State<EmpleadosView> createState() => _EmpleadosViewState();
}

class _EmpleadosViewState extends State<EmpleadosView>
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
      vsync: this,
      duration: Duration(milliseconds: 500),
    )..forward();
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
      // Fetch empleados
      final empRes = await Supabase.instance.client
          .from('empleados')
          .select('*')
          .order('nombre');
      final empleados = List<Map<String, dynamic>>.from(empRes);

      // Fetch gerentes and normalize to same shape
      List<Map<String, dynamic>> gerentes = [];
      try {
        final gerRes = await Supabase.instance.client
            .from('gerentes')
            .select('*')
            .order('nombre');
        gerentes = (gerRes as List).map((g) => {
          'id': g['id'],
          'nombre': g['nombre'] ?? '',
          'email': g['email'] ?? '',
          'rol': 'gerente',
          'salario_por_hora': g['salario_por_hora'] ?? 0,
          'avatar_url': g['avatar_url'] ?? '',
          'user_id': g['user_id'],
          ...Map<String, dynamic>.from(g),
        }).toList();
      } catch (_) {}

      final todos = [...empleados, ...gerentes];
      todos.sort((a, b) => (a['nombre'] as String).compareTo(b['nombre'] as String));

      setState(() {
        _empleados = todos;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _eliminarEmpleado(String id, String nombre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          tr(context, 'Eliminar Empleado', 'Delete Employee'),
          style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Text(
          tr(context, '¿Eliminar a $nombre? Esta acción no se puede deshacer.', 'Delete $nombre? This action cannot be undone.'),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(150)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              tr(context, 'Cancelar', 'Cancel'),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(150)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              tr(context, 'Eliminar', 'Delete'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await Supabase.instance.client.from('empleados').delete().eq('id', id);
        await _cargarEmpleados();
        _showSnack(trStatic(context, 'Empleado eliminado', 'Employee deleted'));
      } catch (_) {
        _showSnack(trStatic(context, 'Error al eliminar', 'Error deleting'), isError: true);
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _editarEmpleado(Map<String, dynamic> emp) async {
    final nombreCtrl = TextEditingController(text: emp['nombre']);
    final emailCtrl = TextEditingController(text: emp['email']);
    final salarioCtrl = TextEditingController(
      text: emp['salario_por_hora']?.toString() ?? '0',
    );
    String rol = emp['rol'];
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            tr(context, 'Editar Empleado', 'Edit Employee'),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Field(
                  controller: nombreCtrl,
                  label: tr(context, 'Nombre', 'Name'),
                  icon: Icons.person_outline,
                ),
                SizedBox(height: 12),
                _Field(
                  controller: emailCtrl,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  enabled: false,
                ),
                SizedBox(height: 12),
                _Field(
                  controller: salarioCtrl,
                  label: tr(context, 'Salario/hora (\$)', 'Hourly wage (\$)'),
                  icon: Icons.attach_money_rounded,
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: rol,
                  decoration: _fieldDecoration(tr(context, 'Rol', 'Role'), Icons.badge_outlined, context),
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  items: [
                    DropdownMenuItem(
                      value: 'empleado',
                      child: Text(tr(context, 'Empleado', 'Employee')),
                    ),
                    DropdownMenuItem(value: 'gerente', child: Text(tr(context, 'Gerente', 'Manager'))),
                  ],
                  onChanged: (v) => rol = v!,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                tr(context, 'Cancelar', 'Cancel'),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(150)),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                tr(context, 'Guardar', 'Save'),
                style: const TextStyle(color: Colors.white),
              ),
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
            .eq('id', emp['id']);
        await _cargarEmpleados();
        _showSnack(trStatic(context, 'Empleado actualizado', 'Employee updated'));
      } catch (_) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.redAccent : Color(0xFF00C853),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  List<Map<String, dynamic>> get _filtrados => _empleados.where((e) {
    if (_filtroRol != 'todos' && e['rol'] != _filtroRol) return false;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      return e['nombre'].toLowerCase().contains(q) ||
          e['email'].toLowerCase().contains(q);
    }
    return true;
  }).toList();

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageService>();
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: Size(MediaQuery.of(context).size.width, 60),
              painter: _WavePainter(),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                _buildSearch(),
                _buildFiltros(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      tr(context,
                        '${_filtrados.length} resultado${_filtrados.length != 1 ? 's' : ''}',
                        '${_filtrados.length} result${_filtrados.length != 1 ? 's' : ''}'),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: _isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          )
                        : _filtrados.isEmpty
                        ? _buildEmpty()
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 60),
                            itemCount: _filtrados.length,
                            separatorBuilder: (_, _) =>
                                SizedBox(height: 10),
                            itemBuilder: (_, i) => _EmpleadoTile(
                              empleado: _filtrados[i],
                              onEdit: () => _editarEmpleado(_filtrados[i]),
                              onDelete: () => _eliminarEmpleado(
                                _filtrados[i]['id'],
                                _filtrados[i]['nombre'],
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    child: Row(
      children: [
        Visibility(
          visible: Navigator.canPop(context),
          maintainSize: true, maintainAnimation: true, maintainState: true,
          child: _ScaleBtn(
            onPressed: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withAlpha(40), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withAlpha(40).withOpacity(0.4),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 15,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        SizedBox(width: 14),
        Text(
          tr(context, 'Empleados', 'Employees'),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Spacer(),
        _ScaleBtn(
          onPressed: () {},
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.35),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              Icons.person_add_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildSearch() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    child: TextField(
      onChanged: (v) => setState(() => _searchQuery = v),
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: tr(context, 'Buscar empleado...', 'Search employee...'),
        hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(80), fontSize: 14),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                  size: 18,
                ),
                onPressed: () => setState(() => _searchQuery = ''),
              )
            : null,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withAlpha(40), width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withAlpha(40), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.8),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
  );

  Widget _buildFiltros() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Row(
      children: [
        _FilterBtn(tr(context, 'Todos', 'All'), 'todos'),
        SizedBox(width: 8),
        _FilterBtn(tr(context, 'Empleados', 'Employees'), 'empleado'),
        SizedBox(width: 8),
        _FilterBtn(tr(context, 'Gerentes', 'Managers'), 'gerente'),
      ],
    ),
  );

  Widget _FilterBtn(String label, String value) {
    final sel = _filtroRol == value;
    return GestureDetector(
      onTap: () => setState(() => _filtroRol = value),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: sel ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: sel ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.primary.withAlpha(40),
            width: 1.3,
          ),
          boxShadow: sel
              ? [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: sel ? Colors.white : Theme.of(context).colorScheme.onSurface.withAlpha(150),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).colorScheme.primary.withAlpha(40), width: 1.5),
          ),
          child: Icon(
            Icons.group_off_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: 36,
          ),
        ),
        SizedBox(height: 16),
        Text(
          tr(context, 'Sin resultados', 'No results'),
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 6),
        Text(
          tr(context, 'Prueba con otro filtro o búsqueda', 'Try a different filter or search'),
          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withAlpha(150)),
        ),
      ],
    ),
  );
}

class _EmpleadoTile extends StatelessWidget {
  final Map<String, dynamic> empleado;
  final VoidCallback onEdit, onDelete;
  const _EmpleadoTile({
    required this.empleado,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final esGerente = empleado['rol'] == 'gerente';
    final roleColor = esGerente ? Theme.of(context).colorScheme.primary : Color(0xFF00C853);
    final initial = (empleado['nombre'] as String).isNotEmpty
        ? (empleado['nombre'] as String)[0].toUpperCase()
        : '?';
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withAlpha(40), width: 1.4),
        boxShadow: [
          BoxShadow(color: Theme.of(context).colorScheme.primary.withAlpha(15), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
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
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    empleado['nombre'],
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    empleado['email'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                    ),
                  ),
                  SizedBox(height: 5),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          esGerente ? tr(context, 'Gerente', 'Manager') : tr(context, 'Empleado', 'Employee'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: roleColor,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '\$${empleado['salario_por_hora']}/hr',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                _ActionBtn(
                  icon: Icons.edit_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  onTap: onEdit,
                ),
                SizedBox(height: 6),
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
  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
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

InputDecoration _fieldDecoration(
    String label, IconData icon, BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: cs.onSurface.withAlpha(150), fontSize: 14),
    prefixIcon: Icon(icon, color: cs.primary, size: 20),
    filled: true,
    fillColor: cs.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.primary.withAlpha(40)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.primary.withAlpha(40), width: 1.2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.primary, width: 1.8),
    ),
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
  Widget build(BuildContext context) => TextField(
    controller: controller,
    enabled: enabled,
    keyboardType: keyboardType,
    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
    decoration: _fieldDecoration(label, icon, context),
  );
}

class _ScaleBtn extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  const _ScaleBtn({required this.onPressed, required this.child});
  @override
  State<_ScaleBtn> createState() => _ScaleBtnState();
}

class _ScaleBtnState extends State<_ScaleBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 120),
      lowerBound: 0.94,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => _c.reverse(),
    onTapUp: (_) {
      _c.forward();
      widget.onPressed?.call();
    },
    onTapCancel: () => _c.forward(),
    child: AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Transform.scale(scale: _c.value, child: child),
      child: widget.child,
    ),
  );
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * 0.5)
        ..cubicTo(
          size.width * 0.25,
          size.height * 0.15,
          size.width * 0.75,
          size.height * 0.85,
          size.width,
          size.height * 0.43,
        )
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
      Paint()
        ..color = Color(0xFFDDEEFF).withOpacity(0.7)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
