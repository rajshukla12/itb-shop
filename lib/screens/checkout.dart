import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api.dart';
import '../state/cart.dart';
import '../state/auth.dart';
import '../widgets/common.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _address = TextEditingController();
  final _pincode = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthModel>().user;
    if (u != null) {
      _name.text = u.name;
      _mobile.text = u.mobile;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    _address.dispose();
    _pincode.dispose();
    super.dispose();
  }

  Future<void> _place() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final cart = context.read<CartModel>();
      final auth = context.read<AuthModel>();
      final res = await context.read<ApiService>().placeOrder(
            userId: auth.user?.id,
            name: _name.text.trim(),
            mobile: _mobile.text.trim(),
            address: _address.text.trim(),
            pincode: _pincode.text.trim(),
            items: cart.items,
          );
      cart.clear();
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600, size: 60),
              const SizedBox(height: 12),
              const Text('Order placed!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Order #${res['order_id']} • ${money((res['total'] as num?) ?? 0)}', style: TextStyle(color: Colors.grey.shade700)),
              const SizedBox(height: 6),
              Text('${res['message']}', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // dialog
                Navigator.pop(context); // checkout
                Navigator.pop(context); // cart
              },
              child: const Text('Continue Shopping'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Delivery details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Full name'), validator: _req),
            const SizedBox(height: 12),
            TextFormField(
              controller: _mobile,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Mobile number'),
              validator: (v) => (v == null || v.trim().length < 10) ? 'Enter a valid mobile number' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _address, maxLines: 3, decoration: const InputDecoration(labelText: 'Full address'), validator: _req),
            const SizedBox(height: 12),
            TextFormField(controller: _pincode, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Pincode (optional)')),
            const SizedBox(height: 20),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    ...cart.items.map((it) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Expanded(child: Text('${it.name}  ×${it.qty}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))),
                              Text(money(it.lineTotal), style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        )),
                    const Divider(),
                    Row(
                      children: [
                        const Text('Total', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        const Spacer(),
                        Text(money(cart.subtotal), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.local_shipping_outlined, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text('Cash on Delivery / Confirmation call', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
            ]),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _place,
              child: _saving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Text('Place Order'),
            ),
          ],
        ),
      ),
    );
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;
}
