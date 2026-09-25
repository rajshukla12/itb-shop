// Data models for the iTechBuilders shop app.

class Category {
  final int id;
  final String name;
  final String slug;
  final int parentId;
  final int level;
  final String image;

  Category({
    required this.id,
    required this.name,
    required this.slug,
    required this.parentId,
    required this.level,
    required this.image,
  });

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: _int(j['id']),
        name: (j['name'] ?? '').toString(),
        slug: (j['slug'] ?? '').toString(),
        parentId: _int(j['parent_id']),
        level: _int(j['level']),
        image: (j['image'] ?? '').toString(),
      );
}

class Product {
  final int id;
  final String name;
  final String slug;
  final double price;
  final double mrp;
  final int discount;
  final String image;
  final bool inStock;
  final String stockText;
  final String short;
  final String sku;
  final int catId;
  final int subCatId;

  // detail-only
  final String description;
  final String descriptionHtml;
  final List<String> gallery;

  Product({
    required this.id,
    required this.name,
    required this.slug,
    required this.price,
    required this.mrp,
    required this.discount,
    required this.image,
    required this.inStock,
    required this.stockText,
    required this.short,
    this.sku = '',
    required this.catId,
    required this.subCatId,
    this.description = '',
    this.descriptionHtml = '',
    this.gallery = const [],
  });

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: _int(j['id']),
        name: (j['name'] ?? '').toString(),
        slug: (j['slug'] ?? '').toString(),
        price: _double(j['price']),
        mrp: _double(j['mrp']),
        discount: _int(j['discount']),
        image: (j['image'] ?? '').toString(),
        inStock: j['in_stock'] == true || j['in_stock'] == 1,
        stockText: (j['stock_text'] ?? '').toString(),
        short: (j['short'] ?? '').toString(),
        sku: (j['sku'] ?? '').toString(),
        catId: _int(j['cat_id']),
        subCatId: _int(j['sub_cat_id']),
        description: (j['description'] ?? '').toString(),
        descriptionHtml: (j['description_html'] ?? '').toString(),
        gallery: (j['gallery'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      );

  Map<String, dynamic> toCartJson() => {
        'id': id,
        'name': name,
        'price': price,
        'mrp': mrp,
        'image': image,
      };
}

class CartItem {
  final int productId;
  final String name;
  final double price;
  final double mrp;
  final String image;
  int qty;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.mrp,
    required this.image,
    this.qty = 1,
  });

  double get lineTotal => price * qty;

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'name': name,
        'price': price,
        'mrp': mrp,
        'image': image,
        'qty': qty,
      };

  factory CartItem.fromJson(Map<String, dynamic> j) => CartItem(
        productId: _int(j['product_id']),
        name: (j['name'] ?? '').toString(),
        price: _double(j['price']),
        mrp: _double(j['mrp']),
        image: (j['image'] ?? '').toString(),
        qty: _int(j['qty']) == 0 ? 1 : _int(j['qty']),
      );
}

class AppUser {
  final int id;
  final int cId;
  final String name;
  final String email;
  final String mobile;
  final String token;

  AppUser({
    required this.id,
    required this.cId,
    required this.name,
    required this.email,
    required this.mobile,
    required this.token,
  });

  factory AppUser.fromJson(Map<String, dynamic> u, String token) => AppUser(
        id: _int(u['id']),
        cId: _int(u['c_id']),
        name: (u['name'] ?? '').toString(),
        email: (u['email'] ?? '').toString(),
        mobile: (u['mobile'] ?? '').toString(),
        token: token,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'c_id': cId,
        'name': name,
        'email': email,
        'mobile': mobile,
        'token': token,
      };
}

class OrderSummary {
  final int orderId;
  final double total;
  final String status;
  final String createdAt;
  final List<CartItem> items;

  OrderSummary({
    required this.orderId,
    required this.total,
    required this.status,
    required this.createdAt,
    required this.items,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> j) => OrderSummary(
        orderId: _int(j['order_id']),
        total: _double(j['total']),
        status: (j['status'] ?? '').toString(),
        createdAt: (j['created_at'] ?? '').toString(),
        items: (j['items'] as List?)
                ?.map((e) => CartItem(
                      productId: 0,
                      name: (e['name'] ?? '').toString(),
                      price: _double(e['price']),
                      mrp: 0,
                      image: (e['image'] ?? '').toString(),
                      qty: _int(e['qty']),
                    ))
                .toList() ??
            const [],
      );
}

int _int(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse('${v ?? ''}') ?? 0;
}

double _double(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse('${v ?? ''}') ?? 0;
}
