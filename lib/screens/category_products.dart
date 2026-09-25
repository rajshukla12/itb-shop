import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api.dart';
import '../models.dart';
import '../widgets/common.dart';
import '../widgets/product_card.dart';

class CategoryProductsScreen extends StatefulWidget {
  final Category category;
  const CategoryProductsScreen({super.key, required this.category});
  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  final _scroll = ScrollController();
  final List<Product> _items = [];
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;
  bool _first = true;
  String? _error;
  String _sort = 'new';

  @override
  void initState() {
    super.initState();
    _load();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 400) _load();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading || (!_hasMore && !reset)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    if (reset) {
      _page = 1;
      _hasMore = true;
      _items.clear();
    }
    try {
      final api = context.read<ApiService>();
      final isSub = widget.category.parentId != 0 || widget.category.level >= 2;
      final page = await api.products(
        catId: isSub ? null : widget.category.id,
        subCatId: isSub ? widget.category.id : null,
        sort: _sort,
        page: _page,
        perPage: 20,
      );
      setState(() {
        _items.addAll(page.items);
        _hasMore = page.hasMore;
        _page++;
        _first = false;
      });
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changeSort(String s) {
    if (s == _sort) return;
    _sort = s;
    _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: _changeSort,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'new', child: Text('Newest')),
              PopupMenuItem(value: 'price_low', child: Text('Price: Low to High')),
              PopupMenuItem(value: 'price_high', child: Text('Price: High to Low')),
            ],
          ),
        ],
      ),
      body: _first && _loading
          ? const Loader()
          : _error != null && _items.isEmpty
              ? ErrorRetry(message: _error!, onRetry: () => _load(reset: true))
              : _items.isEmpty
                  ? const Center(child: Text('No products in this category yet.'))
                  : Column(
                      children: [
                        Expanded(
                          child: GridView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.all(10),
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 230, mainAxisExtent: 268, crossAxisSpacing: 10, mainAxisSpacing: 10),
                            itemCount: _items.length,
                            itemBuilder: (_, i) => ProductCard(_items[i]),
                          ),
                        ),
                        if (_loading && !_first) const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator()),
                      ],
                    ),
    );
  }
}
