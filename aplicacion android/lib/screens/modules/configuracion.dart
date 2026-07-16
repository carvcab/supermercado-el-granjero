import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/firestore_service.dart';
import '../../theme.dart';
import '../../main.dart';

class ConScreen extends StatefulWidget {
  const ConScreen({super.key});
  @override
  State<ConScreen> createState() => _ConScreenState();
}

class _ConScreenState extends State<ConScreen> {
  final _nombreCtrl = TextEditingController();
  bool _alertaStock = false;
  final _stockMinCtrl = TextEditingController();
  final _limiteDescCtrl = TextEditingController();
  final _diasProvCtrl = TextEditingController();

  bool _syncAuto = false;
  bool _conectado = false;

  bool _temaOscuro = false;
  bool _sonido = true;
  StreamSubscription? _sub;

  static const _docs = [
    'productos', 'ventas', 'clientes', 'proveedores',
    'cajas', 'compras', 'usuarios', 'categorias',
    'fiados', 'cierres', 'distribuciones', 'configuracion',
  ];

  @override
  void initState() {
    super.initState();
    _sub = Fb.stream('configuracion').listen((config) {
      if (config.isNotEmpty) {
        final c = config.first;
        _nombreCtrl.text = c['nombreNegocio'] ?? '';
        _alertaStock = c['alertaStock'] ?? false;
        _stockMinCtrl.text = (c['stockMinimo'] ?? 5).toString();
        _limiteDescCtrl.text = (c['limiteDescuento'] ?? 20).toString();
        _diasProvCtrl.text = (c['diasRecordatorio'] ?? 7).toString();
        _syncAuto = c['sincronizacionAuto'] ?? false;
        _temaOscuro = c['temaOscuro'] ?? false;
        _sonido = c['sonido'] ?? true;
      } else {
        _stockMinCtrl.text = '5';
        _limiteDescCtrl.text = '20';
        _diasProvCtrl.text = '7';
      }
      _checkConnectividad();
      setState(() {});
    });
    _cargarTemaOscuro();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _nombreCtrl.dispose();
    _stockMinCtrl.dispose();
    _limiteDescCtrl.dispose();
    _diasProvCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkConnectividad() async {
    try {
      await FirebaseFirestore.instance
          .collection('datos')
          .doc('productos')
          .get(const GetOptions(source: Source.server));
      _conectado = true;
    } catch (_) {
      _conectado = false;
    }
  }

  Future<void> _cargarTemaOscuro() async {
    final prefs = await SharedPreferences.getInstance();
    final dark = prefs.getBool('darkMode') ?? false;
    App.darkMode.value = dark;
    if (mounted) setState(() => _temaOscuro = dark);
  }

  Map<dynamic, dynamic> get _config => {
    'nombreNegocio': _nombreCtrl.text,
    'alertaStock': _alertaStock,
    'stockMinimo': int.tryParse(_stockMinCtrl.text) ?? 5,
    'limiteDescuento': double.tryParse(_limiteDescCtrl.text) ?? 20,
    'diasRecordatorio': int.tryParse(_diasProvCtrl.text) ?? 7,
    'sincronizacionAuto': _syncAuto,
    'temaOscuro': _temaOscuro,
    'sonido': _sonido,
  };

  Future<void> _saveConfig() async {
    await Fb.setList('configuracion', [_config]);
  }

  void _snack(String msg, Color bg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: bg));
  }

  Future<void> _syncAhora() async {
    await _saveConfig();
    await _checkConnectividad();
    setState(() {});
    _snack(
      _conectado ? 'Sincronizacion completada' : 'Sin conexion',
      _conectado ? Tema.primary : Tema.danger,
    );
  }

  // --- Exportar --------------------------------------------------------

  Future<void> _exportar() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Tema.primary)),
    );
    try {
      final data = <String, dynamic>{};
      for (final doc in _docs) {
        final snap = await FirebaseFirestore.instance.collection('datos').doc(doc).get();
        if (snap.exists && snap.data() != null) {
          data[doc] = snap.data()!['lista'];
        }
      }
      final json = const JsonEncoder.withIndent('  ').convert(data);
      if (!mounted) return;
      Navigator.pop(context);
      _showJsonDialog(json, false);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _snack('Error al exportar: $e', Tema.danger);
    }
  }

  // --- Importar --------------------------------------------------------

  Future<void> _importar() async {
    _showJsonDialog('', true);
  }

  void _showJsonDialog(String json, bool isImport) {
    final ctrl = TextEditingController(text: json);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isImport ? 'Importar Datos' : 'Exportar Datos',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 420,
          child: TextField(
            controller: ctrl,
            maxLines: null,
            expands: true,
            readOnly: !isImport,
            textAlignVertical: TextAlignVertical.top,
            style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText: isImport ? 'Pega el JSON aqui...' : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(Tema.radiusSm)),
            ),
          ),
        ),
        actions: [
          if (!isImport)
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: ctrl.text));
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('JSON copiado al portapapeles')),
                );
              },
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copiar'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
          if (isImport)
            ElevatedButton(
              onPressed: () async {
                try {
                  final parsed = jsonDecode(ctrl.text) as Map<String, dynamic>;
                  final batch = FirebaseFirestore.instance.batch();
                  for (final entry in parsed.entries) {
                    batch.set(
                      FirebaseFirestore.instance.collection('datos').doc(entry.key),
                      {'lista': entry.value},
                    );
                  }
                  await batch.commit();
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  _snack('Datos importados correctamente', Tema.primary);
                } catch (e) {
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Tema.danger),
                  );
                }
              },
              child: const Text('Importar'),
            ),
        ],
      ),
    );
  }

  // --- Limpiar ---------------------------------------------------------

  Future<void> _limpiar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpiar todos los datos?'),
        content: const Text(
          'Esta accion eliminara toda la informacion del negocio. No se puede deshacer.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Tema.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar todo'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in _docs) {
        batch.set(
          FirebaseFirestore.instance.collection('datos').doc(doc),
          {'lista': []},
        );
      }
      await batch.commit();
      _nombreCtrl.clear();
      setState(() {
        _alertaStock = false;
        _syncAuto = false;
        _temaOscuro = false;
        _sonido = true;
      });
      _stockMinCtrl.text = '5';
      _limiteDescCtrl.text = '20';
      _diasProvCtrl.text = '7';
      await _saveConfig();
      _snack('Todos los datos han sido eliminados', Tema.primary);
    }
  }

  // --- Semilla ---------------------------------------------------------

  Future<void> _restablecerSemilla() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restablecer semilla?'),
        content: const Text(
          'Se vaciaran los productos. Los productos actuales seran eliminados.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restablecer'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await Fb.setList('productos', []);
      _snack('Productos vaciados', Tema.primary);
    }
  }

  // --- Backup ----------------------------------------------------------

  Future<void> _subirBackup() async {
    try {
      final data = <String, dynamic>{};
      for (final doc in _docs) {
        final snap = await FirebaseFirestore.instance.collection('datos').doc(doc).get();
        if (snap.exists && snap.data() != null) {
          data[doc] = snap.data()!['lista'];
        }
      }
      data['fecha'] = DateTime.now().toIso8601String();
      await FirebaseFirestore.instance.collection('datos').doc('backup').set(data);
      _snack('Backup subido a la nube', Tema.primary);
    } catch (e) {
      _snack('Error: $e', Tema.danger);
    }
  }

  Future<void> _bajarBackup() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurar backup?'),
        content: const Text(
          'Se restauraran los datos desde el backup en la nube. Los datos actuales seran reemplazados.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        final snap = await FirebaseFirestore.instance.collection('datos').doc('backup').get();
        if (!snap.exists) {
          _snack('No hay backup disponible', Tema.danger);
          return;
        }
        final data = Map<String, dynamic>.from(snap.data()!);
        data.remove('fecha');
        final batch = FirebaseFirestore.instance.batch();
        for (final entry in data.entries) {
          batch.set(
            FirebaseFirestore.instance.collection('datos').doc(entry.key),
            {'lista': entry.value},
          );
        }
        await batch.commit();
        _snack('Backup restaurado', Tema.primary);
      } catch (e) {
        _snack('Error: $e', Tema.danger);
      }
    }
  }

  // --- UI --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(12),
      children: [
        _section('General', [
          _textTile(Icons.store_outlined, 'Nombre del negocio', _nombreCtrl, hint: 'Ej: Supermercado El Granjero'),
          _switchTile(
            Icons.warning_amber_outlined,
            'Alerta Stock Bajo',
            'Activar alerta cuando el stock sea bajo',
            _alertaStock,
            (v) {
              _alertaStock = v;
              setState(() {});
              _saveConfig();
            },
          ),
          _textTile(Icons.inventory_2_outlined, 'Stock minimo', _stockMinCtrl, hint: '5', number: true),
          _textTile(Icons.percent_outlined, 'Limite Descuento (%)', _limiteDescCtrl, hint: '20', number: true),
          _textTile(
            Icons.calendar_today_outlined,
            'Dias Recordatorio Proveedores',
            _diasProvCtrl,
            hint: '7',
            number: true,
          ),
        ]),
        _section('Sincronizacion', [
          _statusTile(),
          _buttonTile('Sincronizar Ahora', Icons.sync, _syncAhora),
          _switchTile(
            Icons.sync_outlined,
            'Sincronizacion Automatica',
            'Sincronizar datos periodicamente',
            _syncAuto,
            (v) {
              _syncAuto = v;
              setState(() {});
              _saveConfig();
            },
          ),
        ]),
        _section('Datos', [
          _buttonTile('Exportar Datos (JSON)', Icons.upload_file, _exportar),
          _buttonTile('Importar Datos (JSON)', Icons.download, _importar),
          _buttonTile('Limpiar Datos', Icons.delete_sweep_outlined, _limpiar, danger: true),
          _buttonTile('Restablecer Semilla', Icons.grass_outlined, _restablecerSemilla),
          _buttonTile('Bajar Backup', Icons.cloud_download_outlined, _bajarBackup),
          _buttonTile('Subir Backup', Icons.cloud_upload_outlined, _subirBackup),
        ]),
        _section('Apariencia', [
          _switchTile(
            Icons.dark_mode_outlined,
            'Tema oscuro',
            'Activar modo oscuro',
            _temaOscuro,
            (v) {
              _temaOscuro = v;
              App.darkMode.value = v;
              setState(() {});
              _saveConfig();
              SharedPreferences.getInstance().then((p) => p.setBool('darkMode', v));
            },
          ),
          _switchTile(
            Icons.volume_up_outlined,
            'Sonido',
            'Sonido al registrar venta',
            _sonido,
            (v) {
              _sonido = v;
              setState(() {});
              _saveConfig();
            },
          ),
        ]),
      ],
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: Tema.cardDeco,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Tema.primary, letterSpacing: 0.5),
              ),
            ),
            ...children,
            SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Widget _switchTile(IconData icon, String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      dense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 12),
      secondary: Icon(icon, color: Tema.textSoft, size: 22),
      title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Tema.textDark)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Tema.textMuted)),
      value: value,
      onChanged: onChanged,
      activeColor: Tema.primary,
    );
  }

  Widget _textTile(IconData icon, String label, TextEditingController ctrl,
      {String hint = '', bool number = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Tema.textSoft, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: ctrl,
              keyboardType: number ? TextInputType.number : TextInputType.text,
              onChanged: (_) => _saveConfig(),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Tema.textDark),
              decoration: InputDecoration(
                labelText: label,
                hintText: hint,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                labelStyle: TextStyle(fontSize: 12, color: Tema.textSoft),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buttonTile(String label, IconData icon, VoidCallback onTap, {bool danger = false}) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 12),
      leading: Icon(icon, color: danger ? Tema.danger : Tema.primary, size: 22),
      title: Text(
        label,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: danger ? Tema.danger : Tema.textDark),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tema.radiusSm)),
    );
  }

  Widget _statusTile() {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 12),
      leading: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _conectado ? Tema.primary : Tema.danger,
        ),
      ),
      title: Text(
        _conectado ? 'Conectado' : 'Desconectado',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _conectado ? Tema.primary : Tema.danger),
      ),
      subtitle: Text(
        _conectado ? 'Firestore en linea' : 'Sin conexion al servidor',
        style: TextStyle(fontSize: 12, color: Tema.textMuted),
      ),
    );
  }
}


