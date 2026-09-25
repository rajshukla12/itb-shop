import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../state/cart.dart';
import '../screens/product_detail.dart';
import 'common.dart';

class ProductCard extends StatelessWidget {
  final Product p;
  const ProductCard(this.p, {super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartModel>();
    final inCart = cart.qtyOf(p.id);
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: p.id))),
      child: Card(
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(aspectRatio: 1, child: NetImage(p.image, fit: BoxFit.contain)),
                if (p.discount > 0)
                  Positioned(
                    left: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.red.shade600, borderRadius: BorderRadius.circular(6)),
                      child: Text('${p.discount}% OFF', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                if (!p.inStock)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                      child: const Text('Out of stock', style: TextStyle(color: Colors.white, fontSize: 9)),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, height: 1.2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(money(p.price), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 5),
                  if (p.mrp > p.price)
                    Text(money(p.mrp), style: TextStyle(fontSize: 11, color: Colors.grey.shade500, decoration: TextDecoration.lineThrough)),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(8),
              child: SizedBox(
                width: double.infinity,
                height: 34,
                child: inCart == 0
                    ? OutlinedButton(
                        onPressed: p.inStock ? () => context.read<CartModel>().add(p) : null,
                        style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                        child: const Text('ADD', style: TextStyle(fontWeight: FontWeight.bold)),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _qtyBtn(Icons.remove, () => context.read<CartModel>().setQty(p.id, inCart - 1)),
                          Text('$inCart', style: const TextStyle(fontWeight: FontWeight.bold)),
                          _qtyBtn(Icons.add, () => context.read<CartModel>().setQty(p.id, inCart + 1)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData i, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: const Color(0xFFEFF3FA), borderRadius: BorderRadius.circular(6)),
          child: Icon(i, size: 18),
        ),
      );
}

/// A responsive product grid used by several screens.
class ProductGrid extends StatelessWidget {
  final List<Product> products;
  final ScrollController? controller;
  final Widget? footer;
  final EdgeInsets padding;
  const ProductGrid({super.key, required this.products, this.controller, this.footer, this.padding = const EdgeInsets.all(10)});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: controller,
      padding: padding,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 230,
        mainAxisExtent: 268,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: products.length,
      itemBuilder: (_, i) => ProductCard(products[i]),
    );
  }
}
