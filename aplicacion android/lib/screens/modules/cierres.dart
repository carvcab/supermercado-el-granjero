import 'dart:async';

import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../theme.dart';

class CieScreen extends StatefulWidget {
  const CieScreen({super.key});
  @override
  State<CieScreen> createState() => _CieScreenState();
}

class _CieScreenState extends State<CieScreen> {
  List<Map<dynamic, dynamic>> _cajas = [];
  List<Map<dynamic, dynamic>> _cierres = [];
  List<Map<dynamic, dynamic>> _ventas = [];
  List<Map<dynamic, dynamic>> _autoconsumos = [];
  List<Map<dynamic, dynamic>> _productos = [];
  Map<dynamic, dynamic>? _cajaAbierta;
  StreamSubscription? _subJ;
  StreamSubscription? _subC;
  StreamSubscription? _subV;
  StreamSubscription? _subA;
  StreamSubscription? _subP;

  final _dineroRealCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();
  double _diferencia = 0;

  DateTime _desde = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _hasta = DateTime.now();

  @override
  void initState() {
    super.initState();
    _subJ = Fb.stream('cajas').listen((d) {
      setState(() {
        _cajas = d;
        _cajaAbierta = d.isNotEmpty && d.last['estado'] == 'abierta' ? d.last : null;
        _dineroRealCtrl.clear();
        _obsCtrl.clear();
        _diferencia = 0;
      });
    });
    _subC = Fb.stream('cierres').listen((d) => setState(() => _cierres = d));
    _subV = Fb.stream('ventas').listen((d) => setState(() => _ventas = d));
    _subA = Fb.stream('autoconsumos').listen((d) => setState(() => _autoconsumos = d.cast<Map<dynamic, dynamic>>()));
    _subP = Fb.stream('productos').listen((d) => setState(() => _productos = d.cast<Map<dynamic, dynamic>>()));
  }

  @override
  void dispose() {
    _subJ?.cancel();
    _subC?.cancel();
    _subV?.cancel();
    _subA?.cancel();
    _subP?.cancel();
    _dineroRealCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  double _num(dynamic v) => (v is num ? v : 0).toDouble();

  double _totalMovs(String tipo) {
    final movs = List<Map<dynamic, dynamic>>.from(_cajaAbierta?['movimientos'] ?? []);
    return movs
        .where((m) => (m['tipo'] ?? '') == tipo)
        .fold<double>(0, (s, m) => s + ((m['monto'] as num?)?.toDouble() ?? 0));
  }

  void _calcularDiferencia() {
    if (_cajaAbierta == null) return;
    final inicial = _num(_cajaAbierta!['monto_inicial']);
    final ingresos = _totalMovs('ingreso');
    final egresos = _totalMovs('egreso');
    final real = double.tryParse(_dineroRealCtrl.text) ?? 0;
    setState(() => _diferencia = real - (inicial + ingresos - egresos));
  }

  Future<void> _cerrarCaja() async {
    if (_cajaAbierta == null) return;
    final real = double.tryParse(_dineroRealCtrl.text);
    if (real == null || real < 0) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingrese un monto real valido')));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Cierre'),
        content: const Text('Esta seguro de cerrar la caja? No podra agregar mas movimientos hoy.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cerrar Caja')),
        ],
      ),
    );
    if (ok != true) return;

    final inicial = _num(_cajaAbierta!['monto_inicial']);
    final ingresos = _totalMovs('ingreso');
    final egresos = _totalMovs('egreso');
    final esperado = inicial + ingresos - egresos;
    final diferencia = real - esperado;
    final obs = _obsCtrl.text;
    final now = DateTime.now().toIso8601String();

    // Calculate ganancias: only count sales created AFTER this caja opened
    final openTimestamp = (_cajaAbierta!['fecha_apertura'] ?? '').toString();
    var totalVenta = 0.0;
    var totalCosto = 0.0;
    for (final v in _ventas) {
      final vCreated = (v['created_at'] ?? v['fecha'] ?? '').toString();
      if (vCreated.compareTo(openTimestamp) >= 0 && (v['metodo_pago'] ?? '') != 'fiado') {
        totalVenta += _num(v['total']);
        final items = (v['items'] as List?) ?? [];
        for (final it in items) {
          final qty = _num(it['cantidad']);
          final pCompra = _num(it['precio_compra']);
          totalCosto += qty * pCompra;
        }
      }
    }
    var totalConsumosCosto = 0.0;
    final openDate = (openTimestamp).toString().substring(0, 10);
    for (final c in _autoconsumos) {
      final cFecha = (c['fecha'] ?? '').toString().substring(0, 10);
      if (cFecha.compareTo(openDate) >= 0) {
        final prod = _productos.isNotEmpty
            ? _productos.firstWhere((p) => p['id']?.toString() == c['producto_id']?.toString(), orElse: () => <dynamic, dynamic>{})
            : <dynamic, dynamic>{};
        final pc = prod.isNotEmpty ? _num(prod['precio_compra']) : 0.0;
        totalConsumosCosto += _num(c['cantidad']) * pc;
      }
    }
    final ganancias = totalVenta - totalCosto - totalConsumosCosto;

    _cajaAbierta!['estado'] = 'cerrada';
    _cajaAbierta!['fecha_cierre'] = now;
    _cajaAbierta!['dinero_real'] = real;
    _cajaAbierta!['esperado'] = esperado;
    _cajaAbierta!['diferencia'] = diferencia;
    _cajaAbierta!['ganancias'] = ganancias;
    _cajaAbierta!['consumos_propios'] = totalConsumosCosto;
    _cajaAbierta!['capital_productos'] = totalCosto;
    _cajaAbierta!['observaciones'] = obs;
    _cajaAbierta!['ingresos'] = ingresos;
    _cajaAbierta!['egresos'] = egresos;
    await Fb.setList('cajas', _cajas);

    final cfg = await Fb.getDoc('config_caja_negocio');
    cfg['balance'] = _num(cfg['balance']) + _num(_cajaAbierta!['monto_inicial']) + totalCosto + diferencia;
    cfg['ganancias_acumuladas'] = _num(cfg['ganancias_acumuladas']) + ganancias;
    cfg['updated_at'] = now;
    await Fb.setDoc('config_caja_negocio', cfg);

    final cierreId = _cierres.isEmpty ? 1 : _cierres.map((x) => (x['id'] as int)).reduce((a, b) => a > b ? a : b) + 1;
    _cierres.add({
      'id': cierreId,
      'caja_id': _cajaAbierta!['id'],
      'fecha_cierre': now,
      'fecha_apertura': _cajaAbierta!['fecha_apertura'],
      'monto_inicial': inicial,
      'ingresos': ingresos,
      'egresos': egresos,
      'esperado': esperado,
      'dinero_real': real,
      'diferencia': diferencia,
      'ganancias': ganancias,
      'consumos_propios': totalConsumosCosto,
      'observaciones': obs,
    });
    await Fb.setList('cierres', _cierres);

    if (mounted) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF1b4d3e), size: 24),
              SizedBox(width: 10),
              Text('Cierre Realizado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryRow(Icons.trending_up, 'Ganancias del periodo', Fb.formatMoney(ganancias), Colors.green.shade700),
              SizedBox(height: 10),
              _buildSummaryRow(Icons.account_balance_wallet, 'Total en caja', Fb.formatMoney(real), Tema.darkBlue),
              SizedBox(height: 10),
              _buildSummaryRow(Icons.inventory_2, 'Capital en productos', Fb.formatMoney(totalCosto), Tema.primary),
              SizedBox(height: 6),
              const Divider(),
              Text('La caja ha sido cerrada exitosamente.', style: TextStyle(fontSize: 12, color: Tema.textMuted)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Aceptar', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    }
  }

  List<Map<dynamic, dynamic>> get _cierresFiltrados {
    final desde = DateTime(_desde.year, _desde.month, _desde.day);
    final hasta = DateTime(_hasta.year, _hasta.month, _hasta.day).add(const Duration(days: 1));
    return _cierres.where((c) {
      final fecha = (c['fecha_cierre'] ?? c['fecha_apertura'] ?? '').toString();
      if (fecha.isEmpty) return false;
      final d = DateTime.tryParse(fecha);
      if (d == null) return false;
      return !d.isBefore(desde) && d.isBefore(hasta);
    }).toList()..sort((a, b) => (b['fecha_cierre'] ?? '').compareTo(a['fecha_cierre'] ?? ''));
  }

  String _formatFecha(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  Future<void> _pickDate(bool esDesde) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: esDesde ? _desde : _hasta,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: esDesde ? 'Desde' : 'Hasta',
    );
    if (picked != null) setState(() => esDesde ? _desde = picked : _hasta = picked);
  }

  Future<void> _eliminarCierre(Map<dynamic, dynamic> cierre) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Cierre'),
        content: const Text('Eliminar este registro de cierre de forma permanente?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: Tema.danger), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true) return;
    _cierres.removeWhere((x) => x['id'] == cierre['id']);
    await Fb.setList('cierres', _cierres);

    final cajaId = cierre['caja_id'];
    if (cajaId != null) {
      final idx = _cajas.indexWhere((c) => c['id'] == cajaId);
      if (idx >= 0 && _cajas[idx]['estado'] == 'cerrada') {
        _cajas[idx]['estado'] = 'abierta';
        _cajas[idx].remove('fecha_cierre');
        _cajas[idx].remove('dinero_real');
        _cajas[idx].remove('diferencia');
        _cajas[idx].remove('observaciones');
        await Fb.setList('cajas', _cajas);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cierre eliminado y caja reabierta')));
        return;
      }
    }
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cierre eliminado')));
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      _buildStatusCard(),
      SizedBox(height: 12),
    ];
    if (_cajaAbierta != null) {
      children.add(_buildCloseForm());
      children.add(SizedBox(height: 12));
    }
    children.add(_buildHistorial());
    return ListView(
      padding: EdgeInsets.all(12),
      children: children,
    );
  }

  Widget _buildStatusCard() {
    final abierta = _cajaAbierta != null;
    return Container(
      decoration: Tema.cardDeco,
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(abierta ? Icons.lock_open_rounded : Icons.lock_rounded, color: abierta ? Tema.primary : Tema.danger, size: 26),
              SizedBox(width: 10),
              Text(abierta ? 'Caja Abierta' : 'Caja Cerrada', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: abierta ? Tema.primary : Tema.danger)),
              SizedBox(width: 10),
              Container(width: 10, height: 10, decoration: BoxDecoration(color: abierta ? Tema.primary : Tema.danger, shape: BoxShape.circle)),
            ],
          ),
          if (!abierta) ...[
            SizedBox(height: 10),
            Text('No hay caja abierta. Abre una caja desde el modulo de Caja antes de realizar un cierre.', textAlign: TextAlign.center, style: TextStyle(color: Tema.textSoft, fontSize: 13)),
            if (_cajas.isNotEmpty && _cajas.last['estado'] == 'cerrada') ...[
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    _cajas.last['estado'] = 'abierta';
                    _cajas.last.remove('fecha_cierre');
                    _cajas.last.remove('dinero_real');
                    _cajas.last.remove('diferencia');
                    _cajas.last.remove('observaciones');
                    await Fb.setList('cajas', _cajas);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Caja reabierta')));
                  },
                  icon: const Icon(Icons.lock_open, size: 16),
                  label: const Text('Reabrir ultima caja'),
                  style: OutlinedButton.styleFrom(foregroundColor: Tema.primary),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildCloseForm() {
    final inicial = _num(_cajaAbierta!['monto_inicial']);
    final ingresos = _num(_cajaAbierta!['ingresos']);
    final egresos = _num(_cajaAbierta!['egresos']);

    return Container(
      decoration: Tema.cardDeco,
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(Icons.calculate_rounded, color: Tema.primary, size: 20), SizedBox(width: 8), Text('Realizar Cierre', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Tema.textDark))]),
          SizedBox(height: 16),
          _roField('Monto Inicial', Fb.formatMoney(inicial), Icons.play_arrow_rounded, Tema.primary),
          SizedBox(height: 8),
          _roField('Ingresos', Fb.formatMoney(ingresos), Icons.trending_up_rounded, Colors.green.shade700),
          SizedBox(height: 8),
          _roField('Egresos', Fb.formatMoney(egresos), Icons.trending_down_rounded, Tema.danger),
          SizedBox(height: 16),
          TextField(
            controller: _dineroRealCtrl,
            decoration: const InputDecoration(
              labelText: 'Dinero Real en Caja *',
              hintText: 'Ingrese el monto fisico contado...',
              helperText: 'Cuente el dinero fisico que hay en caja y registrelo',
              prefixIcon: Icon(Icons.monetization_on_rounded),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => _calcularDiferencia(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _diferencia < 0 ? Tema.danger.withValues(alpha: 0.07) : _diferencia > 0 ? Colors.green.withValues(alpha: 0.07) : Tema.cardBorder.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(Tema.radiusSm),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Diferencia', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Tema.textDark)),
                Text(Fb.formatMoney(_diferencia), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _diferencia < 0 ? Tema.danger : _diferencia > 0 ? Colors.green.shade700 : Tema.textDark)),
              ],
            ),
          ),
          SizedBox(height: 12),
          TextField(controller: _obsCtrl, decoration: const InputDecoration(labelText: 'Observaciones', prefixIcon: Icon(Icons.notes_rounded)), maxLines: 3),
          SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _cerrarCaja,
              icon: const Icon(Icons.lock_rounded),
              label: const Text('Cerrar Caja'),
              style: ElevatedButton.styleFrom(backgroundColor: Tema.danger, padding: EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roField(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: Tema.bg.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(Tema.radiusSm), border: Border.all(color: Tema.cardBorder)),
      child: Row(children: [
        Icon(icon, color: color.withValues(alpha: 0.7), size: 20),
        SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 13, color: Tema.textSoft)),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        SizedBox(width: 10),
        Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: Tema.textSoft))),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }

  Widget _buildHistorial() {
    final filtrados = _cierresFiltrados;

    return Container(
      decoration: Tema.cardDeco,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(Icons.history_rounded, color: Tema.primary, size: 20), SizedBox(width: 8), Text('Historial de Cierres', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Tema.textDark))]),
          SizedBox(height: 12),
          Row(children: [
            Expanded(child: _dateBtn('Desde', _desde, () => _pickDate(true))),
            SizedBox(width: 8),
            Expanded(child: _dateBtn('Hasta', _hasta, () => _pickDate(false))),
          ]),
          SizedBox(height: 12),
          if (filtrados.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Column(children: [
                Icon(Icons.inbox_rounded, size: 40, color: Tema.textMuted.withValues(alpha: 0.4)),
                SizedBox(height: 8),
                Text('Sin cierres registrados', style: TextStyle(color: Tema.textMuted, fontSize: 14)),
              ])),
            )
          else
            ...filtrados.map((c) {
              final montoInicial = _num(c['monto_inicial']);
              final ingresos = _num(c['ingresos']);
              final egresos = _num(c['egresos']);
              final real = _num(c['dinero_real']);
              final diferencia = _num(c['diferencia']);
              final obs = c['observaciones'] ?? '';
              final fecha = c['fecha_cierre'] ?? c['fecha_apertura'] ?? '';

              return Dismissible(
                key: Key('cierre_${c['id']}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: 20),
                  margin: EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(color: Tema.danger, borderRadius: BorderRadius.circular(Tema.radius)),
                  child: const Icon(Icons.delete_rounded, color: Colors.white),
                ),
                confirmDismiss: (_) => showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Eliminar Cierre'),
                    content: const Text('Eliminar este registro de cierre de forma permanente?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: Tema.danger), child: const Text('Eliminar')),
                    ],
                  ),
                ),
                onDismissed: (_) => _eliminarCierre(c),
                child: Container(
                  margin: EdgeInsets.only(bottom: 8),
                  decoration: Tema.cardDeco,
                  padding: EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatFecha(fecha), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Tema.textDark)),
                          Icon(Icons.swipe_left_rounded, size: 16, color: Tema.textMuted.withValues(alpha: 0.5)),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(children: [
                        _stat('Inicial', Fb.formatMoney(montoInicial), Tema.textSoft),
                        SizedBox(width: 12),
                        _stat('Ingresos', Fb.formatMoney(ingresos), Colors.green.shade700),
                        SizedBox(width: 12),
                        _stat('Egresos', Fb.formatMoney(egresos), Tema.danger),
                      ]),
                      SizedBox(height: 6),
                      Row(children: [
                        _stat('Dinero Real', Fb.formatMoney(real), Tema.darkBlue),
                        SizedBox(width: 12),
                        _stat('Diferencia', Fb.formatMoney(diferencia), diferencia < 0 ? Tema.danger : Colors.green.shade700),
                      ]),
                      if (obs.toString().isNotEmpty) ...[
                        SizedBox(height: 6),
                        Text(obs.toString(), style: TextStyle(fontSize: 12, color: Tema.textMuted, fontStyle: FontStyle.italic), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
        ],
      ),
    ),
  );
}),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 10, color: Tema.textMuted)),
        SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }

  Widget _dateBtn(String label, DateTime val, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, prefixIcon: const Icon(Icons.calendar_today_rounded, size: 17), isDense: true),
        child: Text('${val.day.toString().padLeft(2, '0')}/${val.month.toString().padLeft(2, '0')}/${val.year}', style: TextStyle(fontSize: 13, color: Tema.textDark)),
      ),
    );
  }
}


