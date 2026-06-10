// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GerenteChatView extends StatefulWidget {
  const GerenteChatView({super.key});

  @override
  State<GerenteChatView> createState() => _GerenteChatViewState();
}

class _GerenteChatViewState extends State<GerenteChatView>
    with SingleTickerProviderStateMixin {
  final TextEditingController _mensajeController = TextEditingController();
  List<Map<String, dynamic>> _mensajes = [];
  bool _isLoading = true;
  String _gerenteId = '';
  String _gerenteNombre = '';
  RealtimeChannel? _channel;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _cargarDatos();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _mensajeController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) { setState(() => _isLoading = false); return; }
    try {
      final gerente = await Supabase.instance.client
          .from('gerentes')
          .select('id, nombre')
          .eq('user_id', user.id)
          .maybeSingle();
      if (gerente != null) {
        _gerenteId = gerente['id'] ?? '';
        _gerenteNombre = gerente['nombre'] ?? 'Gerente';
      }
    } catch (_) {}
    await _cargarMensajes();
    _suscribir();
  }

  Future<void> _cargarMensajes() async {
    try {
      final res = await Supabase.instance.client
          .from('mensajes_gerentes')
          .select()
          .order('created_at', ascending: false)
          .limit(60);
      if (mounted) setState(() { _mensajes = List<Map<String, dynamic>>.from(res); _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _suscribir() {
    _channel = Supabase.instance.client
        .channel('mensajes_gerentes_ch')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'mensajes_gerentes',
          callback: (payload) {
            if (mounted) setState(() => _mensajes.insert(0, Map<String, dynamic>.from(payload.newRecord)));
          },
        )
        .subscribe();
  }

  Future<void> _enviar() async {
    final texto = _mensajeController.text.trim();
    if (texto.isEmpty || _gerenteId.isEmpty) return;
    _mensajeController.clear();
    try {
      await Supabase.instance.client.from('mensajes_gerentes').insert({
        'gerente_id': _gerenteId,
        'gerente_nombre': _gerenteNombre,
        'mensaje': texto,
      });
    } catch (_) {}
  }

  Future<void> _editar(String id, String nuevoTexto) async {
    try {
      await Supabase.instance.client
          .from('mensajes_gerentes')
          .update({'mensaje': nuevoTexto})
          .eq('id', id);
      if (mounted) setState(() {
        final idx = _mensajes.indexWhere((m) => m['id'].toString() == id);
        if (idx != -1) _mensajes[idx] = {..._mensajes[idx], 'mensaje': nuevoTexto};
      });
    } catch (_) {}
  }

  Future<void> _eliminar(String id) async {
    try {
      await Supabase.instance.client.from('mensajes_gerentes').delete().eq('id', id);
      if (mounted) setState(() => _mensajes.removeWhere((m) => m['id'].toString() == id));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(children: [
              Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withAlpha(180),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(children: [
                    _buildHeader(),
                    Expanded(child: _buildMensajes()),
                    _buildInput(),
                  ]),
                ),
              ),
            ]),
    );
  }

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
    child: Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Chat Gerentes',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 2),
          Text('${_mensajes.length} mensajes',
            style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ]),
      ),
      GestureDetector(
        onTap: _cargarMensajes,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white.withAlpha(150), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
        ),
      ),
    ]),
  );

  Widget _buildMensajes() => _mensajes.isEmpty
      ? Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: Theme.of(context).colorScheme.primary.withAlpha(120)),
            const SizedBox(height: 16),
            const Text('Sin mensajes aún', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Sé el primero en escribir', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withAlpha(150))),
          ]),
        )
      : ListView.builder(
          reverse: true,
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
          itemCount: _mensajes.length,
          itemBuilder: (_, i) {
            final m = _mensajes[i];
            final esPropio = m['gerente_id']?.toString() == _gerenteId;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: _buildBubble(m, esPropio),
            );
          },
        );

  Widget _buildBubble(Map<String, dynamic> m, bool esPropio) {
    final nombre = m['gerente_nombre'] ?? 'Gerente';
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'G';
    final cs = Theme.of(context).colorScheme;

    final avatar = CircleAvatar(
      radius: 16,
      backgroundColor: esPropio ? cs.primary.withAlpha(60) : Colors.grey.shade200,
      child: Text(inicial,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
          color: esPropio ? cs.primary : Colors.grey.shade700)),
    );

    final bubble = GestureDetector(
      onLongPress: esPropio ? () => _mostrarOpciones(m) : null,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
        child: Container(
          decoration: BoxDecoration(
            gradient: esPropio ? LinearGradient(colors: [cs.primary, cs.primary.withAlpha(200)]) : null,
            color: esPropio ? null : cs.surface,
            borderRadius: BorderRadius.circular(18),
            border: !esPropio ? Border.all(color: cs.primary.withAlpha(30)) : null,
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: esPropio ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!esPropio)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(nombre, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cs.onSurface.withAlpha(160))),
                ),
              Text(m['mensaje'] ?? '',
                style: TextStyle(fontSize: 14, color: esPropio ? Colors.white : cs.onSurface, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(_formatTime(m['created_at']),
                style: TextStyle(fontSize: 10, color: esPropio ? Colors.white60 : cs.onSurface.withAlpha(100))),
            ],
          ),
        ),
      ),
    );

    return Row(
      mainAxisAlignment: esPropio ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: esPropio
          ? [bubble, const SizedBox(width: 8), avatar]
          : [avatar, const SizedBox(width: 8), bubble],
    );
  }

  String _formatTime(dynamic ts) {
    if (ts == null) return '';
    try {
      final dt = DateTime.parse(ts.toString()).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return ''; }
  }

  void _mostrarOpciones(Map<String, dynamic> mensaje) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          ListTile(
            leading: Container(padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.edit_rounded, color: Colors.blue.shade600)),
            title: const Text('Editar mensaje', style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () { Navigator.pop(context); _mostrarEditar(mensaje); },
          ),
          ListTile(
            leading: Container(padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.delete_rounded, color: Colors.red.shade600)),
            title: const Text('Eliminar mensaje', style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () { Navigator.pop(context); _confirmarEliminar(mensaje['id'].toString()); },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _mostrarEditar(Map<String, dynamic> mensaje) {
    final ctrl = TextEditingController(text: mensaje['mensaje'] ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Editar mensaje'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: null,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              final texto = ctrl.text.trim();
              if (texto.isEmpty) return;
              Navigator.pop(ctx);
              await _editar(mensaje['id'].toString(), texto);
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text('Mensaje editado'),
                backgroundColor: Colors.green.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 2),
              ));
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _confirmarEliminar(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar mensaje'),
        content: const Text('¿Eliminar este mensaje?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () { Navigator.pop(context); _eliminar(id); },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: cs.surface,
      boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 20, offset: const Offset(0, -4))],
    ),
    child: Row(children: [
      Expanded(
        child: TextField(
          controller: _mensajeController,
          style: TextStyle(color: cs.onSurface),
          decoration: InputDecoration(
            hintText: 'Mensaje para gerentes...',
            hintStyle: TextStyle(color: cs.onSurface.withAlpha(100)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: cs.primary.withAlpha(isDark ? 60 : 40))),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: cs.primary.withAlpha(isDark ? 60 : 40))),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: cs.primary, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            filled: true,
            fillColor: isDark ? cs.surface.withAlpha(220) : cs.surface,
          ),
          maxLines: null,
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => _enviar(),
        ),
      ),
      const SizedBox(width: 10),
      Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _enviar,
            borderRadius: BorderRadius.circular(24),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
    ]),
  );
  }
}
