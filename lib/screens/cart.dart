import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/cart.dart';
import '../widgets/common.dart';
import 'checkout.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartModel>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        automaticallyImplyLeading: Navigator.canPop(context),
        actions: [
          if (!cart.isEmpty)
            TextButton(
              onPressed: () => _confirmClear(context),
              child: const Text('Clear', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: cart.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 60, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('Your cart is empty', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: cart.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final it = cart.items[i];
                return Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(width: 64, height: 64, child: NetImage(it.image, fit: BoxFit.contain))),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(it.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(money(it.price), style: const TextStyle(fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            Row(
                              children: [
                                _qBtn(Icons.remove, () => context.read<CartModel>().setQty(it.productId, it.qty - 1)),
                                Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text('${it.qty}', style: const TextStyle(fontWeight: FontWeight.bold))),
                                _qBtn(Icons.add, () => context.read<CartModel>().setQty(it.productId, it.qty + 1)),
                              ],
                            ),
                            TextButton(
                              onPressed: () => context.read<CartModel>().remove(it.productId),
                              style: TextButton.styleFrom(minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 6)),
                              child: const Text('Remove', style: TextStyle(fontSize: 11, color: Colors.red)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 8, offset: const Offset(0, -2))]),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Subtotal', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        Text(money(cart.subtotal), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen())),
                        child: const Text('Checkout'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _qBtn(IconData i, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(color: const Color(0xFFEFF3FA), borderRadius: BorderRadius.circular(6)),
          child: Icon(i, size: 16),
        ),
      );

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear cart?'),
        content: const Text('Remove all items from the cart?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<CartModel>().clear();
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
