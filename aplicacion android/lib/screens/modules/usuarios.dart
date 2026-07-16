import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/firestore_service.dart';
import '../../theme.dart';

class UsuScreen extends StatefulWidget {
  const UsuScreen({super.key});
  @override
  State<UsuScreen> createState() => _UsuScreenState();
}

class _UsuScreenState extends State<UsuScreen> with SingleTickerProviderStateMixin {
  late TabController _tc;
  List<Map<dynamic, dynamic>> _usuarios = [];
  List<Map<dynamic, dynamic>> _roles = [];
  List<Map<dynamic, dynamic>> _acciones = [];
  final _fAcc = TextEditingController();
  String _fAccTxt = '';
  bool _loading = true;
  StreamSubscription? _sub;


  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 3, vsync: this);
    _sub = Fb.stream('usuarios').listen((d) => setState(() { _usuarios = d; _loading = false; }));
    Future.wait([Fb.getList('roles'), _loadAcciones()]).then((res) {
      _roles = res[0];
      _acciones = res[1];
      _acciones.sort((a, b) => (b['timestamp'] ?? '').compareTo(a['timestamp'] ?? ''));
      setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _tc.dispose();
    _fAcc.dispose();
    super.dispose();
  }

  Future<List<Map<dynamic, dynamic>>> _loadAcciones() async {
    try {
      final a = await Fb.getList('acciones');
      if (a.isNotEmpty) return a;
    } catch (_) {}
    return [];
  }

  int _nextId(List<Map<dynamic, dynamic>> list) {
    if (list.isEmpty) return 1;
    return list.map((x) => x['id'] is int ? x['id'] as int : int.tryParse(x['id'].toString()) ?? 0).reduce((a, b) => a > b ? a : b) + 1;
  }

  int _roleUserCount(String rol) => _usuarios.where((u) => (u['rol'] ?? '').toString() == rol).length;

  List<dynamic> _permisosDe(dynamic entity) {
    final raw = entity['permiso_ids'] ?? entity['permisos'];
    if (raw is List) return raw;
    return [];
  }

  // ── User CRUD ──

  Future<void> _openUser(Map? u) async {
    final us = TextEditingController(text: u?['username'] ?? '');
    final pw = TextEditingController();
    final nm = TextEditingController(text: u?['nombre_completo'] ?? u?['nombre'] ?? '');
    final em = TextEditingController(text: u?['email'] ?? '');
    final tl = TextEditingController(text: u?['telefono'] ?? '');
    final ft = TextEditingController(text: u?['foto'] ?? '');
    var fotoBase64 = u?['foto']?.toString() ?? '';
    XFile? pickedImage;
    var rol = (u?['rol'] ?? 'Cajero').toString();
    var act = u == null || u['activo'] != false;
    var permisoIdsList = _permisosDe(u ?? {});
    final edit = u != null;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          return AlertDialog(
            insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            title: Text(edit ? 'Editar Usuario' : 'Nuevo Usuario', style: TextStyle(fontWeight: FontWeight.w700, color: Tema.textDark)),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                GestureDetector(
                  onTap: () async {
                    final img = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 300);
                    if (img != null) {
                      final bytes = await img.readAsBytes();
                      fotoBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
                      pickedImage = img;
                      setSt(() {});
                    }
                  },
                  child: Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 42,
                          backgroundColor: Tema.primary.withValues(alpha: 0.1),
                          backgroundImage: pickedImage != null
                              ? FileImage(File(pickedImage!.path))
                              : (fotoBase64.isNotEmpty && fotoBase64.startsWith('data:'))
                                  ? MemoryImage(base64Decode(fotoBase64.split(',')[1]))
                                  : (fotoBase64.isNotEmpty && (fotoBase64.startsWith('http')))
                                      ? NetworkImage(fotoBase64) as ImageProvider
                                      : null,
                          child: pickedImage == null && fotoBase64.isEmpty
                              ? const Icon(Icons.camera_alt, color: Tema.primary, size: 28)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () async {
                              final img = await ImagePicker().pickImage(source: ImageSource.camera, maxWidth: 300);
                              if (img != null) {
                                final bytes = await img.readAsBytes();
                                fotoBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
                                pickedImage = img;
                                setSt(() {});
                              }
                            },
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: Tema.primary,
                              child: const Icon(Icons.add_a_photo, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 4),
                GestureDetector(
                  onTap: fotoBase64.isNotEmpty ? () {
                    setSt(() { fotoBase64 = ''; pickedImage = null; });
                  } : null,
                  child: Text(
                    fotoBase64.isNotEmpty ? 'Tocar para quitar foto' : 'Tocar para elegir foto',
                    style: TextStyle(fontSize: 11, color: fotoBase64.isNotEmpty ? Tema.danger : Tema.textMuted),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: us,
                  readOnly: edit,
                  decoration: const InputDecoration(labelText: 'Usuario *', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: pw,
                  obscureText: true,
                  decoration: InputDecoration(labelText: edit ? 'Contrasena (dejar vacio)' : 'Contrasena *', border: const OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                ),
                SizedBox(height: 10),
                TextField(controller: nm, decoration: const InputDecoration(labelText: 'Nombre Completo', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10))),
                SizedBox(height: 10),
                TextField(controller: em, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)), keyboardType: TextInputType.emailAddress),
                SizedBox(height: 10),
                TextField(controller: tl, decoration: const InputDecoration(labelText: 'Telefono', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)), keyboardType: TextInputType.phone),
                SizedBox(height: 10),
                _rolDropdown(rol, (v) => setSt(() => rol = v)),
                SizedBox(height: 14),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Activo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  dense: true,
                  visualDensity: VisualDensity.standard,
                  value: act,
                  activeColor: Tema.primary,
                  onChanged: (v) => setSt(() => act = v),
                ),
                SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: const Icon(Icons.lock_outlined, size: 18),
                    label: Text(edit ? 'Editar Permisos' : 'Configurar Permisos'),
                    style: TextButton.styleFrom(foregroundColor: Tema.primary),
                    onPressed: () async {
                      final updated = await _openPermisosModal(ctx, 'Usuario', us.text.isNotEmpty ? us.text : 'Nuevo', permisoIdsList, true);
                      if (updated != null) {
                        setSt(() => permisoIdsList = updated);
                      }
                    },
                  ),
                ),
              ]),
            )),
            actionsPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Tema.textMuted),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Tema.radiusSm),
                        ),
                      ),
                      child: Text('Cancelar', style: TextStyle(color: Tema.textDark, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Tema.primary,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Tema.radiusSm),
                        ),
                      ),
                      child: const Text('Guardar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
    if (ok != true || us.text.isEmpty || (!edit && pw.text.isEmpty)) return;
    final data = <String, dynamic>{
      'username': us.text.trim(),
      'nombre_completo': nm.text.trim(),
      'email': em.text.trim(),
      'telefono': tl.text.trim(),
      'foto': fotoBase64.isNotEmpty ? fotoBase64 : ft.text,
      'rol': rol,
      'activo': act,
      'permiso_ids': permisoIdsList,
      'permisos': permisoIdsList,
    };
    if (pw.text.trim().isNotEmpty) data['password'] = pw.text.trim();
    if (edit) {
      final i = _usuarios.indexWhere((x) => x['id'].toString() == u['id'].toString());
      if (i >= 0) {
        data['id'] = u['id'];
        _usuarios[i] = data;
      }
    } else {
      data['id'] = _nextId(_usuarios);
      data['fecha_creacion'] = DateTime.now().toIso8601String();
      _usuarios.add(data);
    }
    await Fb.setList('usuarios', _usuarios);
  }

  Future<void> _deleteUser(Map<dynamic, dynamic> u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        title: const Text('Eliminar Usuario'),
        content: Text('Eliminar a ${u['username'] ?? 'este usuario'}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Tema.danger, foregroundColor: Colors.white),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    _usuarios.removeWhere((x) => x['id'].toString() == u['id'].toString());
    await Fb.setList('usuarios', _usuarios);
  }

  Future<void> _editUserPermisos(Map u) async {
    final actuales = _permisosDe(u);
    final updated = await _openPermisosModal(context, 'Usuario', u['username']?.toString() ?? '', actuales, true);
    if (updated != null) {
      final i = _usuarios.indexWhere((x) => x['id'].toString() == u['id'].toString());
      if (i >= 0) {
        _usuarios[i]['permiso_ids'] = updated;
        _usuarios[i]['permisos'] = updated;
        await Fb.setList('usuarios', _usuarios);
        setState(() {});
      }
    }
  }

  // ── Permisos modal ──

  Future<List<dynamic>?> _openPermisosModal(
    BuildContext ctx, String tipo, String nombre,
    List<dynamic> actuales, bool esUsuario,
  ) async {
    final List<dynamic> allPerms = await Fb.getList('permisos');
    final Map<String, List<Map<dynamic, dynamic>>> groups = {};
    for (final p in allPerms) {
      if (p is Map) {
        final mod = (p['modulo'] ?? 'General').toString();
        groups[mod] = groups[mod] ?? [];
        groups[mod]!.add(p);
      }
    }
    
    final List<dynamic> activeIds = List<dynamic>.from(actuales);
    
    if (!ctx.mounted) return null;
    final result = await showDialog<List<dynamic>?>(
      context: ctx,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setSt) {
          return AlertDialog(
            insetPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 24),
            title: Text('Permisos de $tipo: $nombre', style: TextStyle(fontWeight: FontWeight.w700, color: Tema.textDark, fontSize: 16)),
            content: SizedBox(
              width: double.maxFinite,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(dialogCtx).size.height * 0.7),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: groups.keys.map((mod) {
                      final items = groups[mod]!;
                      final countInMod = items.where((p) => activeIds.any((id) => id.toString() == p['id'].toString())).length;
                      
                      return Card(
                        margin: EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tema.radius), side: BorderSide(color: Tema.cardBorder)),
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.folder_outlined,
                                    size: 18,
                                    color: countInMod > 0 ? Tema.primary : Tema.textMuted,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      mod,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: countInMod > 0 ? Tema.textDark : Tema.textSoft,
                                      ),
                                    ),
                                  ),
                                  if (countInMod > 0)
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Tema.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text('$countInMod/${items.length}',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Tema.primary)),
                                    ),
                                  SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      final allOn = items.every((p) => activeIds.any((id) => id.toString() == p['id'].toString()));
                                      for (final p in items) {
                                        final pid = p['id'];
                                        if (allOn) {
                                          activeIds.removeWhere((id) => id.toString() == pid.toString());
                                        } else {
                                          if (!activeIds.any((id) => id.toString() == pid.toString())) {
                                            activeIds.add(pid);
                                          }
                                        }
                                      }
                                      setSt(() {});
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Tema.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        items.every((p) => activeIds.any((id) => id.toString() == p['id'].toString())) ? 'Nada' : 'Todo',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Tema.primary),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: items.map((p) {
                                  final pid = p['id'];
                                  final isChecked = activeIds.any((id) => id.toString() == pid.toString());
                                  return FilterChip(
                                    label: Text(p['nombre']?.toString() ?? p['permiso']?.toString() ?? ''),
                                    selected: isChecked,
                                    onSelected: (selected) {
                                      if (selected) {
                                        if (!activeIds.any((id) => id.toString() == pid.toString())) {
                                          activeIds.add(pid);
                                        }
                                      } else {
                                        activeIds.removeWhere((id) => id.toString() == pid.toString());
                                      }
                                      setSt(() {});
                                    },
                                    backgroundColor: Colors.transparent,
                                    selectedColor: Tema.primary.withValues(alpha: 0.15),
                                    checkmarkColor: Tema.primary,
                                    labelStyle: TextStyle(
                                      fontSize: 12,
                                      color: isChecked ? Tema.primary : Tema.textSoft,
                                      fontWeight: isChecked ? FontWeight.w600 : FontWeight.normal
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(color: isChecked ? Tema.primary : Tema.cardBorder),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, null),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogCtx, activeIds),
                style: ElevatedButton.styleFrom(backgroundColor: Tema.primary, foregroundColor: Colors.white),
                child: const Text('Aceptar'),
              ),
            ],
          );
        },
      ),
    );
    return result;
  }

  // ── Rol dropdown ──

  Widget _rolDropdown(String current, ValueChanged<String> onChanged) {
    final options = <String>[];
    for (final r in _roles) {
      final n = r['nombre']?.toString() ?? '';
      if (n.isNotEmpty && !options.contains(n)) options.add(n);
    }
    if (current.isNotEmpty && !options.contains(current)) options.add(current);
    if (!options.contains('Admin')) options.add('Admin');
    if (!options.contains('Cajero')) options.add('Cajero');
    if (!options.contains('Supervisor')) options.add('Supervisor');
    if (!options.contains('Vendedor')) options.add('Vendedor');
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: current),
      optionsBuilder: (v) {
        if (v.text.isEmpty) return options;
        return options.where((o) => o.toLowerCase().contains(v.text.toLowerCase()));
      },
      fieldViewBuilder: (ctx, ctl, node, _) => TextField(
        controller: ctl,
        focusNode: node,
        decoration: const InputDecoration(labelText: 'Rol *', border: OutlineInputBorder()),
      ),
      onSelected: onChanged,
    );
  }

  // ── Roles CRUD ──

  Future<void> _addRole() async {
    final nameC = TextEditingController();
    final descC = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        title: Text('Nuevo Rol', style: TextStyle(fontWeight: FontWeight.w700, color: Tema.textDark)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Nombre *', border: OutlineInputBorder())),
          SizedBox(height: 10),
          TextField(controller: descC, decoration: const InputDecoration(labelText: 'Descripcion', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)), maxLines: 2),
        ]))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Tema.primary, foregroundColor: Colors.white),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
    if (ok != true || nameC.text.isEmpty) return;
    _roles.add({'id': _nextId(_roles), 'nombre': nameC.text.trim(), 'descripcion': descC.text.trim(), 'permiso_ids': [], 'permisos': []});
    await Fb.setList('roles', _roles);
    setState(() {});
  }

  Future<void> _editRolePermisos(Map<dynamic, dynamic> r) async {
    final actuales = _permisosDe(r);
    final updated = await _openPermisosModal(context, 'Rol', r['nombre']?.toString() ?? '', actuales, false);
    if (updated != null) {
      r['permiso_ids'] = updated;
      r['permisos'] = updated;
      final i = _roles.indexWhere((x) => x['id'].toString() == r['id'].toString());
      if (i >= 0) _roles[i] = r;
      await Fb.setList('roles', _roles);
      setState(() {});
    }
  }

  Future<void> _deleteRole(Map<dynamic, dynamic> r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        title: const Text('Eliminar Rol'),
        content: Text('Eliminar el rol "${r['nombre'] ?? ''}"? Los usuarios con este rol no se eliminaran.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Tema.danger, foregroundColor: Colors.white),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    _roles.removeWhere((x) => x['id'].toString() == r['id'].toString());
    await Fb.setList('roles', _roles);
    setState(() {});
  }

  // ── Build ──

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      backgroundColor: Tema.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Usuarios y Roles'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(Tema.radiusSm),
            ),
            child: TabBar(
              controller: _tc,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(Tema.radiusSm),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Tema.primary,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.9),
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Usuarios'),
                Tab(text: 'Roles'),
                Tab(text: 'Acciones'),
              ],
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Tema.primary))
          : TabBarView(controller: _tc, children: [_usuariosTab(), _rolesTab(), _accionesTab()]),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tc.index == 0) { _openUser(null); }
          else if (_tc.index == 1) { _addRole(); }
        },
        backgroundColor: Tema.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ── Tab: Usuarios ──

  Widget _usuariosTab() {
    if (_usuarios.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.people_outline, size: 64, color: Tema.textMuted.withValues(alpha: 0.5)),
          SizedBox(height: 12),
          Text('No hay usuarios registrados', style: TextStyle(color: Tema.textMuted, fontSize: 15)),
        ]),
      );
    }
    return ListView.builder(
        padding: EdgeInsets.fromLTRB(10, 8, 10, 80),
        itemCount: _usuarios.length,
        itemBuilder: (_, i) {
          final u = _usuarios[i];
          return _userCard(u);
        },
      );
  }

  Widget _userCard(Map<dynamic, dynamic> u) {
    final activo = u['activo'] != false;
    final username = u['username']?.toString() ?? '';
    final nombre = u['nombre_completo']?.toString() ?? u['nombre']?.toString() ?? '';
    final rol = u['rol']?.toString() ?? 'Sin rol';
    final foto = u['foto']?.toString() ?? '';
    final letra = (nombre.isNotEmpty ? nombre : username).isNotEmpty ? (nombre.isNotEmpty ? nombre : username)[0].toUpperCase() : 'U';
    final lastAccess = u['ultimo_acceso']?.toString() ?? u['fecha_creacion']?.toString() ?? '';
    final lastAccessStr = lastAccess.length >= 10 ? lastAccess.substring(0, 10).replaceAll('T', ' ') : lastAccess;

    ImageProvider? photoProvider;
    if (foto.startsWith('data:')) {
      try {
        photoProvider = MemoryImage(base64Decode(foto.split(',')[1]));
      } catch (_) {}
    } else if (foto.startsWith('http')) {
      photoProvider = NetworkImage(foto);
    }

    return Dismissible(
      key: Key('usr_${u['id']}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: Tema.danger.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(Tema.radius),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        await _deleteUser(u);
        return false;
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Tema.cardBg,
          borderRadius: BorderRadius.circular(Tema.radius),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: InkWell(
          onTap: () => _openUser(u),
          borderRadius: BorderRadius.circular(Tema.radius),
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: activo ? Tema.primary.withValues(alpha: 0.12) : Tema.textMuted.withValues(alpha: 0.15),
                      backgroundImage: photoProvider,
                      child: photoProvider == null
                          ? Text(letra, style: TextStyle(color: activo ? Tema.primary : Tema.textMuted, fontWeight: FontWeight.w700, fontSize: 18))
                          : null,
                    ),
                    Positioned(
                      right: 1,
                      bottom: 1,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: activo ? const Color(0xFF4CAF50) : Tema.textMuted,
                          border: Border.all(color: Tema.cardBg, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre.isNotEmpty ? nombre : username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w700, color: Tema.textDark, fontSize: 15),
                      ),
                      SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            '@$username',
                            style: TextStyle(fontSize: 12, color: Tema.textSoft),
                          ),
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Tema.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(rol, style: const TextStyle(color: Tema.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      if (lastAccessStr.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded, size: 12, color: Tema.textMuted.withValues(alpha: 0.7)),
                            SizedBox(width: 4),
                            Text(lastAccessStr, style: TextStyle(fontSize: 10, color: Tema.textMuted)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.lock_outline, color: Tema.primary, size: 20),
                  onPressed: () => _editUserPermisos(u),
                  tooltip: 'Permisos',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Tab: Roles ──

  Widget _rolesTab() {
    if (_roles.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.admin_panel_settings_outlined, size: 64, color: Tema.textMuted.withValues(alpha: 0.5)),
          SizedBox(height: 12),
          Text('No hay roles definidos', style: TextStyle(color: Tema.textMuted, fontSize: 15)),
        ]),
      );
    }
    return ListView.builder(
        padding: EdgeInsets.fromLTRB(10, 8, 10, 80),
        itemCount: _roles.length,
        itemBuilder: (_, i) {
          final r = _roles[i];
          final count = _roleUserCount(r['nombre']?.toString() ?? '');
          return Container(
            margin: EdgeInsets.only(bottom: 6),
            decoration: Tema.cardDeco,
            child: ListTile(
              onTap: () => _editRolePermisos(r),
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              leading: CircleAvatar(
                backgroundColor: Tema.primary.withValues(alpha: 0.1),
                child: Icon(Icons.lock_outline, color: Tema.primary, size: 20),
              ),
              title: Text(r['nombre']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, color: Tema.textDark)),
              subtitle: Text(
                '${r['descripcion']?.toString() ?? 'Sin descripcion'}  \u2014  $count usuario${count != 1 ? 's' : ''}',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Tema.textSoft, fontSize: 12),
              ),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(icon: Icon(Icons.lock_outline, color: Tema.primary, size: 20), onPressed: () => _editRolePermisos(r), tooltip: 'Permisos'),
                IconButton(icon: Icon(Icons.delete_outline, color: Tema.danger, size: 20), onPressed: () => _deleteRole(r), tooltip: 'Eliminar'),
              ]),
            ),
          );
        },
      );
  }

  // ── Tab: Acciones ──

  Widget _accionesTab() {
    final filtradas = _fAccTxt.isEmpty
        ? _acciones
        : _acciones.where((a) => (a['usuario'] ?? a['usuario_nombre'] ?? '').toString().toLowerCase().contains(_fAccTxt.toLowerCase())).toList();

    return Column(children: [
      Padding(
        padding: EdgeInsets.fromLTRB(10, 8, 10, 4),
        child: SearchInput(
          controller: _fAcc,
          hintText: 'Filtrar por usuario...',
          onChanged: (v) => setState(() => _fAccTxt = v),
        ),
      ),
      Expanded(
        child: filtradas.isEmpty
            ? Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.history, size: 48, color: Tema.textMuted.withValues(alpha: 0.5)),
                  SizedBox(height: 8),
                  Text(_acciones.isEmpty ? 'Sin acciones registradas' : 'Sin resultados',
                      style: TextStyle(color: Tema.textMuted)),
                ]),
              )
            : ListView.builder(
                padding: EdgeInsets.fromLTRB(10, 4, 10, 16),
                itemCount: filtradas.length,
                itemBuilder: (_, i) {
                  final a = filtradas[i];
                  final ts = a['timestamp']?.toString() ?? '';
                  final fecha = ts.length >= 16 ? ts.substring(0, 16).replaceAll('T', ' ') : ts;
                  return Container(
                    margin: EdgeInsets.only(bottom: 4),
                    decoration: Tema.cardDeco,
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: Tema.primary.withValues(alpha: 0.1),
                        child: Icon(Icons.history, color: Tema.primary, size: 16),
                      ),
                      title: Text(a['accion']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Tema.textDark)),
                      subtitle: Text(
                        '${a['usuario'] ?? a['usuario_nombre'] ?? '-'}  \u2014  $fecha',
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Tema.textSoft, fontSize: 11),
                      ),
                      trailing: a['detalle'] != null
                          ? Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Tema.textMuted.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(a['detalle'].toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Tema.textMuted)),
                            )
                          : null,
                    ),
                  );
                },
              ),
      ),
    ]);
  }
}

