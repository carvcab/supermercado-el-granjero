import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';

class Fb {
  static final _db = FirebaseFirestore.instance.collection('datos');
  static Box? _box;
  static bool _online = true;

  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox('supermercado_data');
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
    _checkOnline();
  }

  static bool get online => _online;

  static void _checkOnline() {
    try {
      _db.doc('productos').get().then((_) {
        _online = true;
        _sincronizarPendientes();
      }).catchError((_) {
        _online = false;
      });
    } catch (_) {
      _online = false;
    }
  }

  static Future<void> _sincronizarPendientes() async {
    if (_box == null) return;
    final pendientes = _box!.get('_pendientes', defaultValue: <Map>[]);
    if (pendientes.isEmpty) return;
    for (final p in List<Map>.from(pendientes)) {
      try {
        final doc = p['doc'] as String;
        final list = p['lista'] as List;
        final List<Map<String, dynamic>> listWithStrKeys = _sanitizeList(list)
            .cast<Map>()
            .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
            .toList();
        await _db.doc(doc).set({'lista': listWithStrKeys}, SetOptions(merge: true));
      } catch (_) { break; }
    }
    await _box!.delete('_pendientes');
  }

  static List<dynamic> _sanitizeList(List<dynamic> list) {
    final List<dynamic> res = [];
    for (final item in list) {
      if (item is Map) {
        res.add(_sanitizeMap(item));
      } else if (item is List) {
        res.add(_sanitizeList(item));
      } else {
        res.add(item);
      }
    }
    return res;
  }

  static Map<dynamic, dynamic> _sanitizeMap(Map map) {
    final Map<dynamic, dynamic> res = {};
    map.forEach((k, v) {
      if (v is Map) {
        res[k] = _sanitizeMap(v);
      } else if (v is List) {
        res[k] = _sanitizeList(v);
      } else {
        res[k] = v;
      }
    });
    return res;
  }

  static Future<List<Map<dynamic,dynamic>>> getList(String doc) async {
    if (_box == null) return [];
    try {
      final d = await _db.doc(doc).get();
      final data = d.data();
      if (data != null && data['lista'] != null) {
        final list = _sanitizeList(data['lista'] as List).cast<Map<dynamic, dynamic>>();
        await _box!.put(doc, list);
        _online = true;
        return list;
      }
    } catch (_) { _online = false; }
    final cached = _box!.get(doc);
    if (cached != null) {
      try {
        return _sanitizeList(cached as List).cast<Map<dynamic, dynamic>>();
      } catch (_) {}
    }
    return [];
  }

  static Future<void> clearCache(String doc) async {
    if (_box != null) {
      await _box!.delete(doc);
    }
  }

  static Future<void> setList(String doc, List<Map<dynamic,dynamic>> list) async {
    if (_box == null) return;
    final clean = _sanitizeList(list).cast<Map<dynamic, dynamic>>();
    try {
      await _box!.put(doc, clean);
      final List<Map<String, dynamic>> listWithStrKeys = clean
          .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
          .toList();
      await _db.doc(doc).set({'lista': listWithStrKeys}, SetOptions(merge: true));
      _online = true;
    } catch (_) {
      _online = false;
      final pendientes = _box!.get('_pendientes', defaultValue: <Map>[]);
      final idx = pendientes.indexWhere((p) => p['doc'] == doc);
      if (idx >= 0) {
        pendientes[idx] = {'doc': doc, 'lista': clean};
      } else {
        pendientes.add({'doc': doc, 'lista': clean});
      }
      await _box!.put('_pendientes', pendientes);
    }
  }

  static Future<List<Map<dynamic, dynamic>>> mergeItem(String doc, Map<dynamic, dynamic> item, {bool isDelete = false, dynamic deleteId}) async {
    try {
      final d = await _db.doc(doc).get();
      final data = d.data();
      List<Map<dynamic, dynamic>> remoteList = [];
      if (data != null && data['lista'] != null) {
        remoteList = _sanitizeList(data['lista'] as List).cast<Map<dynamic, dynamic>>();
      }
      if (isDelete && deleteId != null) {
        remoteList.removeWhere((x) => x['id'] == deleteId);
      } else {
        final idx = remoteList.indexWhere((x) => x['id'] == item['id']);
        if (idx >= 0) {
          remoteList[idx] = {...remoteList[idx], ...item};
        } else {
          remoteList.add(item);
        }
      }
      await setList(doc, remoteList);
      return remoteList;
    } catch (_) {
      _online = false;
      return [];
    }
  }

  static Future<void> recordDeletion(String col, dynamic id) async {
    final String delId = '${col}_$id';
    try {
      final List<Map<dynamic, dynamic>> deletions = await getList('deletions');
      final exists = deletions.any((d) => d['id']?.toString() == delId);
      if (!exists) {
        deletions.add({
          'id': delId,
          'col': col,
          'target_id': id,
          'deleted_at': DateTime.now().toIso8601String(),
        });
        await setList('deletions', deletions);
      }
    } catch (e) {
      debugPrint('Error recording deletion in Flutter: $e');
    }
  }

  static Stream<List<Map<dynamic,dynamic>>> stream(String doc) {
    StreamController<List<Map<dynamic,dynamic>>>? ctrl;
    StreamSubscription? fireSub;

    void emit(List<Map<dynamic,dynamic>> data) {
      if (ctrl != null && !ctrl.isClosed) ctrl.add(data);
    }

    ctrl = StreamController<List<Map<dynamic,dynamic>>>(
      onListen: () {
        if (_box != null) {
          final cached = _box!.get(doc);
          if (cached != null) {
            try {
              emit(_sanitizeList(cached as List).cast<Map<dynamic, dynamic>>());
            } catch (_) {}
          }
        }
        fireSub = _db.doc(doc).snapshots().listen((snap) {
          final data = snap.data();
          if (data != null && data['lista'] != null) {
            final list = _sanitizeList(data['lista'] as List).cast<Map<dynamic, dynamic>>();
            if (_box != null) _box!.put(doc, list);
            _online = true;
            emit(list);
          }
        }, onError: (_) {
          _online = false;
        });
      },
      onCancel: () {
        fireSub?.cancel();
      },
    );

    return ctrl.stream;
  }

  /// Stream a single document as a Map (for config_caja_negocio, etc.)
  /// Reads root-level fields directly, ignoring the 'lista' wrapper.
  static Stream<Map<dynamic, dynamic>> streamDoc(String doc) {
    StreamController<Map<dynamic, dynamic>>? ctrl;
    StreamSubscription? fireSub;

    void emit(Map<dynamic, dynamic> data) {
      if (ctrl != null && !ctrl.isClosed) ctrl.add(data);
    }

    ctrl = StreamController<Map<dynamic, dynamic>>(
      onListen: () {
        // Emit cached value first
        if (_box != null) {
          final cached = _box!.get('_doc_$doc');
          if (cached != null && cached is Map) {
            emit(_sanitizeMap(cached));
          }
        }
        fireSub = _db.doc(doc).snapshots().listen((snap) {
          final data = snap.data();
          if (data != null) {
            final clean = _sanitizeMap(data);
            if (_box != null) _box!.put('_doc_$doc', clean);
            _online = true;
            emit(clean);
          }
        }, onError: (_) {
          _online = false;
        });
      },
      onCancel: () {
        fireSub?.cancel();
      },
    );

    return ctrl.stream;
  }

  static Future<Map<dynamic,dynamic>> getDoc(String doc) async {
    try {
      final d = await _db.doc(doc).get();
      final data = d.data();
      if (data != null && data['lista'] != null && data['lista'] is List) {
        final list = _sanitizeList(data['lista'] as List).cast<Map<dynamic, dynamic>>();
        return list.isNotEmpty ? list.first : {};
      }
      if (data != null) return _sanitizeMap(data);
    } catch (_) {}
    return {};
  }

  static Future<void> setDoc(String doc, Map<dynamic,dynamic> value) async {
    try {
      final clean = _sanitizeMap(value);
      final Map<String, dynamic> cleanStringKeys = clean.map((k, v) => MapEntry(k.toString(), v));
      await _db.doc(doc).set(cleanStringKeys, SetOptions(merge: true));
    } catch (_) {}
  }

  static String formatMoney(num n) {
    final isNeg = n < 0;
    final s = n.abs().round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${isNeg ? '-' : ''}\$$buf';
  }

  static Widget kpiCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const Spacer(),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
