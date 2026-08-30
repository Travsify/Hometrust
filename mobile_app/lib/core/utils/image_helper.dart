import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../constants/api_constants.dart';

class ImageHelper {
  /// Resolves any image URL (including localhost or relative storage URLs) to the live API host.
  static String? resolveUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final cleanUrl = url.trim();

    // If it's already a full non-localhost URL (e.g. https://...)
    if (cleanUrl.startsWith('https://') && !cleanUrl.contains('localhost')) {
      return cleanUrl;
    }

    // If it points to localhost (from local backend default)
    if (cleanUrl.contains('localhost:5000')) {
      return cleanUrl.replaceAll('http://localhost:5000/api/v1', ApiConstants.baseUrl);
    }

    // If it's a relative path like /files/... or files/...
    if (cleanUrl.startsWith('/')) {
      return '${ApiConstants.baseUrl}/storage$cleanUrl';
    }

    return cleanUrl;
  }

  /// Builds a responsive avatar or logo widget that shows local picked bytes if available,
  /// or resolves the remote network image, with fallback to initial letters / placeholder icon.
  static Widget buildAvatar({
    String? imageUrl,
    Uint8List? previewBytes,
    required double size,
    required String fallbackName,
    Color backgroundColor = const Color(0xFF0F172A),
    Color textColor = Colors.white,
    BorderRadius? borderRadius,
  }) {
    final radius = borderRadius ?? BorderRadius.circular(size / 2);

    // 1. If local bytes are provided (immediate preview upon file selection)
    if (previewBytes != null && previewBytes.isNotEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.memory(
          previewBytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    // 2. If remote URL is provided
    final resolved = resolveUrl(imageUrl);
    if (resolved != null && resolved.isNotEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.network(
          resolved,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallback(size, fallbackName, backgroundColor, textColor, radius),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(color: backgroundColor.withValues(alpha: 0.1), borderRadius: radius),
              child: Center(
                child: SizedBox(
                  width: size * 0.4,
                  height: size * 0.4,
                  child: const CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF059669)),
                ),
              ),
            );
          },
        ),
      );
    }

    // 3. Fallback to initials
    return _buildFallback(size, fallbackName, backgroundColor, textColor, radius);
  }

  static Widget _buildFallback(double size, String name, Color bg, Color text, BorderRadius radius) {
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join('').toUpperCase()
        : 'HT';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: text,
            fontWeight: FontWeight.w900,
            fontSize: size * 0.36,
          ),
        ),
      ),
    );
  }
}
