import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api.dart';
import '../models.dart';
import '../state/cart.dart';
import '../widgets/common.dart';
import '../widgets/product_card.dart';
import 'cart.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  const ProductDetailScreen({super.key, required this.productId});
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Future<Map<String, dynamic>> _future;
  int _img = 0;

  @override
  void initState() {
    super.initState();
    _future = context.read<ApiService>().product(id: widget.productId);
  }

  void _reload() => setState(() => _future = context.read<ApiService>().product(id: widget.productId));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: context.watch<CartModel>().count > 0,
              label: Text('${context.watch<CartModel>().count}'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Loader();
          if (snap.hasError) return ErrorRetry(message: '${snap.error}', onRetry: _reload);
          final p = snap.data!['product'] as Product;
          final related = snap.data!['related'] as List<Product>;
          final gallery = p.gallery.isNotEmpty ? p.gallery : [p.image];
          return Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    Container(
                      color: Colors.white,
                      child: Column(
                        children: [
                          AspectRatio(aspectRatio: 1, child: NetImage(gallery[_img.clamp(0, gallery.length - 1)], fit: BoxFit.contain)),
                          if (gallery.length > 1)
                            SizedBox(
                              height: 66,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.all(8),
                                itemCount: gallery.length,
                                itemBuilder: (_, i) => GestureDetector(
                                  onTap: () => setState(() => _img = i),
                                  child: Container(
                                    width: 54,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: _img == i ? Theme.of(context).primaryColor : Colors.grey.shade300, width: _img == i ? 2 : 1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: NetImage(gallery[i], fit: BoxFit.contain),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, height: 1.3)),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(money(p.price), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                              const SizedBox(width: 8),
                              if (p.mrp > p.price) ...[
                                Text(money(p.mrp), style: TextStyle(fontSize: 14, color: Colors.grey.shade500, decoration: TextDecoration.lineThrough)),
                                const SizedBox(width: 8),
                                Text('${p.discount}% off', style: TextStyle(fontSize: 14, color: Colors.green.shade700, fontWeight: FontWeight.w600)),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(children: [
                            Icon(p.inStock ? Icons.check_circle : Icons.remove_circle, size: 16, color: p.inStock ? Colors.green : Colors.red),
                            const SizedBox(width: 5),
                            Text(p.inStock ? 'In stock' : 'Out of stock', style: TextStyle(color: p.inStock ? Colors.green.shade700 : Colors.red, fontWeight: FontWeight.w600)),
                            if (p.sku.isNotEmpty) ...[const SizedBox(width: 12), Text('SKU: ${p.sku}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12))],
                          ]),
                          if (p.description.isNotEmpty) ...[
                            const Divider(height: 28),
                            const Text('Description', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            const SizedBox(height: 6),
                            Text(p.description, style: TextStyle(color: Colors.grey.shade800, height: 1.5)),
                          ],
                        ],
                      ),
                    ),
                    if (related.isNotEmpty) ...[
                      const SectionHeader('Related Products'),
                      SizedBox(
                        height: 268,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          itemCount: related.length,
                          itemBuilder: (_, i) => SizedBox(width: 170, child: Padding(padding: const EdgeInsets.only(right: 10), child: ProductCard(related[i]))),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              _BuyBar(p),
            ],
          );
        },
      ),
    );
  }
}

class _BuyBar extends StatelessWidget {
  final Product p;
  const _BuyBar(this.p);
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartModel>();
    final qty = cart.qtyOf(p.id);
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 8, offset: const Offset(0, -2))]),
        child: Row(
          children: [
            Expanded(
              child: qty == 0
                  ? OutlinedButton.icon(
                      onPressed: p.inStock ? () => context.read<CartModel>().add(p) : null,
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('Add to Cart'),
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton.filledTonal(onPressed: () => context.read<CartModel>().setQty(p.id, qty - 1), icon: const Icon(Icons.remove)),
                        Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text('$qty', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                        IconButton.filledTonal(onPressed: () => context.read<CartModel>().setQty(p.id, qty + 1), icon: const Icon(Icons.add)),
                      ],
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: p.inStock
                    ? () {
                        if (qty == 0) context.read<CartModel>().add(p);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
                      }
                    : null,
                child: const Text('Buy Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
