import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';

class AuthModel extends ChangeNotifier {
  AppUser? _user;
  AppUser? get user => _user;
  bool get isLoggedIn => _user != null;

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString('user');
    if (raw == null) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      _user = AppUser.fromJson(j, (j['token'] ?? '').toString());
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setUser(AppUser u) async {
    _user = u;
    final sp = await SharedPreferences.getInstance();
    await sp.setString('user', jsonEncode(u.toJson()));
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    final sp = await SharedPreferences.getInstance();
    await sp.remove('user');
    notifyListeners();
  }
}
