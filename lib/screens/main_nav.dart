import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/cart.dart';
import 'home.dart';
import 'categories.dart';
import 'cart.dart';
import 'account.dart';

class MainNav extends StatefulWidget {
  const MainNav({super.key});
  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _i = 0;
  final _pages = const [HomeScreen(), CategoriesScreen(), CartScreen(), AccountScreen()];

  @override
  Widget build(BuildContext context) {
    final count = context.watch<CartModel>().count;
    return Scaffold(
      body: IndexedStack(index: _i, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (v) => setState(() => _i = v),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          const NavigationDestination(icon: Icon(Icons.category_outlined), selectedIcon: Icon(Icons.category), label: 'Categories'),
          NavigationDestination(
            icon: Badge(isLabelVisible: count > 0, label: Text('$count'), child: const Icon(Icons.shopping_cart_outlined)),
            selectedIcon: Badge(isLabelVisible: count > 0, label: Text('$count'), child: const Icon(Icons.shopping_cart)),
            label: 'Cart',
          ),
          const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }
}
