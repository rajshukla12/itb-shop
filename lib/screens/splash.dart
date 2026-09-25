import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config.dart';
import '../state/cart.dart';
import '../state/auth.dart';
import '../theme.dart';
import 'main_nav.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await Future.wait([
      context.read<CartModel>().load(),
      context.read<AuthModel>().load(),
    ]);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNav()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.memory, size: 56, color: AppTheme.primary),
            ),
            const SizedBox(height: 18),
            const Text(Config.storeName, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Electronics • Robotics • Components', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 28),
            const SizedBox(width: 26, height: 26, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
          ],
        ),
      ),
    );
  }
}
