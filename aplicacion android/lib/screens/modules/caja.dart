import 'dart:async';

import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../theme.dart';

class CajaScreen extends StatefulWidget { const CajaScreen({super.key}); @override State<CajaScreen> createState() => _CajaScreenState(); }

class _CajaScreenState extends State<CajaScreen> with SingleTickerProviderStateMixin {
  List<Map<dynamic, dynamic>> _cajas = [];
  Map<dynamic, dynamic>? _cajaAbierta;
  late TabController _tabController;
  bool _loading = true;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _sub = Fb.stream('cajas').listen((d) {
      setState(() {
        _cajas = d;
        _cajaAbierta = d.isNotEmpty && d.last['estado'] == 'abierta' ? d.last : null;
        _loading = false;
      });
    });
  }

  @override
  void dispose() { _sub?.cancel(); _tabController.dispose(); super.dispose(); }

  List<Map<dynamic, dynamic>> _movs(Map<dynamic, dynamic> caja) =>
      List<Map<dynamic, dynamic>>.from(caja['movimientos'] ?? []);

  int _ing(Map<dynamic, dynamic> caja) =>
      _movs(caja).where((m) => m['tipo'] == 'ingreso').fold<int>(0, (s, m) => s + ((m['monto'] as num?)?.toInt() ?? 0));

  int _egr(Map<dynamic, dynamic> caja) =>
      _movs(caja).where((m) => m['tipo'] != 'ingreso').fold<int>(0, (s, m) => s + ((m['monto'] as num?)?.toInt() ?? 0));

  int _totalEsp(Map<dynamic, dynamic> caja) =>
      ((caja['monto_inicial'] as num?)?.toInt() ?? 0) + _ing(caja) - _egr(caja);

  String _fmt(dynamic v) => '\$${(v is num ? v : 0).round()}';

  String _fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final d = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    final h = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$d $h';
  }

  String _tipoTexto(String t) {
    switch (t) {
      case 'ingreso': return 'Ingreso';
      case 'egreso': return 'Egreso';
      case 'gasto': return 'Gasto';
      case 'pago_proveedor': return 'Pago Proveedor';
      default: return t;
    }
  }

  Color _tipoColor(String t) {
    switch (t) {
      case 'ingreso': return Tema.primary;
      case 'egreso': return Tema.danger;
      case 'gasto': return Colors.orange;
      case 'pago_proveedor': return Tema.darkBlue;
      default: return Tema.textSoft;
    }
  }

  IconData _tipoIcono(String t) {
    switch (t) {
      case 'ingreso': return Icons.arrow_downward_rounded;
      case 'egreso': return Icons.arrow_upward_rounded;
      case 'gasto': return Icons.receipt_long_rounded;
      case 'pago_proveedor': return Icons.local_shipping_rounded;
      default: return Icons.swap_horiz_rounded;
    }
  }

  String _metodoTexto(String? m) {
    switch (m) {
      case 'efectivo': return 'Efectivo';
      case 'tarjeta': return 'Tarjeta';
      case 'transferencia': return 'Transferencia';
      case 'otro': return 'Otro';
      default: return m ?? '-';
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));

  // ==================== ABRIR CAJA ====================
  Future<void> _abrirCaja() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        title: const Text('Abrir Caja'),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Monto Inicial', prefixText: '\$ '),
          autofocus: true,
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Abrir Caja')),
        ],

      ),
    );
    if (ok != true) return;
    final monto = int.tryParse(ctrl.text) ?? 0;
    if (monto < 0) { _snack('El monto inicial no puede ser negativo'); return; }
    // Update config_caja_negocio (subtract opening register amount)
    try {
      final cajaN = await Fb.getDoc('config_caja_negocio');
      final currentBalance = ((cajaN['balance'] ?? 0) as num).toInt();
      final currentBalanceAlCierre = ((cajaN['balance_al_cierre'] ?? 0) as num).toInt();
      cajaN['balance'] = (currentBalance - monto).clamp(0, 999999999);
      cajaN['balance_al_cierre'] = (currentBalanceAlCierre - monto).clamp(0, 999999999);
      cajaN['updated_at'] = DateTime.now().toIso8601String();
      await Fb.setDoc('config_caja_negocio', cajaN);
    } catch (e) {
      debugPrint('Error updating config_caja_negocio on opening caja: $e');
    }

    final id = _cajas.isEmpty ? 1 : (_cajas.map((c) => c['id'] as int).reduce((a, b) => a > b ? a : b) + 1);
    _cajas.add({
      'id': id, 'monto_inicial': monto, 'estado': 'abierta',
      'fecha_apertura': DateTime.now().toIso8601String(), 'fecha_cierre': null,
      'ingresos': 0, 'egresos': 0, 'monto_final_real': null,
      'movimientos': <Map<dynamic, dynamic>>[],
    });
    await Fb.setList('cajas', _cajas);
    _snack('Caja abierta exitosamente');
  }

  Future<void> _reabrirCaja() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reabrir Ultima Caja'),
        content: const Text('Se reabrira la ultima caja cerrada para continuar operando.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reabrir Caja')),
        ],
      ),
    );
    if (ok != true) return;
    final cerradas = _cajas.where((c) => c['estado'] == 'cerrada').toList()
      ..sort((a, b) => ((b['fecha_cierre'] ?? '') as String).compareTo((a['fecha_cierre'] ?? '') as String));
    if (cerradas.isEmpty) { _snack('No hay cajas cerradas para reabrir'); return; }
    final ultima = cerradas.first;
    final idx = _cajas.indexWhere((c) => c['id'] == ultima['id']);
    if (idx < 0) return;

    double n(dynamic v) => (v is num ? v : 0).toDouble();

    final mi = n(ultima['monto_inicial']);
    final cp = n(ultima['capital_productos']);
    final dif = n(ultima['diferencia']);
    final gan = n(ultima['ganancias']);

    try {
      final cfg = await Fb.getDoc('config_caja_negocio');
      cfg['balance'] = n(cfg['balance']) - (mi + cp + dif);
      cfg['ganancias_acumuladas'] = n(cfg['ganancias_acumuladas']) - gan;
      if (n(cfg['balance']) < 0) cfg['balance'] = 0.0;
      if (n(cfg['ganancias_acumuladas']) < 0) cfg['ganancias_acumuladas'] = 0.0;
      cfg['updated_at'] = DateTime.now().toIso8601String();
      await Fb.setDoc('config_caja_negocio', cfg);
    } catch (e) {
      _snack('Error al actualizar saldos: $e');
    }

    try {
      final cierres = await Fb.getList('cierres');
      final cIdx = cierres.indexWhere((x) => x['caja_id'] == ultima['id']);
      if (cIdx >= 0) {
        cierres.removeAt(cIdx);
        await Fb.setList('cierres', cierres);
      }
    } catch (_) {}

    _cajas[idx]['estado'] = 'abierta';
    _cajas[idx]['fecha_cierre'] = null;
    _cajas[idx]['monto_final_real'] = null;
    _cajas[idx]['ganancias'] = 0.0;
    _cajas[idx]['capital_productos'] = 0.0;
    _cajas[idx]['esperado'] = 0.0;
    _cajas[idx]['diferencia'] = 0.0;

    await Fb.setList('cajas', _cajas);
    _snack('Caja reabierta exitosamente');
  }

  // ==================== CERRAR CAJA ====================
  Future<void> _cerrarCaja() async {
    if (_cajaAbierta == null) return;
    final ing = _ing(_cajaAbierta!);
    final egr = _egr(_cajaAbierta!);
    final esp = _totalEsp(_cajaAbierta!);
    final ctrl = TextEditingController(text: esp.toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        title: const Text('Cerrar Caja'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _resumenLinea('Monto Inicial', _fmt(_cajaAbierta!['monto_inicial'])),
          _resumenLinea('+ Ingresos', _fmt(ing)),
          _resumenLinea('- Egresos', _fmt(egr)),
          const Divider(),
          _resumenLinea('Total Esperado', _fmt(esp)),
          SizedBox(height: 16),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Monto Final Real', prefixText: '\$ '),
          ),
        ]))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Tema.danger),
            child: const Text('Cerrar Caja'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    _cajaAbierta!['estado'] = 'cerrada';
    _cajaAbierta!['fecha_cierre'] = DateTime.now().toIso8601String();
    _cajaAbierta!['monto_final_real'] = int.tryParse(ctrl.text) ?? esp;
    _cajaAbierta!['ingresos'] = ing;
    _cajaAbierta!['egresos'] = egr;
    await Fb.setList('cajas', _cajas);
    _snack('Caja cerrada exitosamente');
  }

  Widget _resumenLinea(String label, String value) => Padding(
    padding: EdgeInsets.symmetric(vertical: 2),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: Tema.textSoft)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
    ]),
  );

  // ==================== NUEVO MOVIMIENTO ====================
  Future<void> _nuevoMovimiento() async {
    if (_cajaAbierta == null) return;
    String tipo = 'ingreso';
    final conceptoCtrl = TextEditingController();
    final montoCtrl = TextEditingController();
    String metodoPago = 'efectivo';
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) => AlertDialog(
          insetPadding: EdgeInsets.fromLTRB(12, 16, 12, MediaQuery.of(ctx).viewInsets.bottom + 16),
          title: Row(children: [
            Expanded(child: const Text('Nuevo Movimiento')),
            IconButton(
              icon: Icon(Icons.close, size: 20, color: Tema.textMuted),
              onPressed: () => Navigator.pop(ctx, false),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ]),
          content: SizedBox(
            width: double.maxFinite,
            child: Form(
            key: formKey,
            child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                value: tipo,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: const [
                  DropdownMenuItem(value: 'ingreso', child: Text('Ingreso')),
                  DropdownMenuItem(value: 'egreso', child: Text('Egreso')),
                  DropdownMenuItem(value: 'gasto', child: Text('Gasto')),
                  DropdownMenuItem(value: 'pago_proveedor', child: Text('Pago Proveedor')),
                ],
                onChanged: (v) => setM(() => tipo = v!),
              ),
              SizedBox(height: 12),
              TextFormField(controller: conceptoCtrl, decoration: const InputDecoration(labelText: 'Concepto'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null),
              SizedBox(height: 12),
              TextFormField(controller: montoCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monto', prefixText: '\$ '), validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: metodoPago,
                decoration: const InputDecoration(labelText: 'Método de Pago'),
                items: const [
                  DropdownMenuItem(value: 'efectivo', child: Text('Efectivo')),
                  DropdownMenuItem(value: 'tarjeta', child: Text('Tarjeta')),
                  DropdownMenuItem(value: 'transferencia', child: Text('Transferencia')),
                  DropdownMenuItem(value: 'otro', child: Text('Otro')),
                ],
                onChanged: (v) => setM(() => metodoPago = v!),
              ),
            ])),
          )),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Registrar')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final monto = int.tryParse(montoCtrl.text) ?? 0;
    if (monto <= 0) { _snack('El monto debe ser mayor a cero'); return; }
    if (conceptoCtrl.text.trim().isEmpty) { _snack('El concepto es requerido'); return; }

    final movs = _movs(_cajaAbierta!);
    movs.add({
      'tipo': tipo, 'concepto': conceptoCtrl.text.trim(), 'monto': monto,
      'metodo_pago': metodoPago, 'fecha': DateTime.now().toIso8601String(),
    });
    _cajaAbierta!['movimientos'] = movs;
    _cajaAbierta!['ingresos'] = _ing(_cajaAbierta!);
    _cajaAbierta!['egresos'] = _egr(_cajaAbierta!);
    await Fb.setList('cajas', _cajas);
    _snack('Movimiento registrado');
  }

  // ==================== ELIMINAR MOVIMIENTO ====================
  Future<void> _eliminarMovimiento(int index) async {
    if (_cajaAbierta == null) return;
    final movs = _movs(_cajaAbierta!);
    final eliminado = movs.removeAt(index);
    _cajaAbierta!['movimientos'] = movs;
    _cajaAbierta!['ingresos'] = _ing(_cajaAbierta!);
    _cajaAbierta!['egresos'] = _egr(_cajaAbierta!);
    await Fb.setList('cajas', _cajas);
    _snack('Movimiento "${eliminado['concepto'] ?? ''}" eliminado');
  }

  // ==================== EDITAR MOVIMIENTO ====================
  Future<void> _editarMovimiento(int index) async {
    if (_cajaAbierta == null) return;
    final movs = _movs(_cajaAbierta!);
    final mov = Map<dynamic, dynamic>.from(movs[index]);
    String tipo = mov['tipo'] as String? ?? 'ingreso';
    final conceptoCtrl = TextEditingController(text: mov['concepto'] ?? '');
    final montoCtrl = TextEditingController(text: '${mov['monto'] ?? 0}');
    String metodoPago = mov['metodo_pago'] as String? ?? 'efectivo';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) => AlertDialog(
          insetPadding: EdgeInsets.fromLTRB(12, 16, 12, MediaQuery.of(ctx).viewInsets.bottom + 16),
          title: Row(children: [
            Expanded(child: const Text('Editar Movimiento')),
            IconButton(
              icon: Icon(Icons.close, size: 20, color: Tema.textMuted),
              onPressed: () => Navigator.pop(ctx, false),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ]),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                value: tipo,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: const [
                  DropdownMenuItem(value: 'ingreso', child: Text('Ingreso')),
                  DropdownMenuItem(value: 'egreso', child: Text('Egreso')),
                  DropdownMenuItem(value: 'gasto', child: Text('Gasto')),
                  DropdownMenuItem(value: 'pago_proveedor', child: Text('Pago Proveedor')),
                ],
                onChanged: (v) => setM(() => tipo = v!),
              ),
              SizedBox(height: 12),
              TextField(controller: conceptoCtrl, decoration: const InputDecoration(labelText: 'Concepto')),
              SizedBox(height: 12),
              TextField(controller: montoCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monto', prefixText: '\$ ')),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: metodoPago,
                decoration: const InputDecoration(labelText: 'Metodo de Pago'),
                items: const [
                  DropdownMenuItem(value: 'efectivo', child: Text('Efectivo')),
                  DropdownMenuItem(value: 'tarjeta', child: Text('Tarjeta')),
                  DropdownMenuItem(value: 'transferencia', child: Text('Transferencia')),
                  DropdownMenuItem(value: 'otro', child: Text('Otro')),
                ],
                onChanged: (v) => setM(() => metodoPago = v!),
              ),
            ])),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar Cambios')),
          ],
        ),
      ),
    );
    if (ok != true) return;

    final monto = int.tryParse(montoCtrl.text) ?? 0;
    if (monto <= 0) { _snack('El monto debe ser mayor a cero'); return; }
    if (conceptoCtrl.text.trim().isEmpty) { _snack('El concepto es requerido'); return; }

    mov['tipo'] = tipo;
    mov['concepto'] = conceptoCtrl.text.trim();
    mov['monto'] = monto;
    mov['metodo_pago'] = metodoPago;
    _cajaAbierta!['movimientos'] = movs;
    _cajaAbierta!['ingresos'] = _ing(_cajaAbierta!);
    _cajaAbierta!['egresos'] = _egr(_cajaAbierta!);
    await Fb.setList('cajas', _cajas);
    _snack('Movimiento actualizado. Caja recalculada.');
  }

  // ==================== DETALLE CAJA HISTORIAL ====================
  Future<void> _verDetalleCaja(Map<dynamic, dynamic> caja) async {
    final movs = _movs(caja);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        title: Text('Caja #${caja['id']}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
            child: movs.isEmpty
              ? Padding(padding: EdgeInsets.all(24), child: Text('Sin movimientos', textAlign: TextAlign.center, style: TextStyle(color: Tema.textSoft)))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: movs.length,
                  itemBuilder: (_, i) {
                    final m = movs[i];
                    final t = m['tipo'] as String? ?? '';
                    return Container(
                      margin: EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(color: _tipoColor(t).withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: Tema.cardBorder)),
                      child: ListTile(
                        dense: true,
                        leading: CircleAvatar(radius: 16, backgroundColor: _tipoColor(t).withValues(alpha: 0.15), child: Icon(_tipoIcono(t), size: 16, color: _tipoColor(t))),
                        title: Text(m['concepto'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: Text('${_tipoTexto(t)}  •  ${_metodoTexto(m['metodo_pago'] as String?)}', style: TextStyle(fontSize: 11, color: Tema.textSoft)),
                        trailing: Text(_fmt(m['monto']), style: TextStyle(fontWeight: FontWeight.bold, color: t == 'ingreso' ? Tema.primary : Tema.danger, fontSize: 14)),
                      ),
                    );
                  },
                ),
          )),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar'))],
      ),
    );
  }

  // ==================== UI ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(children: [
                _buildStatusCard(),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: Tema.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: Tema.cardBorder)),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(color: Tema.primary, borderRadius: BorderRadius.circular(10)),
                    labelColor: Colors.white,
                    unselectedLabelColor: Tema.textSoft,
                    labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    dividerColor: Colors.transparent,
                    tabs: const [Tab(text: 'Movimientos'), Tab(text: 'Historial')],
                  ),
                ),
                SizedBox(height: 8),
                Expanded(
                  child: TabBarView(controller: _tabController, children: [
                    _cajaAbierta != null ? _buildMovimientosTab() : _buildEmptyMovimientos(),
                    _buildHistorialTab(),
                  ]),
                ),
              ]),
      floatingActionButton: _cajaAbierta != null && _tabController.index == 0
          ? FloatingActionButton.extended(onPressed: _nuevoMovimiento, icon: const Icon(Icons.add), label: const Text('Nuevo Movimiento'))
          : null,
    );
  }

  Widget _buildStatusCard() {
    final abierta = _cajaAbierta != null;
    final ing = abierta ? _ing(_cajaAbierta!) : 0;
    final egr = abierta ? _egr(_cajaAbierta!) : 0;
    final esp = abierta ? _totalEsp(_cajaAbierta!) : 0;

    return Container(
      margin: EdgeInsets.all(12),
      decoration: Tema.cardDeco,
      padding: EdgeInsets.all(16),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Icon(Icons.circle, size: 10, color: abierta ? Tema.primary : Tema.danger),
            SizedBox(width: 8),
            Text(abierta ? 'Caja Abierta' : 'Caja Cerrada',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: abierta ? Tema.primary : Tema.danger)),
          ]),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (abierta ? Tema.primary : Tema.danger).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(abierta ? 'Abierta' : 'Cerrada',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: abierta ? Tema.primary : Tema.danger)),
          ),
        ]),
        if (abierta) ...[
          SizedBox(height: 14),
          Row(children: [
            Expanded(child: _statCard('Monto Inicial', _fmt(_cajaAbierta!['monto_inicial']), Icons.monetization_on_outlined, Tema.primary)),
            SizedBox(width: 8),
            Expanded(child: _statCard('Ingresos', _fmt(ing), Icons.trending_up, Tema.primary)),
          ]),
          SizedBox(height: 8),
          Row(children: [
            Expanded(child: _statCard('Egresos', _fmt(egr), Icons.trending_down, Tema.danger)),
            SizedBox(width: 8),
            Expanded(child: _statCard('Total Esperado', _fmt(esp), Icons.account_balance_wallet_outlined, Tema.darkBlue)),
          ]),
        ],
        SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: abierta
              ? ElevatedButton.icon(
                  onPressed: _cerrarCaja, icon: const Icon(Icons.lock_outline, size: 18),
                  label: const Text('Cerrar Caja'), style: ElevatedButton.styleFrom(backgroundColor: Tema.danger))
              : Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _abrirCaja, icon: const Icon(Icons.lock_open, size: 18),
                      label: const Text('Abrir Caja')),
                    SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _reabrirCaja, icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Reabrir Ultima Caja', style: TextStyle(fontSize: 13))),
                  ],
                ),
        ),
      ]),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(icon, color: color, size: 22),
        SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 10, color: Tema.textSoft, fontWeight: FontWeight.w600)),
          SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
        ])),
      ]),
    );
  }

  Widget _buildEmptyMovimientos() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.receipt_long_outlined, size: 52, color: Tema.textMuted.withValues(alpha: 0.4)),
      SizedBox(height: 10),
      Text('Abre la caja para registrar movimientos', style: TextStyle(color: Tema.textSoft, fontSize: 14)),
    ]));
  }

  Widget _buildMovimientosTab() {
    final movs = _movs(_cajaAbierta!);
    if (movs.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.receipt_long_outlined, size: 52, color: Tema.textMuted.withValues(alpha: 0.4)),
        SizedBox(height: 10),
        Text('Sin movimientos registrados', style: TextStyle(color: Tema.textSoft, fontSize: 14)),
      ]));
    }

    final reversed = List<Map<dynamic, dynamic>>.from(movs.reversed);
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 12),
      itemCount: reversed.length,
      itemBuilder: (_, i) {
        final m = reversed[i];
        final realIndex = movs.length - 1 - i;
        final t = m['tipo'] as String? ?? '';
        final esIngreso = t == 'ingreso';
        return Dismissible(
          key: Key('mov_${m['fecha']}_$realIndex'),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                title: const Text('Eliminar movimiento'),
                content: Text('¿Eliminar "${m['concepto'] ?? ''}" (\$${m['monto'] ?? 0})?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: Tema.danger))),
                ],
              ),
            );
            if (confirm == true) _eliminarMovimiento(realIndex);
            return false;
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 20),
            margin: EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(color: Tema.danger, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
           child: Container(
            margin: EdgeInsets.symmetric(vertical: 4),
            decoration: Tema.cardDeco,
            child: InkWell(
              onTap: () => _editarMovimiento(realIndex),
              borderRadius: BorderRadius.circular(Tema.radius),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              leading: CircleAvatar(radius: 18, backgroundColor: _tipoColor(t).withValues(alpha: 0.12), child: Icon(_tipoIcono(t), size: 18, color: _tipoColor(t))),
              title: Text(m['concepto'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Text('${_tipoTexto(t)}  •  ${_metodoTexto(m['metodo_pago'] as String?)}  •  ${_fmtDate(m['fecha'] as String?)}',
                  style: TextStyle(fontSize: 11, color: Tema.textSoft)),
              trailing: Text(_fmt(m['monto']),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: esIngreso ? Tema.primary : Tema.danger)),
            ),
          ),
          ),
        );
      },
    );
  }

  Widget _buildHistorialTab() {
    final reversed = List<Map<dynamic, dynamic>>.from(_cajas.reversed);
    if (reversed.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.history, size: 52, color: Tema.textMuted.withValues(alpha: 0.4)),
        SizedBox(height: 10),
        Text('Sin historial de cajas', style: TextStyle(color: Tema.textSoft, fontSize: 14)),
      ]));
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: reversed.length,
      itemBuilder: (_, i) {
        final c = reversed[i];
        final totalEsp = _totalEsp(c);
        final finalReal = c['monto_final_real'] as int?;
        final diferencia = finalReal != null ? finalReal - totalEsp : null;
        final estado = (c['estado'] as String?) ?? 'cerrada';
        final esAbierta = estado == 'abierta';

        return Card(
          margin: EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tema.radius), side: BorderSide(color: Tema.cardBorder)),
          elevation: 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(Tema.radius),
            onTap: () => _verDetalleCaja(c),
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [
                    Icon(Icons.circle, size: 9, color: esAbierta ? Tema.primary : Tema.textMuted),
                    SizedBox(width: 6),
                    Text('Caja #${c['id']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  ]),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: esAbierta ? Tema.primary.withValues(alpha: 0.1) : Tema.textMuted.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(esAbierta ? 'Abierta' : 'Cerrada',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: esAbierta ? Tema.primary : Tema.textSoft)),
                  ),
                ]),
                SizedBox(height: 8),
                Row(children: [
                  Expanded(child: _hLine('Apertura', _fmtDate(c['fecha_apertura'] as String?))),
                  Expanded(child: _hLine('Cierre', _fmtDate(c['fecha_cierre'] as String?))),
                ]),
                SizedBox(height: 3),
                Row(children: [
                  Expanded(child: _hLine('Inicial', _fmt(c['monto_inicial']))),
                  Expanded(child: _hLine('Ingresos', _fmt(c['ingresos']))),
                ]),
                SizedBox(height: 3),
                Row(children: [
                  Expanded(child: _hLine('Egresos', _fmt(c['egresos']))),
                  Expanded(child: _hLine('Total Esperado', _fmt(totalEsp))),
                ]),
                if (finalReal != null) ...[
                  SizedBox(height: 3),
                  Row(children: [
                    Expanded(child: _hLine('Final Real', _fmt(finalReal))),
                    Expanded(child: _hLine('Diferencia', _fmt(diferencia ?? 0))),
                  ]),
                ],
                SizedBox(height: 6),
                Row(children: [
                  Icon(Icons.receipt_outlined, size: 14, color: Tema.textMuted),
                  SizedBox(width: 4),
                  Text('${_movs(c).length} movimientos', style: TextStyle(fontSize: 11, color: Tema.textMuted)),
                  const Spacer(),
                  Icon(Icons.chevron_right, size: 16, color: Tema.textMuted),
                ]),
              ]),
            ),
          ),
        );
      },
    );
  }

  Widget _hLine(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1),
      child: RichText(text: TextSpan(children: [
        TextSpan(text: '$label: ', style: TextStyle(fontSize: 11, color: Tema.textMuted, fontWeight: FontWeight.w500)),
        TextSpan(text: value, style: TextStyle(fontSize: 11, color: Tema.textDark, fontWeight: FontWeight.w600)),
      ])),
    );
  }
}

