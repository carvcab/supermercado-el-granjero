import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme.dart';
import '../../services/firestore_service.dart';

class RepScreen extends StatefulWidget {
  const RepScreen({super.key});
  @override
  State<RepScreen> createState() => _RepScreenState();
}

class _RepScreenState extends State<RepScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab;

  List<Map<dynamic, dynamic>> _ventas = [];
  List<Map<dynamic, dynamic>> _productos = [];
  List<Map<dynamic, dynamic>> _fiados = [];
  List<Map<dynamic, dynamic>> _cajas = [];
  List<Map<dynamic, dynamic>> _distribuciones = [];
  List<Map<dynamic, dynamic>> _autoconsumos = [];
  bool _loading = true;
  int _preset = 4;
  StreamSubscription? _subV;
  StreamSubscription? _subP;
  StreamSubscription? _subF;
  StreamSubscription? _subC;
  StreamSubscription? _subD;
  StreamSubscription? _subAutoc;

  DateTime _desde = DateTime(2020);
  DateTime _hasta = DateTime.now();

  static const _presetLabels = ['Hoy', 'Ayer', 'Esta Semana', 'Este Mes', 'Todo'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 8, vsync: this);
    _subV = Fb.stream('ventas').listen((d) { if (mounted) setState(() { _ventas = d; _loading = false; }); });
    _subP = Fb.stream('productos').listen((d) { if (mounted) setState(() => _productos = d); });
    _subF = Fb.stream('fiados').listen((d) { if (mounted) setState(() => _fiados = d); });
    _subC = Fb.stream('cajas').listen((d) { if (mounted) setState(() => _cajas = d); });
    _subD = Fb.stream('distribuciones').listen((d) { if (mounted) setState(() => _distribuciones = d); });
    _subAutoc = Fb.stream('autoconsumos').listen((d) => setState(() => _autoconsumos = d.cast<Map<dynamic, dynamic>>()));
    Future.delayed(const Duration(seconds: 5), () { if (mounted && _loading) setState(() => _loading = false); });
  }

  @override
  void dispose() {
    _subV?.cancel();
    _subP?.cancel();
    _subF?.cancel();
    _subC?.cancel();
    _subD?.cancel();
    _subAutoc?.cancel();
    _tab.dispose();
    super.dispose();
  }

  DateTime? _parseFecha(dynamic f) {
    if (f == null) return null;
    try {
      final s = f.toString().trim();
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  bool _inRange(DateTime? f) {
    if (f == null) return false;
    final d = DateTime(f.year, f.month, f.day);
    final desde = DateTime(_desde.year, _desde.month, _desde.day);
    final hasta = DateTime(_hasta.year, _hasta.month, _hasta.day);
    return !d.isBefore(desde) && !d.isAfter(hasta);
  }

  List<Map<dynamic, dynamic>> get _ventasFiltradas => _ventas.where((v) => _inRange(_parseFecha(v['fecha']))).toList();

  List<Map<dynamic, dynamic>> get _cajasFiltradas => _cajas.where((c) => _inRange(_parseFecha(c['fecha_apertura']))).toList();

  List<Map<dynamic, dynamic>> get _fiadosRango => _fiados.where((f) {
    final ff = f['fecha']?.toString() ?? '';
    if (ff.isEmpty) return false;
    return _inRange(_parseFecha(ff));
  }).toList();

  List<Map<dynamic, dynamic>> get _distribucionesRango => _distribuciones.where((d) {
    final ff = d['fecha']?.toString() ?? '';
    if (ff.isEmpty) return false;
    return _inRange(DateTime.tryParse(ff));
  }).toList();

  List<Map<dynamic, dynamic>> get _filtroAutoconsumos => _autoconsumos.where((c) {
    final ff = c['fecha']?.toString() ?? '';
    if (ff.isEmpty) return false;
    return _inRange(DateTime.tryParse(ff));
  }).toList();

  void _setPreset(int p) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    setState(() {
      _preset = p;
      switch (p) {
        case 0: _desde = today; _hasta = today; break;
        case 1: _desde = today.subtract(const Duration(days: 1)); _hasta = today.subtract(const Duration(days: 1)); break;
        case 2:
          final dow = today.weekday % 7;
          _desde = today.subtract(Duration(days: dow));
          _hasta = today;
          break;
        case 3: _desde = DateTime(today.year, today.month, 1); _hasta = today; break;
        case 4: _desde = DateTime(2020); _hasta = today; break;
      }
    });
  }

  Future<void> _pickDesde() async {
    final d = await showDatePicker(context: context, initialDate: _desde, firstDate: DateTime(2020), lastDate: DateTime.now());
    if (d != null) setState(() { _desde = d; _preset = -1; });
  }

  Future<void> _pickHasta() async {
    final d = await showDatePicker(context: context, initialDate: _hasta, firstDate: DateTime(2020), lastDate: DateTime.now());
    if (d != null) setState(() { _hasta = d; _preset = -1; });
  }

  String _fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String _fmtDateShort(String d) => d.length >= 10 ? d.substring(0, 10) : d;

  // ═══════════════════════ EXPORT CSV ═══════════════════════

  Future<void> _exportCSV() async {
    try {
      final csv = _buildCSV();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/reporte_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv);
      await Share.shareXFiles([XFile(file.path)], text: 'Reporte ${_tabNames[_tab.index]}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al exportar'), behavior: SnackBarBehavior.floating));
      }
    }
  }

  List<String> get _tabNames => const ['Ventas', 'Ganancias', 'Inventario', 'Fiados', 'Caja', 'Distribuciones', 'Ganancia Neta', 'Consumos'];

  String _buildCSV() {
    final buf = StringBuffer();
    final i = _tab.index;
    if (i == 0) {
      buf.writeln('Fecha,Cliente,Items,Total,Metodo');
      for (final v in _ventasFiltradas) {
        final items = v['items'] as List? ?? [];
        buf.writeln('${_fmtDateShort((v['fecha'] ?? '').toString())},"${(v['cliente_nombre'] ?? v['cliente'] ?? '').toString()}",${items.length},${v['total'] ?? 0},"${(v['metodo'] ?? v['metodo_pago'] ?? '').toString()}"');
      }
    } else if (i == 1) {
      buf.writeln('Fecha,Ventas,Costo,Valor,Ganancia,Margen');
      final map = _gananciasPorDia();
      for (final e in map.entries) {
        final d = e.value;
        final g = d['ganancia']!;
        final v = d['valor']!;
        final mg = v > 0 ? (g / v * 100).toStringAsFixed(1) : '0';
        buf.writeln('${e.key},${d['ventas']},${d['costo']},$v,$g,$mg%');
      }
    } else if (i == 2) {
      buf.writeln('Nombre,Stock,P.Compra,P.Venta,Margen,Valor Total');
      for (final p in _productos) {
        final st = (p['stock_actual'] as num?)?.toInt() ?? 0;
        final pc = (p['precio_compra'] as num?)?.toInt() ?? 0;
        final pv = (p['precio_venta'] as num?)?.toInt() ?? 0;
        final mg = pc > 0 ? ((pv - pc) / pc * 100).toStringAsFixed(0) : '0';
        buf.writeln('"${(p['nombre'] ?? '').toString()}",$st,$pc,$pv,$mg%,${st * pv}');
      }
    } else if (i == 3) {
      buf.writeln('Deudor,Deuda Total,Fiados Activos,Telefono');
      final deu = _deudoresList();
      for (final d in deu) {
        buf.writeln('"${d['nombre']}",${d['total']},"${d['activos']}","${d['telefono'] ?? ''}"');
      }
    } else if (i == 4) {
      buf.writeln('Caja ID,Apertura,Ingresos,Egresos,Balance,Movimientos');
      for (final c in _cajasFiltradas) {
        final ing = _cajaIng(c);
        final egr = _cajaEgr(c);
        buf.writeln('${c['id']},"${_fmtDateShort((c['fecha_apertura'] ?? '').toString())}",$ing,$egr,${ing - egr},${(c['movimientos'] as List? ?? []).length}');
      }
    } else if (i == 5) {
      buf.writeln('Fecha,Total,Categorias');
      for (final d in _distribucionesRango) {
        final cats = ((d['categorias'] as List?) ?? (d['items'] as List?) ?? []).map((c) => '${(c as Map)['nombre']}:${c['monto']}(${(c['porcentaje'] as num?)?.toStringAsFixed(1) ?? 0}%)').join(' | ');
        buf.writeln('"${_fmtDateShort((d['fecha'] ?? '').toString())}",${d['total'] ?? 0},"$cats"');
      }
    } else if (i == 6) {
      buf.writeln('Mes,Ingresos,Egresos,Ganancia Neta');
      final mb = _monthlyBreakdown();
      for (final e in mb.entries) {
        final m = e.value;
        buf.writeln('${e.key},${m['ingresos']},${m['egresos']},${m['neta']}');
      }
    }
    return buf.toString();
  }

  // ═══════════════════════ BUILD ═══════════════════════════

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Tema.primary));

    return Padding(
      padding: EdgeInsets.all(10),
      child: Column(children: [
        _buildExportRow(),
        SizedBox(height: 6),
        _buildPresets(),
        SizedBox(height: 8),
        _buildDateFilter(),
        SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(Tema.radiusSm),
          ),
          child: TabBar(
            controller: _tab,
            isScrollable: true,
            labelColor: Tema.primary,
            unselectedLabelColor: Tema.textMuted,
            indicatorColor: Tema.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            tabs: const [
              Tab(text: 'Ventas'),
              Tab(text: 'Ganancias'),
              Tab(text: 'Inventario'),
              Tab(text: 'Fiados'),
              Tab(text: 'Caja'),
              Tab(text: 'Distribuciones'),
              Tab(text: 'Ganancia Neta'),
              Tab(text: 'Consumos'),
            ],
          ),
        ),
        SizedBox(height: 8),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _buildVentasTab(),
              _buildGananciasTab(),
              _buildInventarioTab(),
              _buildFiadosTab(),
              _buildCajaTab(),
              _buildDistribucionesTab(),
              _buildGananciaNetaTab(),
              _buildConsumosTab(),
            ],
          ),
        ),
      ]),
    );
  }

  // ═══════════════════════ EXPORT ROW ═════════════════════

  Widget _buildExportRow() {
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      InkWell(
        onTap: _exportCSV,
        borderRadius: BorderRadius.circular(Tema.radiusSm),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Tema.primary,
            borderRadius: BorderRadius.circular(Tema.radiusSm),
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.file_download, size: 15, color: Colors.white),
            SizedBox(width: 5),
            Text('Exportar CSV', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
          ]),
        ),
      ),
    ]);
  }

  // ═══════════════════════ DATE PRESETS ═══════════════════

  Widget _buildPresets() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: List.generate(_presetLabels.length, (i) {
        final active = _preset == i;
        return Padding(
          padding: EdgeInsets.only(right: 6),
          child: InkWell(
            onTap: () => _setPreset(i),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: active ? Tema.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: active ? Tema.primary : Tema.cardBorder),
              ),
              child: Text(_presetLabels[i],
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: active ? Colors.white : Tema.textSoft)),
            ),
          ),
        );
      })),
    );
  }

  // ═══════════════════════ DATE FILTER ═══════════════════

  Widget _buildDateFilter() {
    return Row(children: [
      Expanded(
        child: InkWell(
          onTap: _pickDesde,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(Tema.radiusSm), border: Border.all(color: Tema.cardBorder)),
            child: Row(children: [
              const Icon(Icons.calendar_today, size: 16, color: Tema.primary),
              SizedBox(width: 6),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Desde', style: TextStyle(fontSize: 10, color: Tema.textMuted)),
                Text(_fmt(_desde), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Tema.textDark)),
              ]),
            ]),
          ),
        ),
      ),
      Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.arrow_forward, size: 16, color: Tema.textMuted)),
      Expanded(
        child: InkWell(
          onTap: _pickHasta,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(Tema.radiusSm), border: Border.all(color: Tema.cardBorder)),
            child: Row(children: [
              const Icon(Icons.calendar_today, size: 16, color: Tema.primary),
              SizedBox(width: 6),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Hasta', style: TextStyle(fontSize: 10, color: Tema.textMuted)),
                Text(_fmt(_hasta), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Tema.textDark)),
              ]),
            ]),
          ),
        ),
      ),
    ]);
  }

  // ═══════════════════════ VENTAS ═══════════════════════

  Widget _buildVentasTab() {
    final vf = _ventasFiltradas;
    final totalVentas = vf.fold<int>(0, (s, v) => s + ((v['total'] as num?)?.toInt() ?? 0));
    final cantidad = vf.length;
    final promedio = cantidad > 0 ? totalVentas ~/ cantidad : 0;
    final ticketMax = vf.isEmpty ? 0 : vf.map((v) => (v['total'] as num?)?.toInt() ?? 0).reduce((a, b) => a > b ? a : b);

    final porDia = <String, int>{};
    for (final v in vf) {
      final f = _fmtDateShort((v['fecha'] ?? '').toString());
      porDia[f] = (porDia[f] ?? 0) + ((v['total'] as num?)?.toInt() ?? 0);
    }
    final dias = porDia.entries.toList()..sort((a, b) => b.key.compareTo(a.key));

    return SingleChildScrollView(
      child: Column(children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          _kpi('Total Ventas', Fb.formatMoney(totalVentas), Icons.trending_up, Tema.kpiAccents[0], Tema.kpiBgs[0]),
          _kpi('Cantidad', '$cantidad', Icons.receipt_long, Tema.kpiAccents[1], Tema.kpiBgs[1]),
          _kpi('Promedio', Fb.formatMoney(promedio), Icons.bar_chart, Tema.kpiAccents[2], Tema.kpiBgs[2]),
          _kpi('Ticket Max', Fb.formatMoney(ticketMax), Icons.emoji_events, Tema.kpiAccents[3], Tema.kpiBgs[3]),
        ]),
        SizedBox(height: 14),
        if (dias.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Ventas por Dia', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Tema.textDark)),
              Text('${dias.length} dias', style: TextStyle(fontSize: 11, color: Tema.textMuted)),
            ]),
          ),
          _barChart(dias, Tema.kpiAccents[0]),
          SizedBox(height: 10),
        ],
        if (vf.isEmpty)
          _empty('Sin ventas en este rango')
        else
          Container(
            decoration: Tema.cardDeco,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                headingTextStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Tema.textSoft),
                dataTextStyle: TextStyle(fontSize: 12, color: Tema.textDark),
                columns: const [
                  DataColumn(label: Text('Fecha')),
                  DataColumn(label: Text('Cliente')),
                  DataColumn(label: Text('Items'), numeric: true),
                  DataColumn(label: Text('Total'), numeric: true),
                  DataColumn(label: Text('Metodo')),
                ],
                rows: vf.map((v) {
                  final items = v['items'] as List? ?? [];
                  return DataRow(cells: [
                    DataCell(Text(_fmtDateShort((v['fecha'] ?? '').toString()))),
                    DataCell(Text(v['cliente_nombre'] ?? v['cliente'] ?? '-')),
                    DataCell(Text('${items.length}')),
                    DataCell(Text(Fb.formatMoney(v['total'] ?? 0))),
                    DataCell(Text(v['metodo'] ?? v['metodo_pago'] ?? '-')),
                  ]);
                }).toList(),
              ),
            ),
          ),
      ]),
    );
  }

  // ═══════════════════════ GANANCIAS ═══════════════════════

  Map<String, Map<String, int>> _gananciasPorDia() {
    final vf = _ventasFiltradas;
    final Map<String, Map<String, int>> porDia = {};
    for (final v in vf) {
      final items = v['items'] as List? ?? [];
      final f = _fmtDateShort((v['fecha'] ?? '').toString());
      porDia.putIfAbsent(f, () => {'ganancia': 0, 'costo': 0, 'valor': 0, 'ventas': 0});
      for (final it in items) {
        if (it is! Map) continue;
        final pv = ((it['precio_venta'] as num?) ?? (it['precio_unitario'] as num?))?.toInt() ?? 0;
        final pc = (it['precio_compra'] as num?)?.toInt() ?? 0;
        final cant = (it['cantidad'] as num?)?.toInt() ?? 0;
        porDia[f]!['ganancia'] = porDia[f]!['ganancia']! + (pv - pc) * cant;
        porDia[f]!['costo'] = porDia[f]!['costo']! + pc * cant;
        porDia[f]!['valor'] = porDia[f]!['valor']! + pv * cant;
      }
      porDia[f]!['ventas'] = porDia[f]!['ventas']! + 1;
    }
    return porDia;
  }

  Widget _buildGananciasTab() {
    final porDia = _gananciasPorDia();
    final dias = porDia.entries.toList()..sort((a, b) => b.key.compareTo(a.key));

    int gananciaTotal = 0;
    int ventasCosto = 0;
    int ventasValor = 0;
    for (final e in dias) {
      gananciaTotal += e.value['ganancia']!;
      ventasCosto += e.value['costo']!;
      ventasValor += e.value['valor']!;
    }
    final margen = ventasValor > 0 ? (gananciaTotal / ventasValor * 100).toStringAsFixed(1) : '0.0';

    final chartData = dias.map((e) => MapEntry(e.key, e.value['ganancia']!)).toList();

    return SingleChildScrollView(
      child: Column(children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          _kpi('Ganancia Total', Fb.formatMoney(gananciaTotal), Icons.savings, Tema.kpiAccents[0], Tema.kpiBgs[0]),
          _kpi('Margen %', '$margen%', Icons.percent, Tema.kpiAccents[1], Tema.kpiBgs[1]),
          _kpi('Ventas Costo', Fb.formatMoney(ventasCosto), Icons.shopping_cart, Tema.kpiAccents[2], Tema.kpiBgs[2]),
          _kpi('Ventas Valor', Fb.formatMoney(ventasValor), Icons.monetization_on, Tema.kpiAccents[3], Tema.kpiBgs[3]),
        ]),
        SizedBox(height: 14),
        if (chartData.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Text('Ganancia por Dia', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Tema.textDark)),
          ),
          _barChart(chartData, Tema.kpiAccents[0]),
          SizedBox(height: 10),
        ],
        if (dias.isEmpty)
          _empty('Sin datos de ganancias')
        else ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Text('Resumen por dia', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Tema.textDark)),
          ),
          Container(
            decoration: Tema.cardDeco,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 14,
                headingTextStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Tema.textSoft),
                dataTextStyle: TextStyle(fontSize: 12, color: Tema.textDark),
                columns: const [
                  DataColumn(label: Text('Fecha')),
                  DataColumn(label: Text('Ventas'), numeric: true),
                  DataColumn(label: Text('Costo'), numeric: true),
                  DataColumn(label: Text('Valor'), numeric: true),
                  DataColumn(label: Text('Ganancia'), numeric: true),
                  DataColumn(label: Text('Margen'), numeric: true),
                ],
                rows: dias.map((e) {
                  final d = e.value;
                  final g = d['ganancia']!;
                  final v = d['valor']!;
                  final mg = v > 0 ? (g / v * 100).toStringAsFixed(1) : '0.0';
                  return DataRow(cells: [
                    DataCell(Text(e.key)),
                    DataCell(Text('${d['ventas']}')),
                    DataCell(Text(Fb.formatMoney(d['costo']!))),
                    DataCell(Text(Fb.formatMoney(v))),
                    DataCell(Text(Fb.formatMoney(g), style: TextStyle(color: g >= 0 ? Tema.primary : Tema.danger, fontWeight: FontWeight.w600))),
                    DataCell(Text('$mg%')),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ]),
    );
  }

  // ═══════════════════════ INVENTARIO ═══════════════════════

  Widget _buildInventarioTab() {
    final prod = _productos;
    final totalProd = prod.length;
    int valorCosto = 0;
    int valorVenta = 0;
    for (final p in prod) {
      final st = (p['stock_actual'] as num?)?.toInt() ?? 0;
      final pc = (p['precio_compra'] as num?)?.toInt() ?? 0;
      final pv = (p['precio_venta'] as num?)?.toInt() ?? 0;
      valorCosto += st * pc;
      valorVenta += st * pv;
    }
    final gananciaPot = valorVenta - valorCosto;

    final sorted = List<Map<dynamic, dynamic>>.from(prod);
    sorted.sort((a, b) {
      final va = ((a['stock_actual'] as num?)?.toInt() ?? 0) * ((a['precio_venta'] as num?)?.toInt() ?? 0);
      final vb = ((b['stock_actual'] as num?)?.toInt() ?? 0) * ((b['precio_venta'] as num?)?.toInt() ?? 0);
      return vb.compareTo(va);
    });

    return SingleChildScrollView(
      child: Column(children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          _kpi('Total Prod.', '$totalProd', Icons.inventory_2, Tema.kpiAccents[0], Tema.kpiBgs[0]),
          _kpi('Valor Costo', Fb.formatMoney(valorCosto), Icons.shopping_bag, Tema.kpiAccents[1], Tema.kpiBgs[1]),
          _kpi('Valor Venta', Fb.formatMoney(valorVenta), Icons.store, Tema.kpiAccents[2], Tema.kpiBgs[2]),
          _kpi('Gan. Potencial', Fb.formatMoney(gananciaPot), Icons.rocket_launch, Tema.kpiAccents[3], Tema.kpiBgs[3]),
        ]),
        SizedBox(height: 14),
        if (prod.isEmpty)
          _empty('Sin productos')
        else
          Container(
            decoration: Tema.cardDeco,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 12,
                headingTextStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Tema.textSoft),
                dataTextStyle: TextStyle(fontSize: 12, color: Tema.textDark),
                columns: const [
                  DataColumn(label: Text('Nombre')),
                  DataColumn(label: Text('Stock'), numeric: true),
                  DataColumn(label: Text('P.Compra'), numeric: true),
                  DataColumn(label: Text('P.Venta'), numeric: true),
                  DataColumn(label: Text('Margen'), numeric: true),
                  DataColumn(label: Text('Valor Total'), numeric: true),
                ],
                rows: sorted.map((p) {
                  final st = (p['stock_actual'] as num?)?.toInt() ?? 0;
                  final pc = (p['precio_compra'] as num?)?.toInt() ?? 0;
                  final pv = (p['precio_venta'] as num?)?.toInt() ?? 0;
                  final margen = pc > 0 ? ((pv - pc) / pc * 100).toStringAsFixed(0) : '0';
                  final valTotal = st * pv;
                  final stockColor = st <= 0 ? Tema.danger : st <= (p['stock_minimo'] ?? 5) ? Colors.orange : Tema.textDark;
                  return DataRow(cells: [
                    DataCell(Text(p['nombre'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(Text('$st', style: TextStyle(color: stockColor, fontWeight: FontWeight.w600))),
                    DataCell(Text(Fb.formatMoney(pc))),
                    DataCell(Text(Fb.formatMoney(pv))),
                    DataCell(Text('$margen%')),
                    DataCell(Text(Fb.formatMoney(valTotal), style: const TextStyle(fontWeight: FontWeight.w600))),
                  ]);
                }).toList(),
              ),
            ),
          ),
      ]),
    );
  }

  // ═══════════════════════ FIADOS ═══════════════════════

  List<Map<String, dynamic>> _deudoresList() {
    final pendientes = _fiadosRango.where((f) => (f['estado'] ?? '') != 'Pagado').toList();
    final Map<String, Map<String, dynamic>> deudores = {};
    for (final f in pendientes) {
      final nombre = (f['cliente_nombre'] ?? 'Sin nombre').toString();
      deudores.putIfAbsent(nombre, () => {'nombre': nombre, 'total': 0, 'activos': 0, 'telefono': f['cliente_telefono'] ?? ''});
      final saldo = (f['saldo'] as num?)?.toInt() ?? (f['monto_pendiente'] as num?)?.toInt() ?? 0;
      deudores[nombre]!['total'] = (deudores[nombre]!['total'] as int) + saldo;
      deudores[nombre]!['activos'] = (deudores[nombre]!['activos'] as int) + 1;
    }
    final list = deudores.values.toList();
    list.sort((a, b) => (b['total'] as int).compareTo(a['total'] as int));
    return list;
  }

  Widget _buildFiadosTab() {
    final fia = _fiadosRango;
    final pendientes = fia.where((f) => (f['estado'] ?? '') != 'Pagado').toList();
    final pagados = fia.where((f) => (f['estado'] ?? '') == 'Pagado').toList();
    int deudaTotal = 0;
    int abonos = 0;
    for (final f in fia) {
      final saldo = (f['saldo'] as num?)?.toInt() ?? (f['monto_pendiente'] as num?)?.toInt() ?? 0;
      deudaTotal += saldo;
      abonos += (f['abonos'] as num?)?.toInt() ?? (f['total_abonos'] as num?)?.toInt() ?? 0;
    }
    final deudores = _deudoresList();

    return SingleChildScrollView(
      child: Column(children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          _kpi('Deuda Total', Fb.formatMoney(deudaTotal), Icons.money_off, Tema.kpiAccents[0], Tema.kpiBgs[0]),
          _kpi('Pendientes', '${pendientes.length}', Icons.pending, Tema.kpiAccents[1], Tema.kpiBgs[1]),
          _kpi('Pagados', '${pagados.length}', Icons.check_circle, Tema.kpiAccents[2], Tema.kpiBgs[2]),
          _kpi('Abonos', Fb.formatMoney(abonos), Icons.payments, Tema.kpiAccents[3], Tema.kpiBgs[3]),
        ]),
        SizedBox(height: 14),
        if (deudores.isEmpty)
          _empty('Sin deudas pendientes')
        else ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Text('Deudores', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Tema.textDark)),
          ),
          ...deudores.map((d) {
            final total = d['total'] as int;
            final activos = d['activos'] as int;
            return Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Container(
                decoration: Tema.cardDeco,
                padding: EdgeInsets.all(14),
                child: Row(children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(color: Tema.danger.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Tema.radiusSm)),
                    child: const Icon(Icons.person, color: Tema.danger, size: 22),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(d['nombre'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Tema.textDark)),
                      SizedBox(height: 2),
                      Text('$activos fia.', style: TextStyle(fontSize: 11, color: Tema.textSoft)),
                    ]),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(Fb.formatMoney(total), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Tema.danger)),
                    Text('pendiente', style: TextStyle(fontSize: 10, color: Tema.textMuted)),
                  ]),
                ]),
              ),
            );
          }),
        ],
      ]),
    );
  }

  // ═══════════════════════ CAJA ═══════════════════════

  int _cajaIng(Map<dynamic, dynamic> c) =>
      (c['movimientos'] as List? ?? []).where((m) => m['tipo'] == 'ingreso').fold<int>(0, (s, m) => s + ((m['monto'] as num?)?.toInt() ?? 0));

  int _cajaEgr(Map<dynamic, dynamic> c) =>
      (c['movimientos'] as List? ?? []).where((m) => m['tipo'] != 'ingreso').fold<int>(0, (s, m) => s + ((m['monto'] as num?)?.toInt() ?? 0));

  Widget _buildCajaTab() {
    final cf = _cajasFiltradas;
    int totalIng = 0;
    int totalEgr = 0;
    int totalMov = 0;
    for (final c in cf) {
      totalIng += _cajaIng(c);
      totalEgr += _cajaEgr(c);
      totalMov += (c['movimientos'] as List? ?? []).length;
    }
    final balance = totalIng - totalEgr;

    final allMovs = <Map<String, dynamic>>[];
    for (final c in cf) {
      for (final m in (c['movimientos'] as List? ?? [])) {
        allMovs.add({
          ...Map<String, dynamic>.from(m as Map),
          'caja_id': c['id'],
        });
      }
    }
    allMovs.sort((a, b) => (b['fecha'] ?? '').toString().compareTo((a['fecha'] ?? '').toString()));

    // Summary by tipo
    final byTipo = <String, int>{};
    for (final m in allMovs) {
      final t = m['tipo']?.toString() ?? 'otro';
      byTipo[t] = (byTipo[t] ?? 0) + ((m['monto'] as num?)?.toInt() ?? 0);
    }

    return SingleChildScrollView(
      child: Column(children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          _kpi('Ingresos', Fb.formatMoney(totalIng), Icons.arrow_downward, Tema.kpiAccents[0], Tema.kpiBgs[0]),
          _kpi('Egresos', Fb.formatMoney(totalEgr), Icons.arrow_upward, Tema.kpiAccents[1], Tema.kpiBgs[1]),
          _kpi('Balance', Fb.formatMoney(balance), Icons.account_balance_wallet, Tema.kpiAccents[2], Tema.kpiBgs[2]),
          _kpi('Movimientos', '$totalMov', Icons.swap_horiz, Tema.kpiAccents[3], Tema.kpiBgs[3]),
        ]),
        if (byTipo.isNotEmpty) ...[
          SizedBox(height: 14),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Text('Resumen por Tipo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Tema.textDark)),
          ),
          SizedBox(height: 4),
          Container(
            decoration: Tema.cardDeco,
            padding: EdgeInsets.all(10),
            child: Column(children: byTipo.entries.map((e) {
              final color = e.key == 'ingreso' ? Tema.primary : Tema.danger;
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 5),
                child: Row(children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
                  SizedBox(width: 8),
                  Expanded(child: Text(e.key, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Tema.textDark))),
                  Text(Fb.formatMoney(e.value), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
                ]),
              );
            }).toList()),
          ),
        ],
        SizedBox(height: 14),
        if (cf.isEmpty)
          _empty('Sin cajas en este rango')
        else ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Text('Cajas (${cf.length})', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Tema.textDark)),
          ),
          ...cf.map((c) {
            final ing = _cajaIng(c);
            final egr = _cajaEgr(c);
            final b = ing - egr;
            final estado = (c['estado'] as String?) ?? 'cerrada';
            return Container(
              margin: EdgeInsets.only(bottom: 8),
              decoration: Tema.cardDeco,
              padding: EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Caja #${c['id']}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Tema.textDark)),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (estado == 'abierta' ? Tema.primary : Tema.textMuted).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(estado, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: estado == 'abierta' ? Tema.primary : Tema.textMuted)),
                  ),
                ]),
                SizedBox(height: 8),
                Row(children: [
                  _statMini('Ingresos', Fb.formatMoney(ing), Tema.primary),
                  SizedBox(width: 12),
                  _statMini('Egresos', Fb.formatMoney(egr), Tema.danger),
                  SizedBox(width: 12),
                  _statMini('Balance', Fb.formatMoney(b), Tema.darkBlue),
                  SizedBox(width: 12),
                  _statMini('Movs.', '${(c['movimientos'] as List? ?? []).length}', Tema.textSoft),
                ]),
              ]),
            );
          }),
        ],
      ]),
    );
  }

  Widget _statMini(String label, String value, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 10, color: Tema.textMuted)),
      SizedBox(height: 2),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
    ]);
  }

  // ═══════════════════════ DISTRIBUCIONES ═══════════════════════

  Widget _buildDistribucionesTab() {
    final dis = _distribucionesRango;
    int totalDist = 0;
    final catsSet = <String>{};
    for (final d in dis) {
      totalDist += ((d['total'] as num?)?.toInt() ?? 0);
      for (final c in ((d['categorias'] as List?) ?? (d['items'] as List?) ?? [])) {
        catsSet.add((c['nombre'] ?? '').toString());
      }
    }
    final prom = dis.isEmpty ? 0 : totalDist ~/ dis.length;

    return SingleChildScrollView(
      child: Column(children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          _kpi('Total Distrib.', Fb.formatMoney(totalDist), Icons.pie_chart, Tema.kpiAccents[0], Tema.kpiBgs[0]),
          _kpi('Categorias', '${catsSet.length}', Icons.category, Tema.kpiAccents[1], Tema.kpiBgs[1]),
          _kpi('Promedio', Fb.formatMoney(prom), Icons.bar_chart, Tema.kpiAccents[2], Tema.kpiBgs[2]),
          _kpi('Distrib.', '${dis.length}', Icons.history, Tema.kpiAccents[3], Tema.kpiBgs[3]),
        ]),
        SizedBox(height: 14),
        if (dis.isEmpty)
          _empty('Sin distribuciones en este rango')
        else ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Text('Historial (${dis.length})', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Tema.textDark)),
          ),
          ...dis.map((d) {
            final fecha = _fmtDateShort((d['fecha'] ?? '').toString());
            final total = ((d['total'] as num?)?.toInt() ?? 0);
            final cats = ((d['categorias'] as List?) ?? (d['items'] as List?) ?? []).cast<Map>();
            return Container(
              margin: EdgeInsets.only(bottom: 8),
              decoration: Tema.cardDeco,
              padding: EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(fecha, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Tema.textDark)),
                  Text(Fb.formatMoney(total), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Tema.primary)),
                ]),
                if (cats.isNotEmpty) ...[
                  SizedBox(height: 8),
                  ...cats.map((c) => Padding(
                    padding: EdgeInsets.only(bottom: 3),
                    child: Row(children: [
                      const Icon(Icons.circle, size: 6, color: Tema.primary),
                      SizedBox(width: 8),
                      Expanded(child: Text((c['nombre'] ?? '').toString(), style: TextStyle(fontSize: 12, color: Tema.textDark))),
                      Text('${((c['porcentaje'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)}%', style: TextStyle(fontSize: 11, color: Tema.textMuted)),
                      SizedBox(width: 12),
                      Text(Fb.formatMoney(c['monto'] ?? 0), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Tema.primary)),
                    ]),
                  )),
                ],
              ]),
            );
          }),
        ],
      ]),
    );
  }

  // ═══════════════════════ GANANCIA NETA ═══════════════════════

  Map<String, Map<String, int>> _monthlyBreakdown() {
    final map = <String, Map<String, int>>{};
    for (final c in _cajasFiltradas) {
      final fecha = _parseFecha(c['fecha_apertura']);
      if (fecha == null) continue;
      final key = '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}';
      map.putIfAbsent(key, () => {'ingresos': 0, 'egresos': 0, 'neta': 0});
      final ing = _cajaIng(c);
      final egr = _cajaEgr(c);
      map[key]!['ingresos'] = map[key]!['ingresos']! + ing;
      map[key]!['egresos'] = map[key]!['egresos']! + egr;
      map[key]!['neta'] = map[key]!['neta']! + ing - egr;
    }
    return map;
  }

  Widget _buildGananciaNetaTab() {
    final mb = _monthlyBreakdown();
    final months = mb.entries.toList()..sort((a, b) => b.key.compareTo(a.key));

    int totalIng = 0;
    int totalEgr = 0;
    for (final e in months) {
      totalIng += e.value['ingresos']!;
      totalEgr += e.value['egresos']!;
    }
    final totalNeta = totalIng - totalEgr;
    final margenN = totalIng > 0 ? (totalNeta / totalIng * 100).toStringAsFixed(1) : '0.0';

    final chartData = months.map((e) => MapEntry(e.key, e.value['neta']!)).toList();

    return SingleChildScrollView(
      child: Column(children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          _kpi('Ingresos Tot.', Fb.formatMoney(totalIng), Icons.trending_up, Tema.kpiAccents[0], Tema.kpiBgs[0]),
          _kpi('Egresos Tot.', Fb.formatMoney(totalEgr), Icons.trending_down, Tema.kpiAccents[1], Tema.kpiBgs[1]),
          _kpi('Ganancia Neta', Fb.formatMoney(totalNeta), Icons.savings, Tema.kpiAccents[2], Tema.kpiBgs[2]),
          _kpi('Margen Neto', '$margenN%', Icons.percent, Tema.kpiAccents[3], Tema.kpiBgs[3]),
        ]),
        SizedBox(height: 14),
        if (chartData.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Text('Ganancia Neta por Mes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Tema.textDark)),
          ),
          _barChart(chartData, totalNeta >= 0 ? Tema.kpiAccents[0] : Tema.danger),
          SizedBox(height: 10),
        ],
        if (months.isEmpty)
          _empty('Sin datos de cajas en este rango')
        else ...[
          Container(
            decoration: Tema.cardDeco,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 14,
                headingTextStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Tema.textSoft),
                dataTextStyle: TextStyle(fontSize: 12, color: Tema.textDark),
                columns: const [
                  DataColumn(label: Text('Mes')),
                  DataColumn(label: Text('Ingresos'), numeric: true),
                  DataColumn(label: Text('Egresos'), numeric: true),
                  DataColumn(label: Text('Gan. Neta'), numeric: true),
                  DataColumn(label: Text('% Ingreso'), numeric: true),
                ],
                rows: months.map((e) {
                  final d = e.value;
                  final neta = d['neta']!;
                  final ing = d['ingresos']!;
                  final pct = ing > 0 ? (neta / ing * 100).toStringAsFixed(1) : '0.0';
                  return DataRow(cells: [
                    DataCell(Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(Text(Fb.formatMoney(ing))),
                    DataCell(Text(Fb.formatMoney(d['egresos']!))),
                    DataCell(Text(Fb.formatMoney(neta), style: TextStyle(color: neta >= 0 ? Tema.primary : Tema.danger, fontWeight: FontWeight.w600))),
                    DataCell(Text('$pct%')),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ]),
    );
  }

  // ═══════════════════════ BAR CHART ═══════════════════════

  Widget _barChart(List<MapEntry<String, int>> data, Color color) {
    if (data.isEmpty) return const SizedBox.shrink();
    final maxVal = data.map((e) => e.value).reduce((a, b) => a > b ? a : b).toDouble();
    if (maxVal <= 0) return const SizedBox.shrink();

    final display = data.length > 12 ? data.sublist(0, 12) : data;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8),
      padding: EdgeInsets.fromLTRB(8, 12, 8, 6),
      decoration: Tema.cardDeco,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          height: 130,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: display.map((e) {
              final barH = ((e.value / maxVal) * 80).clamp(3.0, 80.0);
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          Fb.formatMoney(e.value),
                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: color),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(height: 1),
                      Container(
                        height: barH,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.7),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                        ),
                      ),
                      SizedBox(height: 3),
                      SizedBox(
                        height: 22,
                        child: Text(
                          e.key.length > 5 ? e.key.substring(5) : e.key,
                          style: TextStyle(fontSize: 8, color: Tema.textMuted),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }

  // ═══════════════════════ CONSUMOS ═══════════════════════

  Widget _buildConsumosTab() {
    final filtrados = _filtroAutoconsumos;
    int totalUnids = 0;
    double costoTotal = 0;
    final Map<String, Map<String, dynamic>> porProducto = {};

    for (final c in filtrados) {
      final cant = (c['cantidad'] is num ? c['cantidad'] as num : num.tryParse((c['cantidad'] ?? '0').toString()) ?? 0).toInt();
      totalUnids += cant;
      final prodMatches = _productos.where((p) => p['id']?.toString() == c['producto_id']?.toString());
      final prod = prodMatches.isNotEmpty ? prodMatches.first : null;
      final pc = prod != null ? ((prod['precio_compra'] is num ? prod['precio_compra'] as num : num.tryParse((prod['precio_compra'] ?? '0').toString()) ?? 0).toDouble()) : 0.0;
      final costo = cant * pc;
      costoTotal += costo;
      final nombre = (c['producto_nombre'] ?? 'Sin nombre').toString();
      porProducto.update(nombre, (v) { v['cantidad'] += cant; v['costo'] += costo; return v; }, ifAbsent: () => {'nombre': nombre, 'cantidad': cant, 'costo': costo});
    }

    final top = porProducto.values.toList()..sort((a, b) => (b['cantidad'] as int).compareTo(a['cantidad'] as int));

    return ListView(
      padding: EdgeInsets.all(12),
      children: [
        Row(children: [
          Expanded(child: Tema.kpiCard('Unidades Cons.', '$totalUnids', Icons.inventory_2, accent: Tema.primary)),
          SizedBox(width: 8),
          Expanded(child: Tema.kpiCard('Costo Total', Fb.formatMoney(costoTotal), Icons.attach_money, accent: Tema.danger)),
          SizedBox(width: 8),
          Expanded(child: Tema.kpiCard('Registros', '${filtrados.length}', Icons.receipt_long, accent: const Color(0xFF1565c0))),
        ]),
        if (top.isNotEmpty) ...[
          SizedBox(height: 12),
          Text('Productos mas consumidos', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Tema.textDark)),
          SizedBox(height: 8),
          ...top.take(15).map((p) => Card(
            child: ListTile(
              title: Text(p['nombre'], style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${p['cantidad']} unids.', style: TextStyle(color: Tema.textSoft)),
              trailing: Text(Fb.formatMoney(p['costo']), style: TextStyle(fontWeight: FontWeight.w700, color: Tema.danger)),
            ),
          )),
        ],
      ],
    );
  }

  // ═══════════════════════ HELPERS ═══════════════════════

  Widget _kpi(String label, String value, IconData icon, Color accent, Color bgTint) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 28) / 2,
      child: Tema.kpiCard(label, value, icon, accent: accent, bgTint: bgTint),
    );
  }

  Widget _empty(String msg) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 40),
      padding: EdgeInsets.all(24),
      decoration: Tema.cardDeco,
      child: Column(children: [
        Icon(Icons.inbox, size: 40, color: Tema.textMuted),
        SizedBox(height: 8),
        Text(msg, style: TextStyle(fontSize: 13, color: Tema.textMuted)),
      ]),
    );
  }
}