import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api.dart';
import '../models.dart';
import '../widgets/common.dart';
import '../widgets/product_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _c = TextEditingController();
  Timer? _debounce;
  List<Product> _items = [];
  bool _loading = false;
  String? _error;
  String _q = '';

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () => _search(v.trim()));
  }

  Future<void> _search(String q) async {
    _q = q;
    if (q.length < 2) {
      setState(() {
        _items = [];
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await context.read<ApiService>().products(q: q, perPage: 30);
      if (_q == q) setState(() => _items = page.items);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _c,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: _onChanged,
          onSubmitted: (v) => _search(v.trim()),
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          decoration: const InputDecoration(
            hintText: 'Search products, SKU…',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
          ),
        ),
        actions: [
          if (_c.text.isNotEmpty)
            IconButton(icon: const Icon(Icons.clear), onPressed: () { _c.clear(); _search(''); }),
        ],
      ),
      body: _loading
          ? const Loader()
          : _error != null
              ? ErrorRetry(message: _error!, onRetry: () => _search(_q))
              : _q.length < 2
                  ? const Center(child: Text('Type at least 2 letters to search.'))
                  : _items.isEmpty
                      ? const Center(child: Text('No products found.'))
                      : ProductGrid(products: _items),
    );
  }
}
