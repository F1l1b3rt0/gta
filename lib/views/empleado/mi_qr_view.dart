// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../services/language_service.dart';
import '../../services/tr.dart';

class MiQrView extends StatefulWidget {
  const MiQrView({super.key});
  @override
  State<MiQrView> createState() => _MiQrViewState();
}

class _MiQrViewState extends State<MiQrView> {
  String? _empleadoId;
  String? _nombre;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final res = await Supabase.instance.client
          .from('empleados')
          .select('id, nombre')
          .eq('user_id', user.id)
          .maybeSingle();
      if (res != null && mounted) {
        setState(() {
          _empleadoId = res['id'] as String?;
          _nombre = res['nombre'] as String?;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageService>();
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(children: [
              if (Navigator.canPop(context))
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cs.primary.withAlpha(40), width: 1.5)),
                    child: Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: cs.primary)),
                )
              else
                const SizedBox(width: 40),
              const SizedBox(width: 10),
              Text(tr(context, 'Mi código QR', 'My QR Code'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: cs.onSurface)),
            ]),
          ),
          Expanded(
            child: Center(
              child: _empleadoId == null
                ? CircularProgressIndicator(color: cs.primary)
                : _buildQrCard(cs, isDark),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildQrCard(ColorScheme cs, bool isDark) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cs.primary.withAlpha(40), width: 1.5),
          boxShadow: [BoxShadow(color: cs.primary.withAlpha(isDark ? 30 : 15), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (_nombre != null) ...[
            CircleAvatar(
              radius: 28,
              backgroundColor: cs.primary.withAlpha(20),
              child: Text(
                _nombre![0].toUpperCase(),
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: cs.primary))),
            const SizedBox(height: 10),
            Text(_nombre!,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: cs.onSurface),
              textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(tr(context, 'Empleado', 'Employee'),
              style: TextStyle(fontSize: 13, color: cs.onSurface.withAlpha(150))),
            const SizedBox(height: 20),
          ],
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.primary.withAlpha(30))),
            child: QrImageView(
              data: _empleadoId!,
              version: QrVersions.auto,
              size: 280,
              gapless: false,
              backgroundColor: Colors.white,
              eyeStyle: QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black),
              dataModuleStyle: QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: cs.primary.withAlpha(12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cs.primary.withAlpha(30))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.fingerprint_rounded, size: 14, color: cs.primary.withAlpha(200)),
              const SizedBox(width: 6),
              Text(
                _empleadoId!.length > 12
                  ? '${_empleadoId!.substring(0, 8)}...'
                  : _empleadoId!,
                style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: cs.onSurface.withAlpha(180))),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.primary.withAlpha(30))),
        child: Row(children: [
          Icon(Icons.info_outline_rounded, color: cs.primary.withAlpha(200), size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(
            tr(context,
              'Muestra este código al gerente al entrar al turno para registrar tu asistencia.',
              'Show this code to the manager when starting your shift to record your attendance.'),
            style: TextStyle(fontSize: 12, color: cs.onSurface.withAlpha(180), height: 1.5))),
        ]),
      ),
      const SizedBox(height: 16),
      GestureDetector(
        onTap: () {
          if (_empleadoId != null) {
            Clipboard.setData(ClipboardData(text: _empleadoId!));
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(tr(context, 'ID copiado', 'ID copied'),
                style: const TextStyle(color: Colors.white)),
              backgroundColor: cs.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 2),
            ));
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: cs.primary.withAlpha(15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.primary.withAlpha(60))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.copy_rounded, size: 15, color: cs.primary),
            const SizedBox(width: 8),
            Text(tr(context, 'Copiar ID', 'Copy ID'),
              style: TextStyle(color: cs.primary, fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    ]),
  );
}
