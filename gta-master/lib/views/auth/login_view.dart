// ignore_for_file: unused_element_parameter, unused_field

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import 'register_view.dart';

// ─── Paleta de colores (tema blanco/azul) ─────────────────────────────────────
class _C {
  // Fondos
  static const bg          = Color(0xFFFFFFFF); // blanco puro
  static const bgCard      = Color(0xFFF0F6FF); // azul muy claro para cards
  static const bgField     = Color(0xFFEAF2FF); // azul pastel para inputs
  static const bgLogoBg    = Color.fromARGB(255, 0, 0, 0); // fondo círculo logo

  // Azules principales
  static const primary     = Color(0xFF0057D9); // azul principal
  static const primaryDark = Color(0xFF003DA0); // hover/glow
  static const accent      = Color(0xFF0099FF); // azul claro / cian
  static const accentLight = Color(0xFF4FC3FF); // partículas / brillo

  // Texto
  static const textTitle   = Color(0xFF001845); // texto fuerte
  static const textSub     = Color(0xFF1565C0); // subtítulos y labels
  static const textHint    = Color(0xFF90B4D8); // placeholder
  static const textField   = Color(0xFF0D2A55); // texto en campos
  static const textMuted   = Color(0xFFB0C8E8); // separador "o"

  // Bordes
  static const border      = Color.fromARGB(255, 125, 188, 255); // borde suave
  static const divider     = Color(0xFFD0E5F8);

  // Sombras / glow
  static const glow1       = Color(0x400099FF);
  static const glow2       = Color(0x200057D9);
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey              = GlobalKey<FormState>();
  final _emailController      = TextEditingController();
  final _passwordController   = TextEditingController();
  final _authService          = AuthService();

  bool _isLoading       = false;
  bool _obscurePassword = true;

  // Animaciones
  late AnimationController _logoController;
  late AnimationController _ringController;
  late AnimationController _contentController;
  late AnimationController _particlesController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _contentSlide;
  late Animation<double> _contentOpacity;

  // Foco
  final _emailFocus = FocusNode();
  final _passFocus  = FocusNode();
  bool _emailFocused = false;
  bool _passFocused  = false;

  // Partículas
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _particlesController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _logoScale = Tween<double>(begin: 0.1, end: 1.5).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    _contentSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic),
    );
    _contentOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeIn),
    );

    for (int i = 0; i < 18; i++) {
      _particles.add(_Particle.random(_random));
    }

    Future.delayed(const Duration(milliseconds: 100), () {
      _logoController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      _contentController.forward();
    });

    _emailFocus.addListener(() {
      setState(() => _emailFocused = _emailFocus.hasFocus);
    });
    _passFocus.addListener(() {
      setState(() => _passFocused = _passFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _ringController.dispose();
    _contentController.dispose();
    _particlesController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // ✅ Pasar 3 argumentos: email, password, userData (vacío para login)
      await _authService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        {}, // ← UserData vacío (solo autenticación)
      );

      // Obtener el tipo de usuario
      final userType = await _authService.getUserType();

      if (mounted) {
        if (userType == 'gerente') {
          Navigator.pushReplacementNamed(context, '/gerente_home');
        } else if (userType == 'empleado') {
          Navigator.pushReplacementNamed(context, '/empleado_home');
        } else {
          _mostrarError('Tipo de usuario no identificado');
        }
      }
    } catch (e) {
      // ✅ Captura el error correctamente
      if (mounted) {
        _mostrarError(e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Helper para mostrar mensajes de error
  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: _C.primaryDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Obtiene el tipo de usuario (rol) del usuario autenticado
  Future<String?> getUserType() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      
      if (user == null) return null;
      
      // Consultar el rol en la tabla empleados
      final response = await Supabase.instance.client
          .from('empleados')
          .select('rol')
          .eq('id', user.id)
          .maybeSingle();
      
      return response?['rol'] as String?;
    } catch (e) {
      debugPrint('Error al obtener tipo de usuario: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          // Degradado de fondo superior azul suave
          _buildGradientBackground(),
          // Grid punteado sutil
          _buildGridBackground(),
          // Orbe de luz superior
          _buildTopOrb(),
          // Partículas flotantes
          _buildParticles(),
          // Línea de escaneo (muy sutil)
          _buildScanLine(),
          // Ola decorativa inferior
          _buildBottomWave(),
          // Contenido principal
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    _buildLogo(),
                    const SizedBox(height: 20),
                    _buildTitleBlock(),
                    const SizedBox(height: 36),
                    _buildFormContent(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Gradiente de fondo ───────────────────────────────────────────────────

  Widget _buildGradientBackground() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: MediaQuery.of(context).size.height * 0.45,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFD6EAFF),
              Color(0xFFFFFFFF),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Fondo con grid ───────────────────────────────────────────────────────

  Widget _buildGridBackground() {
    return CustomPaint(
      size: MediaQuery.of(context).size,
      painter: _GridPainter(),
    );
  }

  // ─── Orbe de luz superior ────────────────────────────────────────────────

  Widget _buildTopOrb() {
    return Positioned(
      top: -60,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _particlesController,
        builder: (_, _) {
          final pulse = (sin(_particlesController.value * 2 * pi) + 1) / 2;
          return Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color.lerp(
                      const Color(0x500099FF),
                      const Color(0x700057D9),
                      pulse,
                    )!,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Partículas flotantes ────────────────────────────────────────────────

  Widget _buildParticles() {
    return AnimatedBuilder(
      animation: _particlesController,
      builder: (_, _) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _ParticlesPainter(_particles, _particlesController.value),
        );
      },
    );
  }

  // ─── Línea de escaneo ────────────────────────────────────────────────────

  Widget _buildScanLine() {
    return AnimatedBuilder(
      animation: _particlesController,
      builder: (_, _) {
        final h = MediaQuery.of(context).size.height;
        final y = (_particlesController.value * h * 2) % (h * 2) - h;
        return Positioned(
          top: y,
          left: 0,
          right: 0,
          child: Container(
            height: h * 0.5,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Color(0x060099FF),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Ola decorativa inferior ──────────────────────────────────────────────

  Widget _buildBottomWave() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: CustomPaint(
        size: Size(MediaQuery.of(context).size.width, 120),
        painter: _WavePainter(),
      ),
    );
  }

  // ─── Logo con anillo giratorio ────────────────────────────────────────────

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([_logoController, _ringController]),
      builder: (_, _) {
        return Opacity(
          opacity: _logoOpacity.value,
          child: Transform.scale(
            scale: _logoScale.value,
            child: SizedBox(
              width: 88,
              height: 88,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Halo exterior difuso
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _C.accent.withOpacity(0.30),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  // Anillo giratorio
                  Transform.rotate(
                    angle: _ringController.value * 2 * pi,
                    child: CustomPaint(
                      size: const Size(88, 88),
                      painter: _SpinningRingPainter(),
                    ),
                  ),
                  // Fondo claro del logo
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _C.bgLogoBg,
                      border: Border.all(color: _C.border, width: 1),
                    ),
                  ),
                  // Imagen del logo
                  ClipOval(
                    child: Image.asset(
                      'assets/icon/icon.png',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Título ───────────────────────────────────────────────────────────────

  Widget _buildTitleBlock() {
    return AnimatedBuilder(
      animation: _contentController,
      builder: (_, _) {
        return Opacity(
          opacity: _contentOpacity.value,
          child: Transform.translate(
            offset: Offset(0, _contentSlide.value),
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF0057D9), Color(0xFF0099FF)],
                  ).createShader(bounds),
                  child: const Text(
                    'ACCESO',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 6,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'BIENVENIDO A GTA',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: _C.textSub.withOpacity(0.7),
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Formulario ───────────────────────────────────────────────────────────

  Widget _buildFormContent() {
    return AnimatedBuilder(
      animation: _contentController,
      builder: (_, _) {
        return Opacity(
          opacity: _contentOpacity.value,
          child: Transform.translate(
            offset: Offset(0, _contentSlide.value * 1.2),
            child: Column(
              children: [
                _NeonTextField(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  isFocused: _emailFocused,
                  label: 'CORREO ELECTRÓNICO',
                  hint: 'tu@correo.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingrese su correo';
                    if (!v.contains('@')) return 'Correo inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                _NeonTextField(
                  controller: _passwordController,
                  focusNode: _passFocus,
                  isFocused: _passFocused,
                  label: 'CONTRASEÑA',
                  hint: '••••••••',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18,
                      color: _C.textSub.withOpacity(0.6),
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingrese su contraseña';
                    if (v.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // ¿Olvidaste tu contraseña?
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      '¿Olvidaste tu contraseña?',
                      style: TextStyle(
                        fontSize: 11,
                        color: _C.primary.withOpacity(0.75),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Botón Iniciar Sesión
                _GlowButton(
                  onPressed: _isLoading ? null : _login,
                  isLoading: _isLoading,
                  label: 'INICIAR SESIÓN',
                  primary: true,
                ),
                const SizedBox(height: 18),

                // Divider
                Row(
                  children: [
                    Expanded(child: Container(height: 1, color: _C.divider)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'o',
                        style: TextStyle(fontSize: 11, color: _C.textMuted),
                      ),
                    ),
                    Expanded(child: Container(height: 1, color: _C.divider)),
                  ],
                ),
                const SizedBox(height: 18),

                // Botón Registrarse
                _GlowButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, anim, _) => const RegisterScreen(),
                        transitionsBuilder: (_, anim, _, child) {
                          return FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.05, 0),
                                end: Offset.zero,
                              ).animate(anim),
                              child: child,
                            ),
                          );
                        },
                      ),
                    );
                  },
                  label: 'REGISTRARSE',
                  primary: false,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Widget: Campo con borde sweep giratorio ──────────────────────────────────

class _NeonTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final Widget? suffix;
  final String? Function(String?)? validator;

  const _NeonTextField({
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.suffix,
    this.validator,
  });

  @override
  State<_NeonTextField> createState() => _NeonTextFieldState();
}

class _NeonTextFieldState extends State<_NeonTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _sweepCtrl;

  @override
  void initState() {
    super.initState();
    _sweepCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.isFocused) _sweepCtrl.repeat();
  }

  @override
  void didUpdateWidget(_NeonTextField old) {
    super.didUpdateWidget(old);
    if (widget.isFocused && !_sweepCtrl.isAnimating) {
      _sweepCtrl.repeat();
    } else if (!widget.isFocused && _sweepCtrl.isAnimating) {
      _sweepCtrl.stop();
      _sweepCtrl.value = 0;
    }
  }

  @override
  void dispose() {
    _sweepCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.5,
            color: _C.textSub,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        AnimatedBuilder(
          animation: _sweepCtrl,
          builder: (_, child) {
            return CustomPaint(
              painter: widget.isFocused
                  ? _SweepBorderPainter(
                      progress: _sweepCtrl.value,
                      radius: 12,
                      strokeWidth: 2.0,
                    )
                  : _StaticBorderPainter(radius: 12),
              child: child,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: _C.bgField,
              boxShadow: widget.isFocused
                  ? [
                      BoxShadow(
                        color: _C.glow1,
                        blurRadius: 14,
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: _C.glow2,
                        blurRadius: 28,
                        spreadRadius: 0,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: _C.border.withOpacity(0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: TextFormField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              keyboardType: widget.keyboardType,
              obscureText: widget.obscureText,
              validator: widget.validator,
              style: TextStyle(
                color: _C.textField,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              cursorColor: _C.primary,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: TextStyle(color: _C.textHint, fontSize: 14),
                prefixIcon: Icon(
                  widget.icon,
                  size: 18,
                  color: widget.isFocused ? _C.primary : _C.textHint,
                ),
                suffixIcon: widget.suffixIcon,
                suffix: widget.suffix,
                filled: false,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE53935), width: 1),
                ),
                errorStyle: const TextStyle(
                  color: Color(0xFFE53935),
                  fontSize: 11,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Widget: Botón con glow ───────────────────────────────────────────────────

class _GlowButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool primary;
  final bool isLoading;

  const _GlowButton({
    required this.onPressed,
    required this.label,
    required this.primary,
    this.isLoading = false,
  });

  @override
  State<_GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<_GlowButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _pressCtrl;
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.reverse(),
      onTapUp: (_) => _pressCtrl.forward(),
      onTapCancel: () => _pressCtrl.forward(),
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: widget.primary
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0057D9), Color(0xFF0099FF)],
                  )
                : null,
            color: widget.primary ? null : Colors.white,
            border: widget.primary
                ? null
                : Border.all(color: _C.primary, width: 1.5),
            boxShadow: widget.primary
                ? [
                    BoxShadow(
                      color: _C.primary.withOpacity(0.35),
                      blurRadius: 18,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: _C.border.withOpacity(0.5),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Brillo interior superior (solo primario)
              if (widget.primary)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 26,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.18),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              widget.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: widget.primary ? Colors.white : _C.primary,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Painters ────────────────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0099FF).withOpacity(0.055)
      ..strokeWidth = 0.5;
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SpinningRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(2, 2, size.width - 4, size.height - 4);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..shader = SweepGradient(
        colors: const [
          Colors.transparent,
          Color(0xFF0099FF),
          Color(0xFF0057D9),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.5, 1.0],
      ).createShader(rect);
    canvas.drawOval(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD6EAFF).withOpacity(0.55)
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, size.height * 0.55);
    path.cubicTo(
      size.width * 0.25, size.height * 0.3,
      size.width * 0.75, size.height * 0.8,
      size.width, size.height * 0.5,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);

    final paint2 = Paint()
      ..color = const Color(0xFFBDD8F5).withOpacity(0.35)
      ..style = PaintingStyle.fill;
    final path2 = Path();
    path2.moveTo(0, size.height * 0.75);
    path2.cubicTo(
      size.width * 0.35, size.height * 0.5,
      size.width * 0.65, size.height * 0.9,
      size.width, size.height * 0.65,
    );
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Painter: borde sweep giratorio para campos ───────────────────────────────

class _SweepBorderPainter extends CustomPainter {
  final double progress;
  final double radius;
  final double strokeWidth;

  _SweepBorderPainter({
    required this.progress,
    required this.radius,
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );

    // Glow exterior suave
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 2
      ..color = const Color(0xFF0099FF).withOpacity(0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(rect, glowPaint);

    // Borde sweep con gradiente rotado
    final sweepRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = SweepGradient(
        colors: const [
          Colors.transparent,
          Color(0xFF0099FF),
          Color(0xFF0057D9),
          Color(0xFF4FC3FF),
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        startAngle: 0,
        endAngle: 2 * pi,
        transform: GradientRotation(progress * 2 * pi),
      ).createShader(sweepRect);
    canvas.drawRRect(rect, borderPaint);
  }

  @override
  bool shouldRepaint(_SweepBorderPainter old) => old.progress != progress;
}

class _StaticBorderPainter extends CustomPainter {
  final double radius;

  _StaticBorderPainter({required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
      Radius.circular(radius),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFFBDD8F5);
    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _ParticlesPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlesPainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (final p in particles) {
      final elapsed = (progress - p.startProgress) % 1.0;
      if (elapsed < 0 || elapsed > p.duration) continue;

      final t = elapsed / p.duration;
      final opacity = t < 0.1
          ? t / 0.1
          : t > 0.9
              ? (1 - t) / 0.1
              : 1.0;

      final x = p.x * size.width;
      final y = size.height - (t * size.height * 0.6 + p.startY * size.height * 0.4);

      canvas.drawCircle(
        Offset(x, y),
        p.radius,
        paint..color = const Color(0xFF0099FF).withOpacity(opacity * 0.45),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) => true;
}

class _Particle {
  final double x;
  final double startY;
  final double startProgress;
  final double duration;
  final double radius;

  _Particle({
    required this.x,
    required this.startY,
    required this.startProgress,
    required this.duration,
    required this.radius,
  });

  factory _Particle.random(Random random) {
    return _Particle(
      x: random.nextDouble(),
      startY: random.nextDouble() * 0.4,
      startProgress: random.nextDouble(),
      duration: 0.2 + random.nextDouble() * 0.3,
      radius: 1.0 + random.nextDouble() * 1.5,
    );
  }
}