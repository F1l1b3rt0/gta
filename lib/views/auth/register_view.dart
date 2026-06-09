// ignore_for_file: unused_import, dead_null_aware_expression, dead_code, unused_element_parameter, unused_field, deprecated_member_use, unnecessary_underscores

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../viewmodels/auth_viewmodel.dart';

// ─── Paleta de colores (misma que login) ──────────────────────────────────────
class _C {
  static const bg           = Color(0xFFFFFFFF);
  static const bgField      = Color(0xFFFFFFFF);
  static const bgCard       = Color(0xFFF0F6FF);

  static const primary      = Color(0xFF0F2DA6);
  static const primaryMid   = Color(0xFF1A3ABF);
  static const primaryLight = Color(0xFF1A4FD8);
  static const accent       = Color(0xFF2196F3);
  static const accentGlow   = Color(0xFF00B4FF);

  static const textTitle    = Color(0xFF1A4FD8);
  static const textSub      = Color(0xFF5A7DBA);
  static const textLabel    = Color(0xFF1A4FD8);
  static const textField    = Color(0xFF1A2A4A);
  static const textHint     = Color(0xFFAABFE0);
  static const textMuted    = Color(0xFFB0C8E8);

  static const border       = Color(0xFFC8DEFF);
  static const divider      = Color(0xFFDDEEFF);
  static const glow1        = Color(0x400099FF);
  static const glow2        = Color(0x200057D9);
}

class RegisterView extends StatelessWidget {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthViewModel(),
      child: const _RegisterContent(),
    );
  }
}

class _RegisterContent extends StatefulWidget {
  const _RegisterContent();

  @override
  State<_RegisterContent> createState() => _RegisterContentState();
}

class _RegisterContentState extends State<_RegisterContent>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late AnimationController _contentController;
  late Animation<double> _contentOpacity;
  late Animation<double> _contentSlide;

  final _nombreFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();
  final _confirmFocus = FocusNode();
  final _salarioFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _contentOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeIn),
    );
    _contentSlide = Tween<double>(begin: 24.0, end: 0.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic),
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _contentController.forward();
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    _nombreFocus.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    _confirmFocus.dispose();
    _salarioFocus.dispose();
    super.dispose();
  }

  Future<void> _handleRegister(AuthViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) return;

    final success = await viewModel.register();
    if (mounted) {
      if (success) {
        Navigator.pop(context);
      } else {
        _mostrarMensaje(viewModel.errorMessage ?? 'Error al registrar');
      }
    }
  }

  void _mostrarMensaje(String mensaje, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, viewModel, _) {
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
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: AnimatedBuilder(
                          animation: _contentController,
                          builder: (_, child) => Opacity(
                            opacity: _contentOpacity.value,
                            child: Transform.translate(
                              offset: Offset(0, _contentSlide.value),
                              child: child,
                            ),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                _buildHero(),
                                const SizedBox(height: 32),
                                _buildNombreField(viewModel),
                                const SizedBox(height: 20),
                                _buildEmailField(viewModel),
                                const SizedBox(height: 20),
                                _buildPasswordRow(viewModel),
                                const SizedBox(height: 20),
                                _buildRolSection(viewModel),
                                const SizedBox(height: 20),
                                if (viewModel.rol == 'empleado') ...[
                                  _buildSalarioField(viewModel),
                                  const SizedBox(height: 20),
                                ],
                                _buildRegisterButton(viewModel),
                                const SizedBox(height: 18),
                                _buildLoginLink(),
                                const SizedBox(height: 48),
                              ],
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
      },
    );
  }

  // ─── Top Bar ──────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          _ScaleButton(
            onPressed: () => Navigator.pop(context),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _C.border, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: _C.border.withValues(alpha: 0.4),
                    blurRadius: 6, offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 15, color: _C.primaryLight,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 38, height: 38,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF1A4FD8), Color(0xFF2196F3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/icon/icon.png',
                width: 38, height: 38, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Text('G',
                      style: TextStyle(color: Colors.white,
                          fontSize: 16, fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text('GTA',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800,
                  color: _C.primaryLight, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  // ─── Hero ─────────────────────────────────────────────────────────────────

  Widget _buildHero() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: double.infinity),
        Text(
          'Crear cuenta',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32, fontWeight: FontWeight.w800, color: _C.primaryLight,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Completa los datos para registrarte',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: _C.textSub),
        ),
      ],
    );
  }

  // ─── Campos ───────────────────────────────────────────────────────────────

  Widget _buildNombreField(AuthViewModel viewModel) {
    return _SnakeTextField(
      focusNode: _nombreFocus,
      label: 'Nombre completo',
      hint: 'Ana García',
      keyboardType: TextInputType.name,
      onChanged: viewModel.setNombre,
      validator: (v) => v == null || v.isEmpty ? 'Ingrese el nombre' : null,
    );
  }

  Widget _buildEmailField(AuthViewModel viewModel) {
    return _SnakeTextField(
      focusNode: _emailFocus,
      label: 'Correo electrónico',
      hint: 'ana@empresa.com',
      keyboardType: TextInputType.emailAddress,
      onChanged: viewModel.setEmail,
      validator: (v) {
        if (v == null || v.isEmpty) return 'Ingrese el correo';
        if (!v.contains('@')) return 'Correo inválido';
        return null;
      },
    );
  }

  Widget _buildPasswordRow(AuthViewModel viewModel) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _SnakePasswordField(
            focusNode: _passFocus,
            label: 'Contraseña',
            hint: '••••••',
            onChanged: viewModel.setPassword,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Requerido';
              if (v.length < 6) return 'Mín. 6 caracteres';
              return null;
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SnakePasswordField(
            focusNode: _confirmFocus,
            label: 'Confirmar',
            hint: '••••••',
            onChanged: (v) => viewModel.setConfirmPassword(v ?? ''),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Requerido';
              if (v != viewModel.password) return 'No coinciden';
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRolSection(AuthViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Rol',
            style: TextStyle(
                fontSize: 14, color: _C.textLabel,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _RolCard(
                label: 'Empleado',
                icon: Icons.person_outline_rounded,
                selected: viewModel.rol == 'empleado',
                onTap: () => viewModel.setRol('empleado'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RolCard(
                label: 'Gerente',
                icon: Icons.work_outline_rounded,
                selected: viewModel.rol == 'gerente',
                onTap: () => viewModel.setRol('gerente'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSalarioField(AuthViewModel viewModel) {
    return _SnakeTextField(
      focusNode: _salarioFocus,
      label: 'Salario por hora',
      hint: '50.00',
      keyboardType: TextInputType.number,
      onChanged: (v) => viewModel.setSalarioPorHora(double.tryParse(v) ?? 0),
      suffix: const Text('MXN/hr',
          style: TextStyle(fontSize: 12, color: _C.textHint)),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Ingrese el salario';
        if (double.tryParse(v) == null) return 'Número inválido';
        if (double.parse(v) <= 0) return 'Debe ser mayor a 0';
        return null;
      },
    );
  }

  Widget _buildRegisterButton(AuthViewModel viewModel) {
    return _ScaleButton(
      onPressed: viewModel.isLoading ? null : () => _handleRegister(viewModel),
      child: Container(
        width: double.infinity, height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: _C.primary,
          boxShadow: [
            BoxShadow(
              color: _C.primary.withValues(alpha: 0.35),
              blurRadius: 16, offset: const Offset(0, 4),
            ),
          ],
        ),
        child: viewModel.isLoading
            ? const Center(
                child: SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text('Crear cuenta',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ],
              ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 14, color: _C.textSub),
            children: [
              const TextSpan(text: '¿Ya tienes cuenta? '),
              TextSpan(
                text: 'Inicia sesión',
                style: const TextStyle(
                  color: _C.primaryLight, fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Widget: Campo con animación serpiente ────────────────────────────────────

class _SnakeTextField extends StatefulWidget {
  final FocusNode focusNode;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final Widget? suffix;
  final void Function(String)? onChanged;
  final String? Function(String?)? validator;

  const _SnakeTextField({
    required this.focusNode,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.suffix,
    this.onChanged,
    this.validator,
  });

  @override
  State<_SnakeTextField> createState() => _SnakeTextFieldState();
}

class _SnakeTextFieldState extends State<_SnakeTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _snakeCtrl;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _snakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    widget.focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() => _isFocused = widget.focusNode.hasFocus);
    if (_isFocused && !_snakeCtrl.isAnimating) {
      _snakeCtrl.repeat();
    } else if (!_isFocused && _snakeCtrl.isAnimating) {
      _snakeCtrl.stop();
      _snakeCtrl.value = 0;
    }
  }

  @override
  void dispose() {
    _snakeCtrl.dispose();
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 14, color: Color(0xFF1A4FD8), fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _snakeCtrl,
          builder: (_, child) {
            return CustomPaint(
              painter: _isFocused
                  ? _SnakeBorderPainter(
                      progress: _snakeCtrl.value, radius: 10)
                  : _StaticBorderPainter(radius: 10),
              child: child,
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: _C.bgField,
            ),
            child: TextFormField(
              focusNode: widget.focusNode,
              keyboardType: widget.keyboardType,
              obscureText: widget.obscureText,
              onChanged: widget.onChanged,
              validator: widget.validator,
              style: const TextStyle(
                color: _C.textField, fontSize: 15, fontWeight: FontWeight.w500,
              ),
              cursorColor: _C.primaryLight,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: const TextStyle(
                    color: _C.textHint, fontSize: 15, fontWeight: FontWeight.w400),
                suffixIcon: widget.suffixIcon,
                suffix: widget.suffix,
                filled: false,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFFE53935), width: 1),
                ),
                errorStyle:
                    const TextStyle(color: Color(0xFFE53935), fontSize: 11),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Widget: Campo de contraseña con animación serpiente ──────────────────────

class _SnakePasswordField extends StatefulWidget {
  final FocusNode focusNode;
  final String label;
  final String hint;
  final void Function(String)? onChanged;
  final String? Function(String?)? validator;

  const _SnakePasswordField({
    required this.focusNode,
    required this.label,
    required this.hint,
    this.onChanged,
    this.validator,
  });

  @override
  State<_SnakePasswordField> createState() => _SnakePasswordFieldState();
}

class _SnakePasswordFieldState extends State<_SnakePasswordField>
    with SingleTickerProviderStateMixin {
  late AnimationController _snakeCtrl;
  bool _isFocused = false;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _snakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    widget.focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() => _isFocused = widget.focusNode.hasFocus);
    if (_isFocused && !_snakeCtrl.isAnimating) {
      _snakeCtrl.repeat();
    } else if (!_isFocused && _snakeCtrl.isAnimating) {
      _snakeCtrl.stop();
      _snakeCtrl.value = 0;
    }
  }

  @override
  void dispose() {
    _snakeCtrl.dispose();
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 14, color: Color(0xFF1A4FD8), fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _snakeCtrl,
          builder: (_, child) {
            return CustomPaint(
              painter: _isFocused
                  ? _SnakeBorderPainter(
                      progress: _snakeCtrl.value, radius: 10)
                  : _StaticBorderPainter(radius: 10),
              child: child,
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: _C.bgField,
            ),
            child: TextFormField(
              focusNode: widget.focusNode,
              obscureText: _obscureText,
              onChanged: widget.onChanged,
              validator: widget.validator,
              style: const TextStyle(
                color: _C.textField, fontSize: 15, fontWeight: FontWeight.w500,
              ),
              cursorColor: _C.primaryLight,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: const TextStyle(
                    color: _C.textHint, fontSize: 15, fontWeight: FontWeight.w400),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20, color: _C.textHint,
                  ),
                  onPressed: () =>
                      setState(() => _obscureText = !_obscureText),
                ),
                filled: false,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFFE53935), width: 1),
                ),
                errorStyle:
                    const TextStyle(color: Color(0xFFE53935), fontSize: 11),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Widget: Tarjeta de Rol ───────────────────────────────────────────────────

class _RolCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RolCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF0F6FF) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? _C.primaryLight : _C.border,
            width: selected ? 2.0 : 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _C.primaryLight.withValues(alpha: 0.15),
                    blurRadius: 12, offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: _C.border.withValues(alpha: 0.4),
                    blurRadius: 4, offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18,
                color: selected ? _C.primaryLight : _C.textHint),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? _C.primaryLight : _C.textHint,
                )),
          ],
        ),
      ),
    );
  }
}

// ─── Widget: Botón con animación scale ───────────────────────────────────────

class _ScaleButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;

  const _ScaleButton({required this.onPressed, required this.child});

  @override
  State<_ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<_ScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) {
        _ctrl.forward();
        widget.onPressed?.call();
      },
      onTapCancel: () => _ctrl.forward(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) =>
            Transform.scale(scale: _ctrl.value, child: child),
        child: widget.child,
      ),
    );
  }
}

// ─── Painter: Serpiente animada ───────────────────────────────────────────────

class _SnakeBorderPainter extends CustomPainter {
  final double progress;
  final double radius;
  static const double _tailLength = 0.28;
  static const int _steps = 160;

  const _SnakeBorderPainter({required this.progress, required this.radius});

  double _perimeter(double w, double h, double r) =>
      2 * (w - 2 * r) + 2 * (h - 2 * r) + 2 * pi * r;

  Offset _pointOnRect(double t, double w, double h, double r) {
    final P = _perimeter(w, h, r);
    double d = ((t % 1.0) + 1.0) % 1.0 * P;

    final segs = <(double, Offset Function(double))>[
      (w - 2 * r, (p) => Offset(r + p, 0)),
      (pi / 2 * r, (p) => Offset(w - r + sin(p / r) * r, r - cos(p / r) * r)),
      (h - 2 * r, (p) => Offset(w, r + p)),
      (pi / 2 * r, (p) => Offset(w - r + cos(p / r) * r, h - r + sin(p / r) * r)),
      (w - 2 * r, (p) => Offset(w - r - p, h)),
      (pi / 2 * r, (p) => Offset(r - sin(p / r) * r, h - r + cos(p / r) * r)),
      (h - 2 * r, (p) => Offset(0, h - r - p)),
      (pi / 2 * r, (p) => Offset(r - cos(p / r) * r, r - sin(p / r) * r)),
    ];

    for (final (len, fn) in segs) {
      if (d <= len) return fn(d);
      d -= len;
    }
    return Offset(r, 0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = radius;

    for (int i = 0; i < _steps; i++) {
      final frac = i / _steps;
      final t =
          ((progress - _tailLength + frac * _tailLength) % 1.0 + 1.0) % 1.0;
      final pt = _pointOnRect(t, w, h, r);

      final alpha = pow(frac, 0.5).toDouble() * 0.92;
      final dotSize = 1.4 + frac * 2.8;
      final blue = (150 + frac * 105).round();

      canvas.drawCircle(
        pt, dotSize,
        Paint()..color = Color.fromRGBO(0, blue, 255, alpha),
      );
    }

    // Cabeza brillante con glow
    final head = _pointOnRect(progress, w, h, r);
    canvas.drawCircle(
      head, 5.0,
      Paint()
        ..color = const Color(0xFF00B4FF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(head, 3.5, Paint()..color = const Color(0xFF00D4FF));
  }

  @override
  bool shouldRepaint(_SnakeBorderPainter old) => old.progress != progress;
}

// ─── Painter: Borde estático ──────────────────────────────────────────────────

class _StaticBorderPainter extends CustomPainter {
  final double radius;
  const _StaticBorderPainter({required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
        Radius.circular(radius),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFFC8DEFF),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─── Painter: Ola inferior ────────────────────────────────────────────────────

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * 0.5)
        ..cubicTo(
          size.width * 0.25, size.height * 0.15,
          size.width * 0.75, size.height * 0.85,
          size.width, size.height * 0.43,
        )
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
      Paint()
        ..color = const Color(0xFFDDEEFF).withValues(alpha: 0.7)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}