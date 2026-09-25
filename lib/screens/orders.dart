import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api.dart';
import '../models.dart';
import '../state/auth.dart';
import '../widgets/common.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future<List<OrderSummary>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final uid = context.read<AuthModel>().user?.id ?? 0;
    _future = context.read<ApiService>().orders(uid);
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'shipped':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: FutureBuilder<List<OrderSummary>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Loader();
          if (snap.hasError) return ErrorRetry(message: '${snap.error}', onRetry: () => setState(_load));
          final orders = snap.data!;
          if (orders.isEmpty) return const Center(child: Text('No orders yet.'));
          return RefreshIndicator(
            onRefresh: () async => setState(_load),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: orders.length,
              itemBuilder: (_, i) {
                final o = orders[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Order #${o.orderId}', style: const TextStyle(fontWeight: FontWeight.w700)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: _statusColor(o.status).withOpacity(.15), borderRadius: BorderRadius.circular(20)),
                              child: Text(o.status.toUpperCase(), style: TextStyle(color: _statusColor(o.status), fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        Text(o.createdAt, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        const Divider(),
                        ...o.items.map((it) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  ClipRRect(borderRadius: BorderRadius.circular(6), child: SizedBox(width: 40, height: 40, child: NetImage(it.image, fit: BoxFit.contain))),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text('${it.name}  ×${it.qty}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))),
                                ],
                              ),
                            )),
                        const Divider(),
                        Row(
                          children: [
                            const Text('Total', style: TextStyle(fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Text(money(o.total), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
