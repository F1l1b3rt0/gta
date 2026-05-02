// ignore_for_file: unused_field

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gta/models/gerente.dart';
import '../../services/auth_service.dart';

// ─── Paleta de colores (tema blanco/azul) ─────────────────────────────────────
class _C {
  static const bg          = Color(0xFFFFFFFF);
  static const bgCard      = Color(0xFFF0F6FF);
  static const bgField     = Color(0xFFEAF2FF);
  static const bgLogoBg    = Color.fromARGB(255, 0, 0, 0);

  static const primary     = Color(0xFF0057D9);
  static const primaryDark = Color(0xFF003DA0);
  static const accent      = Color(0xFF0099FF);
  static const accentLight = Color(0xFF4FC3FF);

  static const textTitle   = Color(0xFF001845);
  static const textSub     = Color(0xFF1565C0);
  static const textHint    = Color(0xFF90B4D8);
  static const textField   = Color(0xFF0D2A55);
  static const textMuted   = Color(0xFFB0C8E8);

  static const border      = Color(0xFFBDD8F5);
  static const divider     = Color(0xFFD0E5F8);

  static const glow1       = Color(0x400099FF);
  static const glow2       = Color(0x200057D9);
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey                  = GlobalKey<FormState>();
  final _nombreController         = TextEditingController();
  final _emailController          = TextEditingController();
  final _passwordController       = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _salarioController        = TextEditingController();

  final AuthService _authService  = AuthService();
  bool _isLoading                 = false;
  bool _obscurePassword           = true;
  bool _obscureConfirmPassword    = true;
  String _rolSeleccionado         = 'empleado';

  // Animaciones
  late AnimationController _logoController;
  late AnimationController _ringController;
  late AnimationController _contentController;
  late AnimationController _ambientController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _contentSlide;
  late Animation<double> _contentOpacity;

  // Foco
  final _nombreFocus  = FocusNode();
  final _emailFocus   = FocusNode();
  final _passFocus    = FocusNode();
  final _confirmFocus = FocusNode();
  final _salarioFocus = FocusNode();

  bool _nombreFocused  = false;
  bool _emailFocused   = false;
  bool _passFocused    = false;
  bool _confirmFocused = false;
  bool _salarioFocused = false;

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
    _ambientController = AnimationController(
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
      if (mounted) _logoController.forward();
    });
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _contentController.forward();
    });

    void addFocusListener(FocusNode node, VoidCallback cb) {
      node.addListener(cb);
    }

    addFocusListener(_nombreFocus,  () => setState(() => _nombreFocused  = _nombreFocus.hasFocus));
    addFocusListener(_emailFocus,   () => setState(() => _emailFocused   = _emailFocus.hasFocus));
    addFocusListener(_passFocus,    () => setState(() => _passFocused    = _passFocus.hasFocus));
    addFocusListener(_confirmFocus, () => setState(() => _confirmFocused = _confirmFocus.hasFocus));
    addFocusListener(_salarioFocus, () => setState(() => _salarioFocused = _salarioFocus.hasFocus));
  }

  @override
  void dispose() {
    _logoController.dispose();
    _ringController.dispose();
    _contentController.dispose();
    _ambientController.dispose();
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _salarioController.dispose();
    _nombreFocus.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    _confirmFocus.dispose();
    _salarioFocus.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      _mostrarMensaje('Las contraseñas no coinciden');
      return;
    }
  
    setState(() => _isLoading = true);
  
    try {
      if (_rolSeleccionado == 'gerente') {
        // Registrar como GERENTE
        await _authService.registerGerente(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          nombre: _nombreController.text.trim(),
          nivel: NivelGerente.senior, // Puedes agregar un selector de nivel
        );
        _mostrarMensaje('Gerente registrado exitosamente', isError: false);
      } else {
        // Registrar como EMPLEADO
        final salario = double.tryParse(_salarioController.text) ?? 0;
        await _authService.registerEmpleado(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          nombre: _nombreController.text.trim(),
          salarioPorHora: salario,
        );
        _mostrarMensaje('Empleado registrado exitosamente', isError: false);
      }
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _mostrarMensaje(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarMensaje(String mensaje, {bool isError = true}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          _buildGradientBackground(),
          _buildGridBackground(),
          _buildTopOrb(),
          _buildParticles(),
          _buildScanLine(),
          _buildBottomWave(),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildLogo(),
                          const SizedBox(height: 16),
                          _buildTitleBlock(),
                          const SizedBox(height: 28),
                          _buildFormContent(),
                        ],
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

  // ─── AppBar personalizado ─────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _C.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.border, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: _C.border.withOpacity(0.5),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 15,
                color: _C.primary,
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
        animation: _ambientController,
        builder: (_, _) {
          final pulse = (sin(_ambientController.value * 2 * pi) + 1) / 2;
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

  Widget _buildParticles() {
    return AnimatedBuilder(
      animation: _ambientController,
      builder: (_, _) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _ParticlesPainter(_particles, _ambientController.value),
        );
      },
    );
  }

  Widget _buildScanLine() {
    return AnimatedBuilder(
      animation: _ambientController,
      builder: (_, _) {
        final h = MediaQuery.of(context).size.height;
        final y = (_ambientController.value * h * 2) % (h * 2) - h;
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
                colors: [Colors.transparent, Color(0x060099FF), Colors.transparent],
              ),
            ),
          ),
        );
      },
    );
  }

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

  // ─── Logo ─────────────────────────────────────────────────────────────────

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([_logoController, _ringController]),
      builder: (_, _) {
        return Opacity(
          opacity: _logoOpacity.value,
          child: Transform.scale(
            scale: _logoScale.value,
            child: SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Halo exterior
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _C.accent.withOpacity(0.30),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  // Anillo giratorio
                  Transform.rotate(
                    angle: _ringController.value * 2 * pi,
                    child: CustomPaint(
                      size: const Size(80, 80),
                      painter: _SpinningRingPainter(),
                    ),
                  ),
                  // Fondo claro del logo
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _C.bgLogoBg,
                      border: Border.all(color: _C.border, width: 1),
                    ),
                  ),
                  ClipOval(
                    child: Image.asset(
                      'assets/icon/icon.png',
                      width: 54,
                      height: 54,
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
                    'REGISTRO',
                    style: TextStyle(
                      fontSize: 26,
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
                    color: _C.textSub.withOpacity(0.7),
                    letterSpacing: 3,
                    fontWeight: FontWeight.w500,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre
                _NeonTextField(
                  controller: _nombreController,
                  focusNode: _nombreFocus,
                  isFocused: _nombreFocused,
                  label: 'NOMBRE COMPLETO',
                  hint: 'Ana García',
                  icon: Icons.person_outline_rounded,
                  validator: (v) => v == null || v.isEmpty ? 'Ingrese el nombre' : null,
                ),
                const SizedBox(height: 16),

                // Email
                _NeonTextField(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  isFocused: _emailFocused,
                  label: 'CORREO ELECTRÓNICO',
                  hint: 'ana@empresa.com',
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingrese el correo';
                    if (!v.contains('@')) return 'Correo inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Contraseñas lado a lado
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _NeonTextField(
                        controller: _passwordController,
                        focusNode: _passFocus,
                        isFocused: _passFocused,
                        label: 'CONTRASEÑA',
                        hint: '••••••',
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 16,
                            color: _C.textHint,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Requerido';
                          if (v.length < 6) return 'Mín. 6 chars';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _NeonTextField(
                        controller: _confirmPasswordController,
                        focusNode: _confirmFocus,
                        isFocused: _confirmFocused,
                        label: 'CONFIRMAR',
                        hint: '••••••',
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscureConfirmPassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 16,
                            color: _C.textHint,
                          ),
                          onPressed: () => setState(
                              () => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Requerido' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Rol
                Text(
                  'ROL',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.5,
                    color: _C.textSub,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _NeonRolCard(
                        label: 'Empleado',
                        icon: Icons.person_outline_rounded,
                        selected: _rolSeleccionado == 'empleado',
                        onTap: () => setState(() => _rolSeleccionado = 'empleado'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _NeonRolCard(
                        label: 'Gerente',
                        icon: Icons.work_outline_rounded,
                        selected: _rolSeleccionado == 'gerente',
                        onTap: () => setState(() {
                          _rolSeleccionado = 'gerente';
                          _salarioController.clear();
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Salario (solo empleados)
                if (_rolSeleccionado == 'empleado') ...[
                  _NeonTextField(
                    controller: _salarioController,
                    focusNode: _salarioFocus,
                    isFocused: _salarioFocused,
                    label: 'SALARIO POR HORA',
                    hint: '50.00',
                    icon: Icons.attach_money_rounded,
                    keyboardType: TextInputType.number,
                    suffix: Text(
                      'MXN/hr',
                      style: TextStyle(fontSize: 12, color: _C.textHint),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Ingrese el salario';
                      if (double.tryParse(v) == null) return 'Número inválido';
                      if (double.parse(v) <= 0) return 'Debe ser mayor a 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Info gerente
                if (_rolSeleccionado == 'gerente') ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: _C.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _C.border, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: _C.glow2,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: _C.primary, size: 16),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Los gerentes no requieren salario por hora',
                            style: TextStyle(
                              fontSize: 12,
                              color: _C.textSub,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Botón registrar
                _GlowButton(
                  onPressed: _isLoading ? null : _registrar,
                  isLoading: _isLoading,
                  label: 'CREAR CUENTA',
                  primary: true,
                ),
                const SizedBox(height: 20),

                // Link login
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 13, color: _C.textMuted),
                        children: [
                          const TextSpan(text: '¿Ya tienes cuenta? '),
                          TextSpan(
                            text: 'Inicia sesión',
                            style: TextStyle(
                              color: _C.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
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
                      BoxShadow(color: _C.glow1, blurRadius: 14),
                      BoxShadow(color: _C.glow2, blurRadius: 28),
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
                errorStyle: const TextStyle(color: Color(0xFFE53935), fontSize: 11),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Widget: Tarjeta de Rol ───────────────────────────────────────────────────

class _NeonRolCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _NeonRolCard({
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? _C.bgCard : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _C.primary : _C.border,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _C.glow1,
                    blurRadius: 12,
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
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? _C.primary : _C.textHint,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? _C.primary : _C.textHint,
              ),
            ),
          ],
        ),
      ),
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
        animation: _pressCtrl,
        builder: (_, child) =>
            Transform.scale(scale: _pressCtrl.value, child: child),
        child: Container(
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
              if (widget.primary)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 26,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12)),
                      gradient: LinearGradient(
                        colors: [Colors.white.withOpacity(0.18), Colors.transparent],
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
                          strokeWidth: 2, color: Colors.white),
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