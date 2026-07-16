import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import '../theme.dart';
import '../services/session_service.dart';
import 'modules/dashboard.dart';
import 'modules/caja.dart';
import 'modules/pos.dart';
import 'modules/inventario.dart';
import 'modules/clientes.dart';
import 'modules/ventas_bar.dart';
import 'modules/proveedores.dart';
import 'modules/fiados.dart';
import 'modules/historial.dart';
import 'modules/compras.dart';
import 'modules/compras_programadas.dart';
import 'modules/categorias.dart';
import 'modules/reportes.dart';
import 'modules/cierres.dart';
import 'modules/distribuciones.dart';
import 'modules/configuracion.dart';
import 'modules/usuarios.dart';
import 'modules/facturacion.dart';
import 'modules/consumos.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  // Permission: [pageName, permisoKey]
  static const _itemPerms = [
    'dashboard',     // Dashboard
    'caja',          // Caja
    'ventas_super',  // Ventas Super
    'ventas_bar',    // Ventas Bar
    'facturacion',   // Facturación
    'consumos',      // Consumos Propios
    'historial_ventas', // Historial
    'fiados',        // Fiados
    'productos',     // Inventario
    'compras',       // Compras
    'compras_programadas', // Compras Prog.
    'categorias',    // Categorías
    'distribuciones', // Distribuciones
    'clientes',      // Clientes
    'proveedores',   // Proveedores
    'usuarios',      // Usuarios
    'reportes',      // Reportes
    'cierres',       // Cierres
    'configuracion', // Configuración
  ];

  static const _items = [
    ['Dashboard', Icons.dashboard_rounded, DashScreen()],
    ['Caja', Icons.account_balance_rounded, CajaScreen()],
    ['Ventas Super', Icons.shopping_cart_rounded, PosScreen()],
    ['Ventas Bar', Icons.local_bar_rounded, BarScreen()],
    ['Facturación', Icons.receipt_rounded, FacScreen()],
    ['Consumos', Icons.person_off, ConsScreen()],
    ['Historial', Icons.receipt_long_rounded, HistScreen()],
    ['Fiados', Icons.payments_rounded, FiaScreen()],
    ['Inventario', Icons.inventory_rounded, InvScreen()],
    ['Compras', Icons.shopping_bag_rounded, CompScreen()],
    ['Compras Prog.', Icons.calendar_month_rounded, CprScreen()],
    ['Categorías', Icons.category_rounded, CatScreen()],
    ['Distribuciones', Icons.account_balance_wallet_rounded, DisScreen()],
    ['Clientes', Icons.people_rounded, CliScreen()],
    ['Proveedores', Icons.business_rounded, ProvScreen()],
    ['Usuarios', Icons.admin_panel_settings_rounded, UsuScreen()],
    ['Reportes', Icons.bar_chart_rounded, RepScreen()],
    ['Cierres', Icons.lock_rounded, CieScreen()],
    ['Configuración', Icons.settings_rounded, ConScreen()],
  ];

  List<List> _filteredItems() {
    return List.generate(_items.length, (i) => i)
        .where((i) => Session.tienePermiso(_itemPerms[i]))
        .map((i) => _items[i])
        .toList();
  }

  Map<int, int> _filteredIndexMap() {
    final map = <int, int>{};
    int pos = 0;
    for (int i = 0; i < _items.length; i++) {
      if (Session.tienePermiso(_itemPerms[i])) {
        map[i] = pos;
        pos++;
      }
    }
    return map;
  }

  List<Map> _filteredGroups() {
    final result = <Map>[];
    for (final group in _groups) {
      final filtered = (group['items'] as List).where((item) {
        final itemIdx = _items.indexOf(item);
        return itemIdx >= 0 && Session.tienePermiso(_itemPerms[itemIdx]);
      }).toList();
      if (filtered.isNotEmpty) {
        result.add({'title': group['title'], 'items': filtered});
      }
    }
    return result;
  }

  static const _groups = [
    {
      'title': 'Principal',
      'items': [
        ['Dashboard', Icons.dashboard_rounded, DashScreen()],
        ['Caja', Icons.account_balance_rounded, CajaScreen()],
      ],
    },
    {
      'title': 'Ventas',
      'items': [
        ['Ventas Super', Icons.shopping_cart_rounded, PosScreen()],
        ['Ventas Bar', Icons.local_bar_rounded, BarScreen()],
        ['Facturación', Icons.receipt_rounded, FacScreen()],
        ['Historial', Icons.receipt_long_rounded, HistScreen()],
        ['Fiados', Icons.payments_rounded, FiaScreen()],
      ],
    },
    {
      'title': 'Inventario y Compras',
      'items': [
        ['Inventario', Icons.inventory_rounded, InvScreen()],
        ['Compras', Icons.shopping_bag_rounded, CompScreen()],
        ['Compras Prog.', Icons.calendar_month_rounded, CprScreen()],
        ['Categorías', Icons.category_rounded, CatScreen()],
        ['Distribuciones', Icons.account_balance_wallet_rounded, DisScreen()],
        ['Consumos', Icons.person_off, ConsScreen()],
      ],
    },
    {
      'title': 'Gestión',
      'items': [
        ['Clientes', Icons.people_rounded, CliScreen()],
        ['Proveedores', Icons.business_rounded, ProvScreen()],
        ['Usuarios', Icons.admin_panel_settings_rounded, UsuScreen()],
      ],
    },
    {
      'title': 'Análisis',
      'items': [
        ['Reportes', Icons.bar_chart_rounded, RepScreen()],
        ['Cierres', Icons.lock_rounded, CieScreen()],
        ['Configuración', Icons.settings_rounded, ConScreen()],
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawerScrimColor: Colors.black87,
      appBar: AppBar(title: Text(_filteredItems().isNotEmpty ? _filteredItems()[_index][0] as String : 'Sin permisos'), actions: [
        if (Session.username != null) Padding(
          padding: EdgeInsets.only(right: 12),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(Session.username!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            SizedBox(width: 6),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Session.permCount > 0 ? Tema.primary.withValues(alpha: 0.15) : Tema.danger.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${Session.permCount} permisos',
                style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  color: Session.permCount > 0 ? Tema.primary : Tema.danger,
                ),
              ),
            ),
          ]),
        ),
      ]),
      body: _filteredItems().isEmpty
          ? const Center(child: Text('No tienes permisos para acceder a ningun modulo.', style: TextStyle(color: Colors.grey)))
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
              key: ValueKey(_index),
              child: _filteredItems()[_index][2] as Widget,
            ),
      drawer: Drawer(
        child: Builder(builder: (ctx) {
          final groups = _filteredGroups();
          final drawerItems = <Widget>[];
          drawerItems.add(
            DrawerHeader(
              decoration: const BoxDecoration(gradient: Tema.headerGradient),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [Tema.shadowMd]),
                  child: const Icon(Icons.store_rounded, color: Tema.primary, size: 28),
                ),
                SizedBox(height: 12),
                Text(Session.username ?? 'El Granjero', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.3)),
                Text('Sistema POS', style: TextStyle(color: Colors.white70, fontSize: 11)),
              ]),
            ),
          );
          int idx = 0;
          final indexMap = _filteredIndexMap();
          for (final group in groups) {
            final items = group['items'] as List;
            drawerItems.add(
              Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  (group['title'] as String).toUpperCase(),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Tema.textMuted, letterSpacing: 1),
                ),
              ),
            );
            for (final item in items) {
              final it = item as List;
              final origIdx = _items.indexWhere((e) => e[0] == it[0]);
              final filteredIdx = origIdx >= 0 ? (indexMap[origIdx] ?? idx) : idx;
              final i = filteredIdx;
              drawerItems.add(
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                  decoration: BoxDecoration(
                    color: _index == i ? Tema.primary.withValues(alpha: 0.08) : Colors.transparent,
                    borderRadius: BorderRadius.circular(Tema.radiusSm),
                  ),
                  child: ListTile(
                    leading: Icon(it[1] as IconData, color: _index == i ? Tema.primary : Tema.textMuted, size: 22),
                    title: Text(it[0] as String, style: TextStyle(fontWeight: _index == i ? FontWeight.w600 : FontWeight.w400, color: _index == i ? Tema.primary : Tema.textDark, fontSize: 13)),
                    onTap: () { setState(() => _index = i); Navigator.pop(context); },
                    dense: true,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tema.radiusSm)),
                  ),
                ),
              );
              idx++;
            }
          }
          drawerItems.add(Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Divider(color: Tema.cardBorder)));
          drawerItems.add(
            Container(
              margin: EdgeInsets.symmetric(horizontal: 8, vertical: 1),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(Tema.radiusSm)),
              child: ListTile(
                leading: const Icon(Icons.logout_rounded, color: Tema.danger, size: 22),
                title: const Text('Cerrar Sesion', style: TextStyle(color: Tema.danger, fontSize: 13)),
                dense: true,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tema.radiusSm)),
                onTap: () async {
                  Session.clear();
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                },
              ),
            ),
          );
          return ListView(children: drawerItems);
        }),
      ),
    );
  }
}


