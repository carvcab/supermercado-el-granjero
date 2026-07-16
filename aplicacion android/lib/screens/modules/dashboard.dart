import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../services/notifications.dart';
import '../../services/session_service.dart';
import '../../theme.dart';

class DashScreen extends StatefulWidget {
  const DashScreen({super.key});
  @override
  State<DashScreen> createState() => _DashScreenState();
}

class _DashScreenState extends State<DashScreen> {
  List<Map<dynamic, dynamic>> _productos = [];
  List<Map<dynamic, dynamic>> _ventas = [];
  List<Map<dynamic, dynamic>> _clientes = [];
  Map<dynamic, dynamic>? _cajaAbierta;
  bool _loading = true;
  bool _notifiedStock = false;

  StreamSubscription? _subP;
  StreamSubscription? _subV;
  StreamSubscription? _subC;
  StreamSubscription? _subCj;

  @override
  void initState() {
    super.initState();
    _subP = Fb.stream('productos').listen((d) {
      setState(() => _productos = d);
      if (!_notifiedStock && d.isNotEmpty) {
        _notifiedStock = true;
        final bajo = d.where((p) => (p['stock_actual'] ?? 0) <= (p['stock_minimo'] ?? 5)).toList();
        if (bajo.isNotEmpty) {
          Notif.show('Alerta de Stock', 'Atención: ${bajo.length} productos con stock bajo o agotados');
        }
      }
    });
    _subV = Fb.stream('ventas').listen((d) => setState(() => _ventas = d));
    _subC = Fb.stream('clientes').listen((d) => setState(() => _clientes = d));
    _subCj = Fb.stream('cajas').listen((d) {
      setState(() {
        _cajaAbierta = d.isNotEmpty && d.last['estado'] == 'abierta' ? d.last : null;
        _loading = false;
      });
    });
  }

  @override
  void dispose() {
    _subP?.cancel();
    _subV?.cancel();
    _subC?.cancel();
    _subCj?.cancel();
    super.dispose();
  }

  String get _hoy => DateTime.now().toIso8601String().substring(0, 10);

  String get _mes {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}';
  }

  List<Map<dynamic, dynamic>> get _vh =>
      _ventas.where((v) => (v['fecha'] ?? '').toString().startsWith(_hoy)).toList();

  double get _totalVm =>
      _ventas.where((v) => (v['fecha'] ?? '').toString().startsWith(_mes)).fold(0.0, (s, v) => s + ((v['total'] as num?)?.toDouble() ?? 0));

  double get _gananciasHoy {
    double g = 0;
    for (var v in _vh) {
      final t = (v['total'] as num?)?.toDouble() ?? 0;
      double c = 0;
      for (var p in (v['productos'] as List? ?? [])) {
        c += ((p['cantidad'] as num?)?.toDouble() ?? 0) * ((p['precio_compra'] as num?)?.toDouble() ?? 0);
      }
      g += t - c;
    }
    return g;
  }

  int get _deudores =>
      _clientes.where((c) => ((c['saldo_pendiente'] ?? 0) as num) > 0).length;

  double get _valorInv =>
      _productos.fold(0.0, (s, p) => s + ((p['stock_actual'] ?? 0) as num) * ((p['precio_venta'] ?? 0) as num));

  List<Map<dynamic, dynamic>> get _stockBajo =>
      _productos.where((p) => (p['stock_actual'] ?? 0) <= (p['stock_minimo'] ?? 5)).toList();

  double get _cajaBalance {
    if (_cajaAbierta == null) return 0;
    final ini = (_cajaAbierta!['monto_inicial'] as num?)?.toDouble() ?? 0;
    double ing = 0, egr = 0;
    for (var m in (_cajaAbierta!['movimientos'] as List? ?? [])) {
      final mt = (m['monto'] as num?)?.toDouble() ?? 0;
      if (m['tipo'] == 'ingreso') { ing += mt; } else { egr += mt; }
    }
    return ini + ing - egr;
  }

  double get _ingresos {
    if (_cajaAbierta == null) return 0;
    return (_cajaAbierta!['movimientos'] as List? ?? [])
        .where((m) => m['tipo'] == 'ingreso')
        .fold(0.0, (s, m) => s + ((m['monto'] as num?)?.toDouble() ?? 0));
  }

  double get _egresos {
    if (_cajaAbierta == null) return 0;
    return (_cajaAbierta!['movimientos'] as List? ?? [])
        .where((m) => m['tipo'] != 'ingreso')
        .fold(0.0, (s, m) => s + ((m['monto'] as num?)?.toDouble() ?? 0));
  }

  List<Map<dynamic, dynamic>> get _recentSales {
    final sorted = List<Map<dynamic, dynamic>>.from(_ventas);
    sorted.sort((a, b) => (b['fecha'] ?? '').compareTo(a['fecha'] ?? ''));
    return sorted.take(5).toList();
  }

  List<Map<String, dynamic>> get _ventasPorDia {
    final now = DateTime.now();
    const dias = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];
    final result = <Map<String, dynamic>>[];
    for (var i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final ventasDia = _ventas.where((v) => (v['fecha'] ?? '').toString().startsWith(key)).toList();
      final total = ventasDia.fold(0.0, (s, v) => s + ((v['total'] as num?)?.toDouble() ?? 0));
      result.add({'dia': dias[d.weekday - 1], 'total': total, 'ventas': ventasDia.length});
    }
    return result;
  }

  List<Map<String, dynamic>> get _topProductos {
    final counts = <String, int>{};
    for (var v in _ventas) {
      for (var p in (v['productos'] as List? ?? [])) {
        final name = p['nombre'] ?? 'Sin nombre';
        counts[name] = (counts[name] ?? 0) + ((p['cantidad'] as num?)?.toInt() ?? 1);
      }
    }
    final sorted = counts.entries.map((e) => <String, dynamic>{'nombre': e.key, 'cantidad': e.value}).toList();
    sorted.sort((a, b) => (b['cantidad'] as int).compareTo(a['cantidad'] as int));
    return sorted.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Center(child: CircularProgressIndicator());

    return ListView(
      padding: EdgeInsets.all(12),
      children: [
        _buildWelcomeCard(),
        SizedBox(height: 10),
        _buildKpiGrid(),
        SizedBox(height: 10),
        _buildVentasSemana(),
        SizedBox(height: 10),
        _buildTopProductos(),
        SizedBox(height: 10),
        _buildQuickStats(),
        SizedBox(height: 10),
        _buildWalletCard(),
        SizedBox(height: 10),
        if (_stockBajo.isNotEmpty) ...[
          _buildLowStock(),
          SizedBox(height: 10),
        ],
        _buildRecentSales(),
      ],
    );
  }

  Widget _buildWelcomeCard() {
    final displayName = Session.nombreCompleto ?? Session.username ?? 'Usuario';
    final userRole = Session.rol;
    final userPhoto = Session.foto;
    final n = DateTime.now();
    final hora = n.hour;
    final saludo = hora < 12 ? 'Buenos días' : hora < 18 ? 'Buenas tardes' : 'Buenas noches';
    const meses = ['Enero','Febrero','Marzo','Abril','Mayo','Junio','Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'];
    const dias = ['Lunes','Martes','Miercoles','Jueves','Viernes','Sabado','Domingo'];
    final dateStr = '${dias[n.weekday - 1]}, ${n.day} de ${meses[n.month - 1]}';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    ImageProvider? photoProvider;
    if (userPhoto != null && userPhoto.startsWith('data:')) {
      photoProvider = MemoryImage(base64Decode(userPhoto.split(',')[1]));
    } else if (userPhoto != null && userPhoto.startsWith('http')) {
      photoProvider = NetworkImage(userPhoto);
    }

    return Container(
      decoration: BoxDecoration(
        gradient: Tema.headerGradient,
        borderRadius: BorderRadius.circular(Tema.radius),
        boxShadow: [Tema.shadowMd],
      ),
      padding: EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            backgroundImage: photoProvider,
            child: photoProvider == null
                ? Text(initial, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white))
                : null,
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$saludo,', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.8))),
                Row(
                  children: [
                    Flexible(
                      child: Text(displayName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    if (userRole != null) ...[
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(userRole, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 2),
                Text(dateStr, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.0,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        Tema.kpiCard('Ventas Hoy', '${_vh.length}', Icons.shopping_cart_rounded, accent: Tema.kpiAccents[3], bgTint: Tema.kpiBgs[3]),
        Tema.kpiCard('Ventas Mes', Fb.formatMoney(_totalVm), Icons.trending_up, accent: Tema.kpiAccents[1], bgTint: Tema.kpiBgs[1]),
        Tema.kpiCard('Ganancias Hoy', Fb.formatMoney(_gananciasHoy), Icons.savings_rounded, accent: Tema.kpiAccents[0], bgTint: Tema.kpiBgs[0]),
        Tema.kpiCard('Deudores Activos', '$_deudores', Icons.people_rounded, accent: Tema.danger, bgTint: Tema.kpiBgs[2]),
        Tema.kpiCard('Valor Inventario', Fb.formatMoney(_valorInv), Icons.inventory_2_rounded, accent: Tema.kpiAccents[2], bgTint: Tema.kpiBgs[0]),
        Tema.kpiCard('Stock Bajo', '${_stockBajo.length}', Icons.warning_amber_rounded, accent: Tema.danger, bgTint: Tema.kpiBgs[2]),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(child: _stat('Productos', '${_productos.length}', Icons.inventory_rounded, Tema.kpiBgs[1], Tema.kpiAccents[1])),
        SizedBox(width: 10),
        Expanded(child: _stat('Clientes', '${_clientes.length}', Icons.group_rounded, Tema.kpiBgs[0], Tema.kpiAccents[0])),
        SizedBox(width: 10),
        Expanded(child: _stat('Caja', _cajaAbierta != null ? 'Abierta' : 'Cerrada', Icons.account_balance_rounded,
          _cajaAbierta != null ? Tema.kpiBgs[2] : Tema.kpiBgs[3],
          _cajaAbierta != null ? Tema.danger : Tema.textMuted)),
      ],
    );
  }

  Widget _stat(String label, String val, IconData icon, Color bg, Color accent) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Tema.radius),
        border: Border.all(color: Tema.cardBorder),
      ),
      padding: EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 22),
          SizedBox(height: 8),
          Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accent)),
          Text(label, style: TextStyle(fontSize: 10, color: Tema.textSoft)),
        ],
      ),
    );
  }

  Widget _buildWalletCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Tema.darkBlue, Color(0xFF0a4a7a)]),
        borderRadius: BorderRadius.circular(Tema.radius),
        boxShadow: [Tema.shadowMd],
      ),
      padding: EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(Tema.radiusSm),
                ),
                child: Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 24),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _cajaAbierta != null ? 'Caja Abierta' : 'Caja Cerrada',
                    style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                  ),
                  Text(
                    _cajaAbierta != null ? 'Balance actual' : 'Abra caja para iniciar operaciones',
                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5)),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                Fb.formatMoney(_cajaBalance),
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ],
          ),
          if (_cajaAbierta != null) ...[
            SizedBox(height: 12),
            Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.15),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _walletItem('Fondo', Fb.formatMoney((_cajaAbierta!['monto_inicial'] as num?)?.toDouble() ?? 0)),
                _walletItem('Ingresos', Fb.formatMoney(_ingresos)),
                _walletItem('Egresos', Fb.formatMoney(_egresos)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _walletItem(String label, String val) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.9))),
        SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.5))),
      ],
    );
  }

  Widget _buildLowStock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Tema.danger, size: 20),
            SizedBox(width: 8),
            Text('Stock Bajo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Tema.danger)),
            const Spacer(),
            Text('${_stockBajo.length} productos', style: TextStyle(fontSize: 12, color: Tema.textMuted)),
          ],
        ),
        SizedBox(height: 8),
        Container(
          decoration: Tema.cardDeco,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: _stockBajo.take(5).map((p) {
              final nombre = p['nombre'] ?? 'Sin nombre';
              final sa = (p['stock_actual'] ?? 0) as num;
              final sm = (p['stock_minimo'] ?? 5) as num;
              return Container(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Tema.cardBorder.withValues(alpha: 0.5))),
                ),
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(nombre, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Tema.textDark)),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Tema.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$sa / $sm',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Tema.danger),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildVentasSemana() {
    final datos = _ventasPorDia;
    final maximo = datos.isEmpty ? 1.0 : datos.map((d) => (d['total'] as double)).reduce(max);
    const colores = [Color(0xFF1b4d3e), Color(0xFF2c5e43), Color(0xFF3d6f54), Color(0xFF4e8065), Color(0xFFb8860b), Color(0xFF3b5998), Color(0xFFd4a017)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.bar_chart_rounded, color: Tema.primary, size: 20),
            SizedBox(width: 8),
            Text('Ventas de la Semana', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Tema.textDark)),
          ],
        ),
        SizedBox(height: 8),
        Container(
          decoration: Tema.cardDeco,
          padding: EdgeInsets.all(12),
          child: Column(
            children: datos.asMap().entries.map((e) {
              final idx = e.key;
              final d = e.value;
              final total = d['total'] as double;
              final ancho = maximo > 0 ? total / maximo : 0.0;
              final color = colores[idx % colores.length];
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(width: 32, child: Text(d['dia'] as String, style: TextStyle(fontSize: 11, color: Tema.textMuted))),
                    SizedBox(width: 4),
                    Expanded(
                      child: Stack(
                        children: [
                          Container(height: 22, decoration: BoxDecoration(color: Tema.cardBorder.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(6))),
                          FractionallySizedBox(
                            widthFactor: ancho.clamp(0.0, 1.0),
                            child: Container(height: 22, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6))),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    SizedBox(width: 50, child: Text(Fb.formatMoney(total), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Tema.textDark))),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTopProductos() {
    final datos = _topProductos;
    if (datos.isEmpty) return const SizedBox.shrink();
    final maximo = datos.first['cantidad'] as int;
    final colores = [Tema.kpiAccents[1], Tema.kpiAccents[0], Tema.kpiAccents[3], Tema.kpiAccents[2], Tema.primary];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.star_rounded, color: Tema.primary, size: 20),
            SizedBox(width: 8),
            Text('Más Vendidos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Tema.textDark)),
          ],
        ),
        SizedBox(height: 8),
        Container(
          decoration: Tema.cardDeco,
          padding: EdgeInsets.all(12),
          child: Column(
            children: datos.asMap().entries.map((e) {
              final idx = e.key;
              final p = e.value;
              final nombre = p['nombre'] as String;
              final cantidad = p['cantidad'] as int;
              final ancho = maximo > 0 ? cantidad / maximo : 0.0;
              final color = colores[idx % colores.length];
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(width: 20, child: Text('${idx + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color))),
                    SizedBox(width: 8),
                    Expanded(
                      child: Stack(
                        children: [
                          Container(height: 22, decoration: BoxDecoration(color: Tema.cardBorder.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(6))),
                          FractionallySizedBox(
                            widthFactor: ancho.clamp(0.0, 1.0),
                            child: Container(
                              height: 22,
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              alignment: Alignment.centerLeft,
                              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
                              child: Text(nombre, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    Text('$cantidad', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentSales() {
    if (_recentSales.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.receipt_long_rounded, color: Tema.primary, size: 20),
            SizedBox(width: 8),
            Text('Ventas Recientes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Tema.textDark)),
          ],
        ),
        SizedBox(height: 8),
        Container(
          decoration: Tema.cardDeco,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: _recentSales.map((v) {
              final cliente = v['cliente'] ?? 'Sin cliente';
              final total = (v['total'] ?? 0) as num;
              final fecha = v['fecha'] ?? '';
              final items = v['productos'] is List ? (v['productos'] as List).length : 0;

              return Container(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Tema.cardBorder.withValues(alpha: 0.5))),
                ),
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Tema.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.receipt_long_rounded, color: Tema.primary, size: 18),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cliente, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Tema.textDark)),
                          SizedBox(height: 2),
                          Text('$fecha  ·  $items items', style: TextStyle(fontSize: 11, color: Tema.textMuted)),
                        ],
                      ),
                    ),
                    Text(
                      Fb.formatMoney(total),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Tema.primary),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}


