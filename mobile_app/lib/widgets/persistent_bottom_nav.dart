import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../screens/navigation_wrapper.dart';

/// A persistent bottom navigation bar that can be added to any screen.
/// When tapped, it navigates to the NavigationWrapper and switches to the
/// selected tab index.
class PersistentBottomNav extends StatelessWidget {
  /// Optional: currently highlighted tab (null = none highlighted)
  final int? activeIndex;

  const PersistentBottomNav({super.key, this.activeIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, 0, Icons.home_rounded, Icons.home_outlined, 'Home'),
              _buildNavItem(context, 1, Icons.explore_rounded, Icons.explore_outlined, 'Explore'),
              _buildVerifyNavItem(context, 2),
              _buildNavItem(context, 3, Icons.account_balance_wallet_rounded, Icons.account_balance_wallet_outlined, 'Purchases'),
              _buildNavItem(context, 4, Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = activeIndex == index;
    return InkWell(
      onTap: () => _navigateToTab(context, index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? const Color(0xFF059669) : AppColors.textMuted,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? const Color(0xFF059669) : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifyNavItem(BuildContext context, int index) {
    final isSelected = activeIndex == index;
    return InkWell(
      onTap: () => _navigateToTab(context, index),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.verified_user_rounded,
              color: isSelected ? Colors.white : AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Verify',
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToTab(BuildContext context, int index) {
    // Pop all routes back to the NavigationWrapper root and switch tab
    Navigator.of(context).popUntil((route) => route.isFirst);
    // Find the NavigationWrapper state and switch tab
    final wrapperState = context.findAncestorStateOfType<NavigationWrapperState>();
    wrapperState?.switchTab(index);
  }
}
