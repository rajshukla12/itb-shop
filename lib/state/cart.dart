import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';

/// Local cart, persisted on the device.
class CartModel extends ChangeNotifier {
  final Map<int, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList();
  int get count => _items.values.fold(0, (s, e) => s + e.qty);
  double get subtotal => _items.values.fold(0.0, (s, e) => s + e.lineTotal);
  bool get isEmpty => _items.isEmpty;

  int qtyOf(int productId) => _items[productId]?.qty ?? 0;

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString('cart');
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List;
      _items.clear();
      for (final e in list) {
        final ci = CartItem.fromJson(e as Map<String, dynamic>);
        _items[ci.productId] = ci;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _save() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('cart', jsonEncode(_items.values.map((e) => e.toJson()).toList()));
  }

  void add(Product p, {int qty = 1}) {
    final existing = _items[p.id];
    if (existing != null) {
      existing.qty += qty;
    } else {
      _items[p.id] = CartItem(
        productId: p.id,
        name: p.name,
        price: p.price,
        mrp: p.mrp,
        image: p.image,
        qty: qty,
      );
    }
    _save();
    notifyListeners();
  }

  void setQty(int productId, int qty) {
    final it = _items[productId];
    if (it == null) return;
    if (qty <= 0) {
      _items.remove(productId);
    } else {
      it.qty = qty;
    }
    _save();
    notifyListeners();
  }

  void remove(int productId) {
    _items.remove(productId);
    _save();
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _save();
    notifyListeners();
  }
}
