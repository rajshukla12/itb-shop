import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config.dart';
import '../state/auth.dart';
import 'login.dart';
import 'orders.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthModel>();
    final u = auth.user;
    return Scaffold(
      appBar: AppBar(title: const Text('Account'), automaticallyImplyLeading: false),
      body: ListView(
        children: [
          Container(
            color: Theme.of(context).primaryColor,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            child: u == null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Welcome, Guest', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('Login to place orders and track them.', style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Theme.of(context).primaryColor, minimumSize: const Size(140, 44)),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                        child: const Text('Login / Register'),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      CircleAvatar(radius: 28, backgroundColor: Colors.white, child: Text(u.name.isNotEmpty ? u.name[0].toUpperCase() : '?', style: TextStyle(fontSize: 22, color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold))),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(u.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(u.email, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            if (u.mobile.isNotEmpty) Text(u.mobile, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 8),
          _tile(context, Icons.receipt_long_outlined, 'My Orders', () {
            if (u == null) {
              _needLogin(context);
            } else {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen()));
            }
          }),
          _tile(context, Icons.call_outlined, 'Call to Order', () => _launch('tel:${Config.supportPhone}')),
          _tile(context, Icons.chat_outlined, 'WhatsApp', () => _launch('https://wa.me/${Config.supportPhone.replaceAll('+', '')}')),
          _tile(context, Icons.public, 'Visit Website', () => _launch('https://www.itechbuilders.com')),
          _tile(context, Icons.info_outline, 'About', () => showAboutDialog(context: context, applicationName: Config.storeName, applicationVersion: '1.0.0')),
          if (u != null)
            _tile(context, Icons.logout, 'Logout', () => context.read<AuthModel>().logout(), color: Colors.red),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String label, VoidCallback onTap, {Color? color}) => ListTile(
        leading: Icon(icon, color: color),
        title: Text(label, style: TextStyle(color: color)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      );

  void _needLogin(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Please login first'),
        action: SnackBarAction(label: 'Login', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()))),
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
