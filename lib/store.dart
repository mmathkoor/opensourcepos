import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class AppStore extends ChangeNotifier {
  AppStore(this._prefs) {
    _load();
  }

  final SharedPreferences _prefs;
  static const _key = 'dukkan_data_v1';
  static const defaultShopName = 'بقالتي';

  String shopName = defaultShopName;
  final List<Product> products = [];
  final List<Sale> sales = [];
  final List<Receiving> receivings = [];

  Product? byId(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  Product? byBarcode(String code) {
    final c = code.trim();
    if (c.isEmpty) return null;
    for (final p in products) {
      if (p.barcode == c) return p;
    }
    return null;
  }

  List<Product> get lowStock =>
      products.where((p) => p.isOut || p.isLow).toList();

  List<Sale> salesSince(DateTime start) =>
      sales.where((s) => !s.time.isBefore(start)).toList();

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  void addProduct({
    required String name,
    required int price,
    int cost = 0,
    int stock = 0,
    int minStock = 5,
    String barcode = '',
  }) {
    products.add(Product(
      id: _newId(),
      name: name.trim(),
      price: price,
      cost: cost,
      stock: stock,
      minStock: minStock,
      barcode: barcode.trim(),
    ));
    products.sort((a, b) => a.name.compareTo(b.name));
    _commit();
  }

  void updateProduct(Product p) {
    products.sort((a, b) => a.name.compareTo(b.name));
    _commit();
  }

  void deleteProduct(String id) {
    products.removeWhere((p) => p.id == id);
    _commit();
  }

  Sale? sell(Map<String, int> cart) {
    final lines = <SaleLine>[];
    for (final e in cart.entries) {
      final p = byId(e.key);
      if (p == null || e.value <= 0 || e.value > p.stock) return null;
      lines.add(SaleLine(
        productId: p.id,
        name: p.name,
        qty: e.value,
        price: p.price,
        cost: p.cost,
      ));
    }
    if (lines.isEmpty) return null;
    for (final l in lines) {
      byId(l.productId)!.stock -= l.qty;
    }
    final sale = Sale(id: _newId(), time: DateTime.now(), lines: lines);
    sales.add(sale);
    _commit();
    return sale;
  }

  bool receive({
    required String productId,
    required int qty,
    int? unitCost,
    String supplier = '',
  }) {
    final p = byId(productId);
    if (p == null || qty <= 0) return false;
    p.stock += qty;
    if (unitCost != null && unitCost > 0) p.cost = unitCost;
    receivings.add(Receiving(
      id: _newId(),
      time: DateTime.now(),
      productId: p.id,
      name: p.name,
      qty: qty,
      cost: unitCost ?? 0,
      supplier: supplier.trim(),
    ));
    _commit();
    return true;
  }

  void setShopName(String name) {
    final n = name.trim();
    shopName = n.isEmpty ? defaultShopName : n;
    _commit();
  }

  void loadSamples() {
    const samples = [
      ['أرز بسمتي 5 كجم', 4500, 3800, 24],
      ['سكر 1 كجم', 900, 750, 40],
      ['زيت طبخ 1.5 لتر', 2200, 1900, 6],
      ['حليب مجفف', 1800, 1500, 12],
      ['شاي أحمر', 1500, 1200, 18],
      ['مياه 1.5 لتر', 250, 180, 60],
      ['دقيق 1 كجم', 700, 550, 3],
      ['معكرونة', 500, 380, 0],
    ];
    for (final s in samples) {
      products.add(Product(
        id: '${_newId()}${products.length}',
        name: s[0] as String,
        price: s[1] as int,
        cost: s[2] as int,
        stock: s[3] as int,
      ));
    }
    products.sort((a, b) => a.name.compareTo(b.name));
    _commit();
  }

  void resetAll() {
    products.clear();
    sales.clear();
    receivings.clear();
    shopName = defaultShopName;
    _commit();
  }

  String exportJson() => const JsonEncoder.withIndent('  ').convert(_toJson());

  bool importJson(String text) {
    try {
      _fromJson(jsonDecode(text) as Map<String, dynamic>);
      _commit();
      return true;
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> _toJson() => {
        'shopName': shopName,
        'products': products.map((p) => p.toJson()).toList(),
        'sales': sales.map((s) => s.toJson()).toList(),
        'receivings': receivings.map((r) => r.toJson()).toList(),
      };

  void _fromJson(Map<String, dynamic> m) {
    final ps = (m['products'] as List)
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
    final ss = (m['sales'] as List)
        .map((e) => Sale.fromJson(e as Map<String, dynamic>))
        .toList();
    final rs = (m['receivings'] as List)
        .map((e) => Receiving.fromJson(e as Map<String, dynamic>))
        .toList();
    final name = (m['shopName'] as String?) ?? defaultShopName;
    products
      ..clear()
      ..addAll(ps);
    sales
      ..clear()
      ..addAll(ss);
    receivings
      ..clear()
      ..addAll(rs);
    shopName = name;
  }

  void _load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return;
    try {
      _fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {}
  }

  void _commit() {
    _prefs.setString(_key, jsonEncode(_toJson()));
    notifyListeners();
  }
}
