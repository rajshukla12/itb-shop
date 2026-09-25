import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';
import 'models.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class HomeData {
  final List<Map<String, String>> sliders; // {title,image,link}
  final List<Category> categories;
  final List<Product> featured;
  HomeData(this.sliders, this.categories, this.featured);
}

class ProductPage {
  final List<Product> items;
  final int total;
  final bool hasMore;
  ProductPage(this.items, this.total, this.hasMore);
}

class ApiService {
  final String base;
  ApiService({String? base}) : base = base ?? Config.apiBase;

  Uri _u(String path, [Map<String, dynamic>? q]) {
    final qp = <String, String>{};
    q?.forEach((k, v) {
      if (v != null && '$v'.isNotEmpty) qp[k] = '$v';
    });
    return Uri.parse('$base/$path').replace(queryParameters: qp.isEmpty ? null : qp);
  }

  Future<Map<String, dynamic>> _get(String path, [Map<String, dynamic>? q]) async {
    try {
      final r = await http.get(_u(path, q)).timeout(const Duration(seconds: 25));
      return _decode(r);
    } catch (e) {
      throw ApiException(_netMsg(e));
    }
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    try {
      final r = await http
          .post(_u(path), headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
          .timeout(const Duration(seconds: 25));
      return _decode(r);
    } catch (e) {
      throw ApiException(_netMsg(e));
    }
  }

  Map<String, dynamic> _decode(http.Response r) {
    Map<String, dynamic> j;
    try {
      j = jsonDecode(r.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Server error (${r.statusCode}). Please try again.');
    }
    if (j['status'] == 'error') {
      throw ApiException((j['message'] ?? 'Request failed').toString());
    }
    return j;
  }

  String _netMsg(Object e) {
    if (e is ApiException) return e.message;
    return 'Network problem. Check your internet and try again.';
  }

  // ---- endpoints ----

  Future<HomeData> home() async {
    final j = await _get('home');
    final sliders = ((j['sliders'] as List?) ?? [])
        .map<Map<String, String>>((e) => {
              'title': (e['title'] ?? '').toString(),
              'image': (e['image'] ?? '').toString(),
              'link': (e['link'] ?? '').toString(),
            })
        .where((e) => e['image']!.isNotEmpty)
        .toList();
    final cats = ((j['categories'] as List?) ?? []).map((e) => Category.fromJson(e)).toList();
    final feat = ((j['featured'] as List?) ?? []).map((e) => Product.fromJson(e)).toList();
    return HomeData(sliders, cats, feat);
  }

  Future<List<Category>> categories() async {
    final j = await _get('categories');
    return ((j['data'] as List?) ?? []).map((e) => Category.fromJson(e)).toList();
  }

  Future<ProductPage> products({
    int? catId,
    int? subCatId,
    String? q,
    String? sort,
    int page = 1,
    int perPage = 20,
  }) async {
    final j = await _get('products', {
      'cat_id': catId,
      'sub_cat_id': subCatId,
      'q': q,
      'sort': sort,
      'page': page,
      'per_page': perPage,
    });
    final items = ((j['data'] as List?) ?? []).map((e) => Product.fromJson(e)).toList();
    return ProductPage(items, _int(j['total']), j['has_more'] == true);
  }

  Future<Map<String, dynamic>> product({int? id, String? slug}) async {
    final j = await _get('product', {'id': id, 'slug': slug});
    return {
      'product': Product.fromJson(j['product']),
      'related': ((j['related'] as List?) ?? []).map((e) => Product.fromJson(e)).toList(),
    };
  }

  Future<AppUser> login(String email, String password) async {
    final j = await _post('login', {'email': email, 'password': password});
    return AppUser.fromJson(j['user'], (j['token'] ?? '').toString());
  }

  Future<AppUser> register(String name, String email, String mobile, String password) async {
    final j = await _post('register', {
      'name': name,
      'email': email,
      'mobile': mobile,
      'password': password,
    });
    return AppUser.fromJson(j['user'], (j['token'] ?? '').toString());
  }

  Future<Map<String, dynamic>> placeOrder({
    int? userId,
    required String name,
    required String mobile,
    required String address,
    String pincode = '',
    required List<CartItem> items,
  }) async {
    final j = await _post('place_order', {
      'user_id': userId,
      'name': name,
      'mobile': mobile,
      'address': address,
      'pincode': pincode,
      'items': items.map((e) => {'product_id': e.productId, 'qty': e.qty}).toList(),
    });
    return {'order_id': _int(j['order_id']), 'total': j['total'], 'message': j['message']};
  }

  Future<List<OrderSummary>> orders(int userId) async {
    final j = await _get('orders', {'user_id': userId});
    return ((j['data'] as List?) ?? []).map((e) => OrderSummary.fromJson(e)).toList();
  }
}

int _int(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse('${v ?? ''}') ?? 0;
}
