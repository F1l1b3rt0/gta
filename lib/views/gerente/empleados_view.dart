// ignore_for_file: unused_field, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  const EmpleadosView({super.key});
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
      duration: const Duration(milliseconds: 500),
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
      final r = await Supabase.instance.client
          .from('empleados')
          .select('*')
          .order('nombre');
      setState(() {
        _empleados = List<Map<String, dynamic>>.from(r);
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
        title: const Text(
          'Eliminar Empleado',
          style: TextStyle(fontWeight: FontWeight.w700, color: _C.textPrimary),
        ),
        content: Text(
          '¿Eliminar a $nombre? Esta acción no se puede deshacer.',
          style: const TextStyle(color: _C.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: _C.textSecondary),
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
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
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
        _showSnack('Empleado eliminado');
      } catch (_) {
        _showSnack('Error al eliminar', isError: true);
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
          title: const Text(
            'Editar Empleado',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: _C.textPrimary,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Field(
                  controller: nombreCtrl,
                  label: 'Nombre',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 12),
                _Field(
                  controller: emailCtrl,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  enabled: false,
                ),
                const SizedBox(height: 12),
                _Field(
                  controller: salarioCtrl,
                  label: 'Salario/hora (\$)',
                  icon: Icons.attach_money_rounded,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: rol,
                  decoration: _fieldDecoration('Rol', Icons.badge_outlined),
                  dropdownColor: _C.bg,
                  items: const [
                    DropdownMenuItem(
                      value: 'empleado',
                      child: Text('Empleado'),
                    ),
                    DropdownMenuItem(value: 'gerente', child: Text('Gerente')),
                  ],
                  onChanged: (v) => rol = v!,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: _C.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.primaryLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Guardar',
                style: TextStyle(color: Colors.white),
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
    return Scaffold(
      backgroundColor: _C.bg,
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
                      '${_filtrados.length} resultado${_filtrados.length != 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: _C.textSecondary,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: _C.primaryLight,
                            ),
                          )
                        : _filtrados.isEmpty
                        ? _buildEmpty()
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 60),
                            itemCount: _filtrados.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
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
        _ScaleBtn(
          onPressed: () => Navigator.pop(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _C.border, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: _C.border.withOpacity(0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 15,
              color: _C.primaryLight,
            ),
          ),
        ),
        const SizedBox(width: 14),
        const Text(
          'Empleados',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: _C.textPrimary,
          ),
        ),
        const Spacer(),
        _ScaleBtn(
          onPressed: () {},
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_C.primary, _C.primaryLight],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: _C.primary.withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
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
      style: const TextStyle(color: _C.textPrimary),
      decoration: InputDecoration(
        hintText: 'Buscar empleado...',
        hintStyle: const TextStyle(color: _C.textHint, fontSize: 14),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: _C.primaryLight,
          size: 20,
        ),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: _C.textSecondary,
                  size: 18,
                ),
                onPressed: () => setState(() => _searchQuery = ''),
              )
            : null,
        filled: true,
        fillColor: _C.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _C.border, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _C.border, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _C.primaryLight, width: 1.8),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
  );

  Widget _buildFiltros() => Padding(
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

  Widget _FilterBtn(String label, String value) {
    final sel = _filtroRol == value;
    return GestureDetector(
      onTap: () => setState(() => _filtroRol = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: sel ? _C.primaryLight : _C.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: sel ? _C.primaryLight : _C.border,
            width: 1.3,
          ),
          boxShadow: sel
              ? [
                  BoxShadow(
                    color: _C.primaryLight.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: sel ? Colors.white : _C.textSecondary,
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
            color: _C.surface,
            shape: BoxShape.circle,
            border: Border.all(color: _C.border, width: 1.5),
          ),
          child: const Icon(
            Icons.group_off_rounded,
            color: _C.primaryLight,
            size: 36,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Sin resultados',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: _C.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Prueba con otro filtro o búsqueda',
          style: TextStyle(fontSize: 13, color: _C.textSecondary),
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
    final roleColor = esGerente ? _C.primaryLight : _C.success;
    final initial = (empleado['nombre'] as String).isNotEmpty
        ? (empleado['nombre'] as String)[0].toUpperCase()
        : '?';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border, width: 1.4),
        boxShadow: const [
          BoxShadow(color: _C.shadowSm, blurRadius: 10, offset: Offset(0, 3)),
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
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    empleado['nombre'],
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _C.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    empleado['email'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: _C.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 5),
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
                        style: const TextStyle(
                          fontSize: 11,
                          color: _C.textSecondary,
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
                  color: _C.primaryLight,
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

InputDecoration _fieldDecoration(String label, IconData icon) =>
    InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _C.textSecondary, fontSize: 14),
      prefixIcon: Icon(icon, color: _C.primaryLight, size: 20),
      filled: true,
      fillColor: _C.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _C.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _C.border, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _C.primaryLight, width: 1.8),
      ),
    );

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
    style: const TextStyle(color: _C.textPrimary),
    decoration: _fieldDecoration(label, icon),
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
      duration: const Duration(milliseconds: 120),
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
        ..color = const Color(0xFFDDEEFF).withOpacity(0.7)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
