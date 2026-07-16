import 'dart:async';

import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../theme.dart';

class DisScreen extends StatefulWidget {
  const DisScreen({super.key});
  @override
  State<DisScreen> createState() => _DisScreenState();
}

class _DisScreenState extends State<DisScreen> {
  List<Map<dynamic, dynamic>> _distribuciones = [];
  List<Map<dynamic, dynamic>> _categorias = [];
  Map<dynamic, dynamic> _configCaja = {};
  final Map<String, double> _montos = {};
  bool _loading = true;
  final _catCtrl = TextEditingController();
  final _editCatCtrl = TextEditingController();
  StreamSubscription? _subDist;
  StreamSubscription? _subConfig;

  @override
  void initState() {
    super.initState();
    _subDist = Fb.stream('distribuciones').listen((d) => setState(() {
      _distribuciones = d;
      _loading = false;
    }));
    // Listen to config_caja_negocio for balance & ganancias (same as PC)
    _subConfig = Fb.streamDoc('config_caja_negocio').listen((cfg) {
      setState(() => _configCaja = cfg);
    });
    _loadCategorias();
  }

  @override
  void dispose() {
    _subDist?.cancel();
    _subConfig?.cancel();
    _catCtrl.dispose();
    _editCatCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategorias() async {
    _categorias = await Fb.getList('distribuciones_categorias');
    for (var c in _categorias) {
      final n = (c['nombre'] ?? '').toString();
      _montos.putIfAbsent(n, () => 0);
    }
    if (mounted) setState(() {});
  }

  double _num(dynamic v) => (v is num ? v : 0).toDouble();

  // --- Balance from config_caja_negocio (same as PC) ---
  double get _cajaNegocioBalance => _num(_configCaja['balance']);
  double get _gananciasAcumuladas => _num(_configCaja['ganancias_acumuladas']);

  double get _totalDistribuido =>
      _distribuciones.fold(0.0, (s, e) => s + _num(e['total']));

  Map<String, double> get _acumuladoPorCategoria {
    final map = <String, double>{};
    for (final d in _distribuciones) {
      // PC uses 'items', Flutter uses 'categorias' — support both
      final cats = (d['items'] as List?) ?? (d['categorias'] as List?) ?? [];
      for (final c in cats) {
        final nombre = (c['categoria_nombre'] ?? c['nombre'] ?? '').toString();
        final monto = _num(c['monto']);
        if (nombre.isNotEmpty) {
          map[nombre] = (map[nombre] ?? 0) + monto;
        }
      }
    }
    return map;
  }

  double get _totalAsignado =>
      _montos.values.fold(0.0, (a, b) => a + b);

  double get _restante => _gananciasAcumuladas - _totalAsignado;

  // --- Categorias CRUD ---

  Future<void> _addCategoria() async {
    final nombre = _catCtrl.text.trim();
    if (nombre.isEmpty) {
      _showMsg('Ingrese un nombre');
      return;
    }
    final existe = _categorias.any(
      (c) => (c['nombre'] ?? '').toString().toLowerCase() == nombre.toLowerCase(),
    );
    if (existe) {
      _showMsg('La categoria ya existe');
      return;
    }
    final id = _categorias.isEmpty
        ? 1
        : (_categorias.map((x) => (x['id'] as num?)?.toInt() ?? 0).reduce((a, b) => a > b ? a : b)) + 1;
    _categorias.add({'id': id, 'nombre': nombre});
    _montos[nombre] = 0;
    _catCtrl.clear();
    await Fb.setList('distribuciones_categorias', _categorias);
    setState(() {});
    _showMsg('Categoria agregada');
  }

  Future<void> _editCategoria(Map<dynamic, dynamic> cat) async {
    _editCatCtrl.text = (cat['nombre'] ?? '').toString();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar Categoria'),
        content: TextField(
          controller: _editCatCtrl,
          decoration: const InputDecoration(labelText: 'Nombre'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Guardar')),
        ],
      ),
    );
    if (ok != true || _editCatCtrl.text.trim().isEmpty) return;
    final oldNombre = (cat['nombre'] ?? '').toString();
    final newNombre = _editCatCtrl.text.trim();
    final idx = _categorias.indexOf(cat);
    _categorias[idx]['nombre'] = newNombre;
    if (oldNombre != newNombre) {
      _montos[newNombre] = _montos[oldNombre] ?? 0;
      _montos.remove(oldNombre);
    }
    await Fb.setList('distribuciones_categorias', _categorias);
    setState(() {});
    _showMsg('Categoria actualizada');
  }

  Future<void> _deleteCategoria(Map<dynamic, dynamic> cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar categoria'),
        content: Text('Eliminar "${cat['nombre']}"? No afecta distribuciones previas.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Tema.danger),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final nombre = (cat['nombre'] ?? '').toString();
    _categorias.remove(cat);
    _montos.remove(nombre);
    await Fb.setList('distribuciones_categorias', _categorias);
    setState(() {});
    _showMsg('Categoria eliminada');
  }

  // --- Distribuir (same logic as PC) ---

  Future<void> _realizarDistribucion() async {
    if (_gananciasAcumuladas <= 0) {
      _showMsg('No hay ganancias disponibles para distribuir');
      return;
    }
    if (_totalAsignado <= 0) {
      _showMsg('Asigne montos a al menos una categoria');
      return;
    }
    if (_totalAsignado > _gananciasAcumuladas + 0.5) {
      _showMsg('Total excede ganancias disponibles (${_fmtF(_gananciasAcumuladas)})');
      return;
    }

    final items = <Map<String, dynamic>>[];
    double totalMonto = 0;
    for (var entry in _montos.entries) {
      if (entry.value <= 0) continue;
      final cat = _categorias.cast<Map<dynamic, dynamic>>().firstWhere(
        (c) => (c['nombre'] ?? '').toString() == entry.key,
        orElse: () => <dynamic, dynamic>{},
      );
      items.add({
        'categoria_id': cat['id'],
        'categoria_nombre': entry.key,
        'nombre': entry.key,
        'monto': entry.value,
      });
      totalMonto += entry.value;
    }

    if (items.isEmpty) {
      _showMsg('Asigne montos a al menos una categoria');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirmar distribucion'),
        content: Text(
          'Distribuir ${_fmtF(totalMonto)} en ${items.length} categoria(s)?\n\n'
          '${items.map((i) => '${i['nombre']}: ${_fmtF(i['monto'])}').join('\n')}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Confirmar')),
        ],
      ),
    );
    if (confirm != true) return;

    final nueva = <String, dynamic>{
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'tipo': 'distribucion',
      'fecha': DateTime.now().toIso8601String().substring(0, 10),
      'total': totalMonto,
      'items': items,
      'categorias': items,
      'created_at': DateTime.now().toIso8601String(),
    };

    _distribuciones.insert(0, Map<dynamic, dynamic>.from(nueva));
    await Fb.setList('distribuciones', _distribuciones);

    // Update config_caja_negocio: subtract ganancias (same as PC)
    final cfg = await Fb.getDoc('config_caja_negocio');
    cfg['ganancias_acumuladas'] = (_num(cfg['ganancias_acumuladas']) - totalMonto).clamp(0, double.infinity);
    cfg['updated_at'] = DateTime.now().toIso8601String();
    await Fb.setDoc('config_caja_negocio', cfg);

    for (var k in _montos.keys.toList()) {
      _montos[k] = 0;
    }

    setState(() {});
    _showMsg('Distribucion realizada por ${_fmtF(totalMonto)}');
  }

  // --- Delete distribution (return money to ganancias) ---

  Future<void> _deleteDistribucion(int idx) async {
    final d = _distribuciones[idx];
    final total = _num(d['total']);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar distribucion'),
        content: Text('Eliminar esta distribucion de ${_fmtF(total)}?\n\nEl monto sera devuelto a ganancias acumuladas.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Tema.danger),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    _distribuciones.removeAt(idx);
    await Fb.setList('distribuciones', _distribuciones);

    // Return money to ganancias_acumuladas (same as PC)
    if (total > 0) {
      final cfg = await Fb.getDoc('config_caja_negocio');
      cfg['ganancias_acumuladas'] = _num(cfg['ganancias_acumuladas']) + total;
      cfg['updated_at'] = DateTime.now().toIso8601String();
      await Fb.setDoc('config_caja_negocio', cfg);
    }

    setState(() {});
    _showMsg('Distribucion eliminada. ${_fmtF(total)} devueltos a ganancias.');
  }

  // --- Edit distribution items (with recalc) ---

  Future<void> _editDistribucionItems(int idx) async {
    final d = _distribuciones[idx];
    final rawItems = (d['items'] as List?) ?? (d['categorias'] as List?) ?? [];
    final items = List<Map<dynamic, dynamic>>.from(
      rawItems.map((e) => Map<dynamic, dynamic>.from(e as Map)),
    );
    final oldTotal = _num(d['total']);

    final result = await showDialog<List<Map<dynamic, dynamic>>>(
      context: context,
      builder: (ctx) => _EditItemsDialog(items: items),
    );
    if (result == null) return;

    double newTotal = result.fold(0.0, (s, e) => s + _num(e['monto']));
    _distribuciones[idx]['items'] = result;
    _distribuciones[idx]['categorias'] = result;
    _distribuciones[idx]['total'] = newTotal;
    await Fb.setList('distribuciones', _distribuciones);

    // Recalculate: difference between old and new total
    final diferencia = newTotal - oldTotal;
    if (diferencia != 0) {
      final cfg = await Fb.getDoc('config_caja_negocio');
      cfg['ganancias_acumuladas'] = (_num(cfg['ganancias_acumuladas']) - diferencia).clamp(0, double.infinity);
      cfg['updated_at'] = DateTime.now().toIso8601String();
      await Fb.setDoc('config_caja_negocio', cfg);
    }

    setState(() {});
    _showMsg('Distribucion actualizada');
  }

  void _showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  String _fmtF(dynamic n) => Fb.formatMoney(n ?? 0);

  void _distribuirEquitativo() {
    if (_categorias.isEmpty || _gananciasAcumuladas <= 0) return;
    final eq = (_gananciasAcumuladas / _categorias.length).roundToDouble();
    for (var c in _categorias) {
      _montos[(c['nombre'] ?? '').toString()] = eq;
    }
    setState(() {});
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: Tema.primary));
    }

    return Scaffold(
      body: ListView(
          padding: EdgeInsets.all(12),
          children: [
            _buildKpiRow(),
            SizedBox(height: 14),
            if (_acumuladoPorCategoria.isNotEmpty) ...[
              _buildResumenCard(),
              SizedBox(height: 14),
            ],
            _buildCategoriasCard(),
            SizedBox(height: 14),
            _buildDistribuirCard(),
            SizedBox(height: 14),
            _buildHistorialCard(),
        ],
      ),
    );
  }

  // --- 3 KPI Cards (matching PC: Caja Negocio, Ganancias Acum., Total Distribuido) ---

  Widget _buildKpiRow() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _kpiCardStyled(
                'Caja Negocio',
                _fmtF(_cajaNegocioBalance),
                Icons.savings_outlined,
                subtitle: 'Capital acumulado',
                accent: Tema.darkBlue,
                bgTint: const Color(0xFFe3ecf3),
                borderColor: Tema.darkBlue,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _kpiCardStyled(
                'Ganancias Acum.',
                _fmtF(_gananciasAcumuladas),
                Icons.trending_up,
                subtitle: 'Utilidad (ventas − costo)',
                accent: const Color(0xFF1a7a2e),
                bgTint: const Color(0xFFe8f5e9),
                borderColor: const Color(0xFF1a7a2e),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _kpiCardStyled(
                'Total Distribuido',
                _fmtF(_totalDistribuido),
                Icons.pie_chart_outline,
                subtitle: 'Repartido a categorias',
                accent: const Color(0xFFe65100),
                bgTint: const Color(0xFFfff3e0),
                borderColor: const Color(0xFFe65100),
              ),
            ),
            SizedBox(width: 10),
            Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _kpiCardStyled(
    String title,
    String value,
    IconData icon, {
    String subtitle = '',
    required Color accent,
    required Color bgTint,
    required Color borderColor,
  }) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgTint,
        borderRadius: BorderRadius.circular(Tema.radius),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: accent),
              SizedBox(width: 4),
              Flexible(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: accent, letterSpacing: 0.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: accent),
          ),
          if (subtitle.isNotEmpty) ...[
            SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 9, color: Color(0xFF616161)),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResumenCard() {
    final acum = _acumuladoPorCategoria;
    final entries = acum.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Container(
      decoration: Tema.cardDeco,
      padding: EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.pie_chart_outline, size: 18, color: Tema.primary),
            SizedBox(width: 8),
            Text('Distribuido por categoria', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Tema.textDark)),
          ]),
          SizedBox(height: 10),
          ...entries.map((e) => Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Expanded(child: Text(e.key, style: TextStyle(fontSize: 13, color: Tema.textSoft))),
              Text(Fb.formatMoney(e.value), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Tema.primary)),
            ]),
          )),
          if (entries.isEmpty) Text('Sin distribuciones', style: TextStyle(fontSize: 12, color: Tema.textMuted)),
        ],
      ),
    );
  }

  Widget _buildCategoriasCard() {
    return Container(
      decoration: Tema.cardDeco,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              gradient: Tema.headerGradient,
            ),
            child: Row(
              children: [
                Icon(Icons.category, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Categorias de Distribucion',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _catCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Nueva categoria...',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (_) => _addCategoria(),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  height: 40,
                  width: 40,
                  child: ElevatedButton(
                    onPressed: _addCategoria,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: Tema.darkBlue,
                    ),
                    child: Icon(Icons.add, size: 20),
                  ),
                ),
              ],
            ),
          ),
          if (_categorias.isEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Center(
                child: Text(
                  'Sin categorias. Agregue categorias para distribuir.',
                  style: TextStyle(color: Tema.textMuted, fontSize: 12),
                ),
              ),
            )
          else
            SizedBox(
              height: 180,
              child: ListView.builder(
                itemCount: _categorias.length,
                itemBuilder: (_, i) {
                  final c = _categorias[i];
                  final nombre = (c['nombre'] ?? '').toString();
                  return Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Tema.cardBorder.withValues(alpha: 0.5)),
                      ),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        backgroundColor: Tema.primary,
                        radius: 16,
                        child: Text(
                          nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                      title: Text(nombre, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Tema.textDark)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _editCategoria(c),
                            icon: Icon(Icons.edit, size: 16, color: Tema.textSoft),
                            visualDensity: VisualDensity.compact,
                          ),
                          IconButton(
                            onPressed: () => _deleteCategoria(c),
                            icon: Icon(Icons.delete_outline, size: 16, color: Tema.danger),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDistribuirCard() {
    final balanceOk = (_totalAsignado - _gananciasAcumuladas).abs() <= 0.5;

    return Container(
      decoration: Tema.cardDeco,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF1a7a2e), Color(0xFF2c5e43)]),
            ),
            child: Row(
              children: [
                Icon(Icons.share, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Distribuir Ganancias',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white),
                  ),
                ),
                Text(
                  'Disponible: ${_fmtF(_gananciasAcumuladas)}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFf9a825)),
                ),
              ],
            ),
          ),
          if (_categorias.isEmpty)
            Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Cree categorias primero para poder distribuir.',
                  style: TextStyle(color: Tema.textMuted, fontSize: 13),
                ),
              ),
            )
          else ...[
            Padding(
              padding: EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  Text(
                    'Asigne montos',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Tema.textSoft),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _distribuirEquitativo,
                    icon: Icon(Icons.balance, size: 14),
                    label: Text('Equitativo', style: TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(
                      foregroundColor: Tema.darkBlue,
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 220,
              child: ListView.builder(
                itemCount: _categorias.length,
                itemBuilder: (_, i) {
                  final c = _categorias[i];
                  final nombre = (c['nombre'] ?? '').toString();
                  final monto = _montos[nombre] ?? 0;

                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: Text(
                            nombre,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Tema.textDark),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: '0',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            controller: TextEditingController(text: monto > 0 ? monto.round().toString() : ''),
                            onChanged: (v) {
                              setState(() => _montos[nombre] = double.tryParse(v) ?? 0);
                            },
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                        SizedBox(width: 8),
                        SizedBox(
                          width: 70,
                          child: Text(
                            _fmtF(monto),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: monto > 0 ? Tema.primary : Tema.textMuted,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: balanceOk && _totalAsignado > 0 ? const Color(0xFFe8f5e9) : const Color(0xFFfce4ec),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      balanceOk && _totalAsignado > 0 ? Icons.check_circle : Icons.warning_amber_rounded,
                      size: 18,
                      color: balanceOk && _totalAsignado > 0 ? const Color(0xFF1a7a2e) : Tema.danger,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Asignado: ${_fmtF(_totalAsignado)} / ${_fmtF(_gananciasAcumuladas)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: balanceOk && _totalAsignado > 0 ? const Color(0xFF1a7a2e) : Tema.danger,
                        ),
                      ),
                    ),
                    if (_restante != 0) ...[
                      Text(
                        _restante > 0 ? 'Falta ${_fmtF(_restante)}' : 'Excede ${_fmtF((-_restante))}',
                        style: TextStyle(fontSize: 11, color: Tema.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(14, 4, 14, 14),
              child: SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _realizarDistribucion,
                  icon: Icon(Icons.check, size: 18),
                  label: Text('Realizar Distribucion'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1a7a2e),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tema.radiusSm)),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistorialCard() {
    final disps = _distribuciones;

    return Container(
      decoration: Tema.cardDeco,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(gradient: Tema.headerGradient),
            child: Row(
              children: [
                Icon(Icons.history, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Historial de Distribuciones',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          if (disps.isEmpty)
            Padding(
              padding: EdgeInsets.all(28),
              child: Center(
                child: Text(
                  'Sin distribuciones registradas',
                  style: TextStyle(color: Tema.textMuted, fontSize: 13),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: disps.length,
              itemBuilder: (_, i) {
                final d = disps[i];
                final fecha = (d['fecha'] ?? '').toString();
                final total = _num(d['total']);
                final rawCats = (d['items'] as List?) ?? (d['categorias'] as List?) ?? [];
                final cats = List<Map<dynamic, dynamic>>.from(
                  rawCats.map((e) => Map<dynamic, dynamic>.from(e as Map)),
                );

                return Dismissible(
                  key: Key(d['id']?.toString() ?? i.toString()),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) async {
                    await _deleteDistribucion(i);
                    return false;
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 20),
                    margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Tema.danger,
                      borderRadius: BorderRadius.circular(Tema.radius),
                    ),
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(Tema.radiusSm),
                      border: Border.all(color: Tema.cardBorder),
                    ),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.symmetric(horizontal: 14),
                      childrenPadding: EdgeInsets.fromLTRB(14, 0, 14, 10),
                      leading: CircleAvatar(
                        backgroundColor: Tema.darkBlue,
                        radius: 18,
                        child: Text(
                          fecha.isNotEmpty ? fecha.substring(fecha.length - 2) : '?',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                      title: Text(
                        fecha,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Tema.textDark),
                      ),
                      subtitle: Text(
                        '${cats.length} categorias - Total: ${_fmtF(total)}',
                        style: TextStyle(fontSize: 11, color: Tema.textSoft),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _editDistribucionItems(i),
                            icon: Icon(Icons.edit, size: 16, color: Tema.textSoft),
                            visualDensity: VisualDensity.compact,
                          ),
                          Icon(Icons.swipe_left, size: 14, color: Tema.textMuted),
                        ],
                      ),
                      children: [
                        for (var item in cats)
                          Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(Icons.circle, size: 6, color: Tema.primary),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    (item['categoria_nombre'] ?? item['nombre'] ?? '').toString(),
                                    style: TextStyle(fontSize: 12, color: Tema.textDark),
                                  ),
                                ),
                                Text(
                                  _fmtF(item['monto'] ?? 0),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Tema.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _EditItemsDialog extends StatefulWidget {
  final List<Map<dynamic, dynamic>> items;
  const _EditItemsDialog({required this.items});

  @override
  State<_EditItemsDialog> createState() => _EditItemsDialogState();
}

class _EditItemsDialogState extends State<_EditItemsDialog> {
  late List<Map<dynamic, dynamic>> _items;
  late List<TextEditingController> _montoCtrls;

  @override
  void initState() {
    super.initState();
    _items = widget.items.map((e) => Map<dynamic, dynamic>.from(e)).toList();
    _montoCtrls = _items.map((e) => TextEditingController(text: '${e['monto'] ?? 0}')).toList();
  }

  @override
  void dispose() {
    for (var c in _montoCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Editar items de distribucion'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _items.length,
          itemBuilder: (_, i) {
            final item = _items[i];
            final nombre = (item['categoria_nombre'] ?? item['nombre'] ?? '').toString();
            return Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(nombre, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _montoCtrls[i],
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        isDense: true,
                        labelText: '\$ Monto',
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar')),
        TextButton(
          onPressed: () {
            for (var i = 0; i < _items.length; i++) {
              _items[i]['monto'] = double.tryParse(_montoCtrls[i].text) ?? 0;
            }
            Navigator.pop(context, _items);
          },
          child: Text('Guardar'),
        ),
      ],
    );
  }
}
