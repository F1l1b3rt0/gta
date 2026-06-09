import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/perfil_service.dart';
import 'chat_view.dart';

class PerfilEmpleadoView extends StatefulWidget {
  const PerfilEmpleadoView({super.key});

  @override
  State<PerfilEmpleadoView> createState() => _PerfilEmpleadoViewState();
}

class _PerfilEmpleadoViewState extends State<PerfilEmpleadoView>
    with SingleTickerProviderStateMixin {
  final PerfilService _perfilService = PerfilService();
  Map<String, dynamic> _perfil = {};
  bool _isLoading = true;
  bool _editandoNombre = false;
  final TextEditingController _nombreController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String _qrData = '';
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _cargarPerfil();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _cargarPerfil() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _perfil = await _perfilService.obtenerPerfil(user.id);

      final qrData = {
        'empleado_id': _perfil['id'],
        'nombre': _perfil['nombre'],
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      _qrData = jsonEncode(qrData);
      _animationController.forward();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _cambiarNombre() async {
    final nuevoNombre = _nombreController.text.trim();
    if (nuevoNombre.isEmpty || nuevoNombre == _perfil['nombre']) return;

    setState(() => _isLoading = true);
    final success =
        await _perfilService.actualizarNombre(_perfil['id'], nuevoNombre);

    if (success) {
      setState(() {
        _perfil['nombre'] = nuevoNombre;
        _editandoNombre = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✓ Nombre actualizado correctamente'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✗ Error al actualizar'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _subirFoto() async {
    final XFile? imagen = await _picker.pickImage(source: ImageSource.gallery);
    if (imagen == null) return;

    setState(() => _isLoading = true);
    final url = await _perfilService.subirFotoPerfil(_perfil['id'], File(imagen.path));

    if (url != null) {
      setState(() => _perfil['avatar_url'] = url);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✓ Foto actualizada'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _compartirQR() async {
    await Share.share(
      'Mi código QR de GTA - ${_perfil['nombre']}\n'
      'Usa este código para registrar mi asistencia.',
      subject: 'Mi QR de GTA',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: const Icon(Icons.refresh, size: 24),
              onPressed: () {
                _animationController.reset();
                _cargarPerfil();
              },
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withAlpha(200),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Fondo con gradiente
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.green.shade400,
                        Colors.green.shade600,
                        Colors.teal.shade700,
                      ],
                    ),
                  ),
                  height: 300,
                ),
                // Contenido
                SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 100),
                  child: Column(
                    children: [
                      // ========== CARD DE PERFIL ==========
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: FadeTransition(
                          opacity: Tween<double>(begin: 0, end: 1).animate(
                            CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(25),
                                  blurRadius: 30,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(28),
                              child: Column(
                                children: [
                                  // Avatar con efecto
                                  GestureDetector(
                                    onTap: _subirFoto,
                                    child: MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: Stack(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.green.shade300
                                                      .withAlpha(100),
                                                  blurRadius: 20,
                                                  spreadRadius: 5,
                                                ),
                                              ],
                                            ),
                                            child: CircleAvatar(
                                              radius: 70,
                                              backgroundColor: Colors.green.shade100,
                                              backgroundImage:
                                                  _perfil['avatar_url'] != null
                                                      ? NetworkImage(_perfil['avatar_url'])
                                                      : null,
                                              child: _perfil['avatar_url'] == null
                                                  ? Text(
                                                      _perfil['nombre']?.isNotEmpty == true
                                                          ? _perfil['nombre'][0]
                                                              .toUpperCase()
                                                          : '?',
                                                      style: const TextStyle(
                                                        fontSize: 48,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.green,
                                                      ),
                                                    )
                                                  : null,
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 0,
                                            right: 0,
                                            child: Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.green.shade500,
                                                    Colors.teal.shade600,
                                                  ],
                                                ),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 3,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.camera_alt,
                                                size: 22,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Nombre
                                  if (!_editandoNombre)
                                    Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                _perfil['nombre'] ?? 'Empleado',
                                                style: const TextStyle(
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF1a1a1a),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.edit, size: 22),
                                              onPressed: () {
                                                _nombreController.text =
                                                    _perfil['nombre'] ?? '';
                                                setState(
                                                    () => _editandoNombre = true);
                                              },
                                              style: IconButton.styleFrom(
                                                backgroundColor:
                                                    Colors.grey.shade100,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    )
                                  else
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _nombreController,
                                            autofocus: true,
                                            decoration: InputDecoration(
                                              hintText: 'Nuevo nombre',
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color: Colors.green.shade300,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color: Colors.green.shade600,
                                                  width: 2,
                                                ),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.check,
                                              color: Colors.green, size: 24),
                                          onPressed: _cambiarNombre,
                                          style: IconButton.styleFrom(
                                            backgroundColor:
                                                Colors.green.shade100,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close,
                                              color: Colors.red, size: 24),
                                          onPressed: () =>
                                              setState(() => _editandoNombre = false),
                                          style: IconButton.styleFrom(
                                            backgroundColor:
                                                Colors.red.shade100,
                                          ),
                                        ),
                                      ],
                                    ),

                                  const SizedBox(height: 8),
                                  Text(
                                    _perfil['email'] ?? '',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Badge de rol
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: _perfil['rol'] == 'gerente'
                                          ? LinearGradient(
                                              colors: [
                                                Colors.blue.shade400,
                                                Colors.blue.shade600,
                                              ],
                                            )
                                          : LinearGradient(
                                              colors: [
                                                Colors.green.shade400,
                                                Colors.teal.shade600,
                                              ],
                                            ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _perfil['rol'] == 'gerente'
                                              ? Colors.blue.shade300
                                                  .withAlpha(50)
                                              : Colors.green.shade300
                                                  .withAlpha(50),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      _perfil['rol'] == 'gerente'
                                          ? '👔 Gerente'
                                          : '👤 Empleado',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ========== INFORMACIÓN ==========
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            _buildInfoCard(
                              icon: Icons.attach_money,
                              title: 'Salario por hora',
                              value: '\$${_perfil['salario_por_hora'] ?? 0}/h',
                              color: Colors.amber,
                            ),
                            const SizedBox(height: 12),
                            _buildInfoCard(
                              icon: Icons.calendar_today,
                              title: 'Miembro desde',
                              value: _perfil['created_at'] != null
                                  ? _perfil['created_at']
                                      .toString()
                                      .substring(0, 10)
                                  : '---',
                              color: Colors.purple,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ========== SECCIÓN QR ==========
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(15),
                                blurRadius: 25,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.green.shade400,
                                            Colors.teal.shade600,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.qr_code_2,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text(
                                        'Código QR de Asistencia',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1a1a1a),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                      width: 2,
                                    ),
                                  ),
                                  child: QrImageView(
                                    data: _qrData,
                                    version: QrVersions.auto,
                                    size: 220,
                                    backgroundColor: Colors.white,
                                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Muestra este QR a tu gerente para registrar tu asistencia',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _compartirQR,
                                    icon: const Icon(Icons.share, size: 20),
                                    label: const Text('Compartir QR'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.shade600,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ========== BOTÓN CHAT ==========
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ChatView(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.chat_bubble, size: 20),
                            label: const Text('Abrir Chat'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 4,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1a1a1a),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}