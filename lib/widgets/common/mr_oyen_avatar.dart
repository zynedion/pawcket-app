import 'package:flutter/material.dart';
import '../../config/theme.dart';

class MrOyenAvatar extends StatelessWidget {
  final double size;
  final String expression; // maps to user's generated assets: angry, cunning, interogating, lazyass, mischievous, smirk, thinking

  const MrOyenAvatar({
    super.key,
    this.size = 128.0,
    this.expression = 'smirk',
  });

  String _getImageAsset() {
    switch (expression.toLowerCase()) {
      case 'angry':
        return 'assets/images/angry_oyen.png';
      case 'cunning':
        return 'assets/images/cunning_oyen.png';
      case 'interrogating':
      case 'interogating':
        return 'assets/images/interogating_oyen.png';
      case 'lazy':
      case 'lazyass':
        return 'assets/images/lazyass_oyen.png';
      case 'mischievous':
        return 'assets/images/mischievous_oyen.png';
      case 'thinking':
        return 'assets/images/thinking_oyen.png';
      case 'smirk':
      default:
        return 'assets/images/smirk_oyen.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Premium glassmorphism-like container with cyan border and subtle glow
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [
            Color(0x330EA5E9), // 20% opacity Cyan
            Color(0x000EA5E9), // Transparent
          ],
          radius: 0.6,
        ),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.3),
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.15),
            blurRadius: 16.0,
            spreadRadius: 2.0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.asset(
          _getImageAsset(),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // High-quality fallback avatar in case image asset is missing/loading fails
            return Container(
              color: AppColors.neutral100,
              alignment: Alignment.center,
              child: const Icon(
                Icons.pets,
                color: AppColors.secondary,
                size: 48,
              ),
            );
          },
        ),
      ),
    );
  }
}
