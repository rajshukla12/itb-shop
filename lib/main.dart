import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api.dart';
import 'theme.dart';
import 'state/cart.dart';
import 'state/auth.dart';
import 'screens/splash.dart';

void main() {
  runApp(const ItbApp());
}

class ItbApp extends StatelessWidget {
  const ItbApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => ApiService()),
        ChangeNotifierProvider(create: (_) => CartModel()),
        ChangeNotifierProvider(create: (_) => AuthModel()),
      ],
      child: MaterialApp(
        title: 'iTechBuilders',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const SplashScreen(),
      ),
    );
  }
}
