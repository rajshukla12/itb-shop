import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config.dart';

String money(num v) => '${Config.currency}${v % 1 == 0 ? v.toInt() : v.toStringAsFixed(2)}';

class NetImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  const NetImage(this.url, {super.key, this.width, this.height, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _ph();
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, __) => _ph(shimmer: true),
      errorWidget: (_, __, ___) => _ph(),
    );
  }

  Widget _ph({bool shimmer = false}) => Container(
        width: width,
        height: height,
        color: const Color(0xFFEDEFF3),
        child: Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 28),
      );
}

class Loader extends StatelessWidget {
  const Loader({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
}

class ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorRetry({super.key, required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 46, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700)),
              const SizedBox(height: 14),
              OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
            ],
          ),
        ),
      );
}

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const SectionHeader(this.title, {super.key, this.onSeeAll});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 8, 8),
        child: Row(
          children: [
            Container(width: 4, height: 18, decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const Spacer(),
            if (onSeeAll != null) TextButton(onPressed: onSeeAll, child: const Text('See all')),
          ],
        ),
      );
}
