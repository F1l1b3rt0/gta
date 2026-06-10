// ignore_for_file: unused_field, deprecated_member_use, unnecessary_underscores

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'register_view.dart';
import '../empleado/empleado_home_view.dart';
import '../gerente/gerente_home_view.dart';

// ─── Paleta de colores ────────────────────────────────────────────────────────
class _C {
  static const bg           = Color(0xFFFFFFFF);
  static const bgField      = Color(0xFFFFFFFF);
  static const topbarBg     = Color(0xFFFFFFFF);

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
  static const textRemember = Color(0xFF1A4FD8);

  static const border       = Color(0xFFC8DEFF);
  static const divider      = Color(0xFFDDEEFF);

  static const waveBg       = Color(0xFFDDEEFF);
}

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthViewModel(),
      child: const _LoginContent(),
    );
  }
}

class _LoginContent extends StatefulWidget {
  const _LoginContent();

  @override
  State<_LoginContent> createState() => _LoginContentState();
}

class _LoginContentState extends State<_LoginContent>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _contentController;
  late Animation<double> _contentOpacity;
  late Animation<double> _contentSlide;

  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();

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
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(AuthViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) return;

    final success = await viewModel.login();
    if (mounted && success) {
      // Obtener el rol del usuario actual
      final userRol = await viewModel.getCurrentUserRol();
      
      if (mounted) {
        if (userRol == 'gerente') {
          // Redirigir al home del gerente
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const GerenteHomeView()),
          );
        } else if (userRol == 'empleado') {
          // Redirigir al home del empleado
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const EmpleadoHomeView()),
          );
        } else {
          _mostrarError('Tipo de usuario no identificado');
        }
      }
    } else if (mounted && viewModel.errorMessage != null) {
      _mostrarError(viewModel.errorMessage!);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: _C.primary,
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
                                const SizedBox(height: 24),
                                _buildHero(),
                                const SizedBox(height: 36),
                                _buildEmailField(viewModel),
                                const SizedBox(height: 20),
                                _buildPasswordField(viewModel),
                                const SizedBox(height: 14),
                                _buildRowExtras(viewModel),
                                const SizedBox(height: 28),
                                _buildLoginButton(viewModel),
                                const SizedBox(height: 14),
                                _buildRegisterButton(),
                                const SizedBox(height: 60),
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

  // ─── Top Bar: logo + "GTA" ────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: const Color(0xFF1A4FD8),
            backgroundImage: const AssetImage('assets/icon/icon.png'),
            onBackgroundImageError: (_, __) {},
            child: null,
          ),
          const SizedBox(width: 10),
          const Text(
            'GTA',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _C.primaryLight,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Hero: Bienvenido ─────────────────────────────────────────────────────

  Widget _buildHero() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(width: double.infinity),
        const Text(
          'Bienvenido',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: _C.primaryLight,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Inicia sesión en tu cuenta',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: _C.textSub,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField(AuthViewModel viewModel) {
    return _SnakeTextField(
      focusNode: _emailFocus,
      label: 'Correo electrónico',
      hint: 'tu@email.com',
      keyboardType: TextInputType.emailAddress,
      onChanged: viewModel.setEmail,
      validator: (v) {
        if (v == null || v.isEmpty) return 'Ingrese su correo';
        if (!v.contains('@')) return 'Correo inválido';
        return null;
      },
    );
  }

  Widget _buildPasswordField(AuthViewModel viewModel) {
    return _SnakePasswordField(
      focusNode: _passFocus,
      label: 'Contraseña',
      hint: '••••••••',
      onChanged: viewModel.setPassword,
      validator: (v) {
        if (v == null || v.isEmpty) return 'Ingrese su contraseña';
        if (v.length < 6) return 'Mínimo 6 caracteres';
        return null;
      },
    );
  }

  Widget _buildRowExtras(AuthViewModel viewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            // TODO: Implementar "Recordarme"
          ],
        ),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('¿Olvidaste tu contraseña?',
              style: TextStyle(fontSize: 14, color: _C.primaryLight)),
        ),
      ],
    );
  }

  Widget _buildLoginButton(AuthViewModel viewModel) {
    return _ScaleButton(
      onPressed: viewModel.isLoading ? null : () => _handleLogin(viewModel),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: _C.primary,
          boxShadow: [
            BoxShadow(
              color: _C.primary.withValues(alpha: 0.35),
              blurRadius: 16,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: viewModel.isLoading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Iniciar sesión',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ─── Botón Crear cuenta ───────────────────────────────────────────────────

  Widget _buildRegisterButton() {
    return _ScaleButton(
      onPressed: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, anim, __) => const RegisterView(),
            transitionsBuilder: (_, anim, __, child) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0), end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity, height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: _C.primaryMid,
          boxShadow: [
            BoxShadow(
              color: _C.primaryMid.withValues(alpha: 0.28),
              blurRadius: 12, offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Text('Crear cuenta nueva',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ),
      ),
    );
  }
}

// ─── Widget: Campo de texto con animación serpiente ────────────────────────────

class _SnakeTextField extends StatefulWidget {
  final FocusNode focusNode;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final void Function(String)? onChanged;
  final String? Function(String?)? validator;

  const _SnakeTextField({
    required this.focusNode,
    required this.label,
    required this.hint,
    this.keyboardType,
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
            fontSize: 14,
            color: Color(0xFF1A4FD8),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _snakeCtrl,
          builder: (_, child) {
            return CustomPaint(
              painter: _isFocused
                  ? _SnakeBorderPainter(progress: _snakeCtrl.value, radius: 10)
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
              onChanged: widget.onChanged,
              validator: widget.validator,
              style: const TextStyle(
                color: _C.textField,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              cursorColor: _C.primaryLight,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: const TextStyle(
                  color: _C.textHint,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
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
                  borderSide: const BorderSide(
                    color: Color(0xFFE53935),
                    width: 1,
                  ),
                ),
                errorStyle: const TextStyle(
                  color: Color(0xFFE53935),
                  fontSize: 11,
                ),
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

// ─── Widget: Campo de contraseña con animación serpiente ───────────────────────

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
            fontSize: 14,
            color: Color(0xFF1A4FD8),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _snakeCtrl,
          builder: (_, child) {
            return CustomPaint(
              painter: _isFocused
                  ? _SnakeBorderPainter(progress: _snakeCtrl.value, radius: 10)
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
                color: _C.textField,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              cursorColor: _C.primaryLight,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: const TextStyle(
                  color: _C.textHint,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: _C.textHint,
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
                  borderSide: const BorderSide(
                    color: Color(0xFFE53935),
                    width: 1,
                  ),
                ),
                errorStyle: const TextStyle(
                  color: Color(0xFFE53935),
                  fontSize: 11,
                ),
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

// ─── Widget: Botón con escala ─────────────────────────────────────────────────

class _ScaleButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;

  const _ScaleButton({
    required this.onPressed,
    required this.child,
  });

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

  const _SnakeBorderPainter({
    required this.progress,
    required this.radius,
  });

  double _perimeter(double w, double h, double r) {
    return 2 * (w - 2 * r) + 2 * (h - 2 * r) + 2 * pi * r;
  }

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
      final t = ((progress - _tailLength + frac * _tailLength) % 1.0 + 1.0) % 1.0;
      final pt = _pointOnRect(t, w, h, r);

      final alpha = pow(frac, 0.5).toDouble() * 0.92;
      final dotSize = 1.4 + frac * 2.8;
      final blue = (150 + frac * 105).round();

      final paint = Paint()
        ..color = Color.fromRGBO(0, blue, 255, alpha)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(pt, dotSize, paint);
    }

    // Cabeza brillante
    final head = _pointOnRect(progress, w, h, r);
    canvas.drawCircle(
      head,
      5.0,
      Paint()
        ..color = const Color(0xFF00B4FF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(
      head,
      3.5,
      Paint()..color = const Color(0xFF00D4FF),
    );
  }

  @override
  bool shouldRepaint(_SnakeBorderPainter old) => old.progress != progress;
}

// ─── Painter: Borde estático cuando no hay foco ───────────────────────────────

class _StaticBorderPainter extends CustomPainter {
  final double radius;
  const _StaticBorderPainter({required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
      Radius.circular(radius),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFFC8DEFF),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─── Painter: Ola inferior decorativa ────────────────────────────────────────

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFDDEEFF).withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    final path = Path()
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
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}