import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api.dart';
import '../config.dart';
import '../models.dart';
import '../widgets/common.dart';
import '../widgets/product_card.dart';
import 'category_products.dart';
import 'search.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<HomeData> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<ApiService>().home();
  }

  void _reload() => setState(() => _future = context.read<ApiService>().home());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(Config.storeName),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
          ),
        ],
      ),
      body: FutureBuilder<HomeData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Loader();
          if (snap.hasError) return ErrorRetry(message: '${snap.error}', onRetry: _reload);
          final d = snap.data!;
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              children: [
                if (d.sliders.isNotEmpty) _Banner(d.sliders),
                if (d.categories.isNotEmpty) ...[
                  const SectionHeader('Shop by Category'),
                  _CategoryStrip(d.categories),
                ],
                if (d.featured.isNotEmpty) ...[
                  const SectionHeader('Featured Products'),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(10),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 230, mainAxisExtent: 268, crossAxisSpacing: 10, mainAxisSpacing: 10),
                    itemCount: d.featured.length,
                    itemBuilder: (_, i) => ProductCard(d.featured[i]),
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Banner extends StatefulWidget {
  final List<Map<String, String>> sliders;
  const _Banner(this.sliders);
  @override
  State<_Banner> createState() => _BannerState();
}

class _BannerState extends State<_Banner> {
  final _pc = PageController();
  int _page = 0;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    if (widget.sliders.length > 1) {
      _t = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!_pc.hasClients) return;
        _page = (_page + 1) % widget.sliders.length;
        _pc.animateToPage(_page, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      });
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 8,
          child: PageView.builder(
            controller: _pc,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: widget.sliders.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: ClipRRect(borderRadius: BorderRadius.circular(12), child: NetImage(widget.sliders[i]['image']!, fit: BoxFit.cover)),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.sliders.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _page == i ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(color: _page == i ? Theme.of(context).primaryColor : Colors.grey.shade300, borderRadius: BorderRadius.circular(3)),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  final List<Category> cats;
  const _CategoryStrip(this.cats);
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: cats.length,
        itemBuilder: (_, i) {
          final c = cats[i];
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryProductsScreen(category: c))),
            child: Container(
              width: 84,
              margin: const EdgeInsets.only(right: 10),
              child: Column(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 6, offset: const Offset(0, 3))]),
                    clipBehavior: Clip.antiAlias,
                    padding: const EdgeInsets.all(8),
                    child: NetImage(c.image, fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 6),
                  Text(c.name, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, height: 1.1)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
