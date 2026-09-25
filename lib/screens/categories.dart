import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api.dart';
import '../models.dart';
import '../widgets/common.dart';
import 'category_products.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});
  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late Future<List<Category>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<ApiService>().categories();
  }

  void _reload() => setState(() => _future = context.read<ApiService>().categories());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories'), automaticallyImplyLeading: false),
      body: FutureBuilder<List<Category>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Loader();
          if (snap.hasError) return ErrorRetry(message: '${snap.error}', onRetry: _reload);
          final all = snap.data!;
          final parents = all.where((c) => c.parentId == 0).toList();
          if (parents.isEmpty) return const Center(child: Text('No categories yet.'));
          return ListView(
            children: parents.map((p) {
              final subs = all.where((c) => c.parentId == p.id).toList();
              return Card(
                margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: ExpansionTile(
                  leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(width: 44, height: 44, child: NetImage(p.image, fit: BoxFit.contain))),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  childrenPadding: const EdgeInsets.only(bottom: 8),
                  trailing: subs.isEmpty
                      ? const Icon(Icons.chevron_right)
                      : null,
                  onExpansionChanged: subs.isEmpty
                      ? (_) => Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryProductsScreen(category: p)))
                      : null,
                  children: [
                    ListTile(
                      dense: true,
                      title: const Text('All in this category'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryProductsScreen(category: p))),
                    ),
                    ...subs.map((s) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.subdirectory_arrow_right, size: 18),
                          title: Text(s.name),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryProductsScreen(category: s))),
                        )),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
