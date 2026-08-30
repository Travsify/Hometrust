import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'explore_screen.dart';
import 'verify_screen.dart';
import 'purchases_screen.dart';
import 'profile_screen.dart';
import 'developer_home_screen.dart';
import 'developer_projects_screen.dart';
import 'developer_subscribers_screen.dart';
import 'developer_tools_screen.dart';
import 'developer_profile_screen.dart';

import '../widgets/floating_ai_assistant.dart';

class NavigationWrapper extends StatefulWidget {
  const NavigationWrapper({super.key});

  @override
  State<NavigationWrapper> createState() => NavigationWrapperState();
}

class NavigationWrapperState extends State<NavigationWrapper> {
  int _currentIndex = 0;

  List<Widget> _getBuyerScreens() => [
    HomeScreen(onNavigateTab: switchTab),
    const ExploreScreen(),
    const VerifyScreen(),
    const PurchasesScreen(),
    const ProfileScreen(),
  ];

  List<Widget> _getDeveloperScreens() => [
    DeveloperHomeScreen(onNavigateTab: switchTab),
    const DeveloperProjectsScreen(),
    const DeveloperSubscribersScreen(),
    const DeveloperToolsScreen(),
    const DeveloperProfileScreen(),
  ];

  void switchTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isDeveloper = authProvider.isDeveloperMode;
    final screens = isDeveloper ? _getDeveloperScreens() : _getBuyerScreens();

    final safeIndex = _currentIndex >= screens.length ? 0 : _currentIndex;

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: safeIndex,
            children: screens,
          ),
          const FloatingAiAssistant(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.cardBorder, width: 1),
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
            child: isDeveloper
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(0, Icons.dashboard_rounded, Icons.dashboard_outlined, 'Dashboard'),
                      _buildNavItem(1, Icons.apartment_rounded, Icons.apartment_outlined, 'Projects'),
                      _buildNavItem(2, Icons.people_alt_rounded, Icons.people_alt_outlined, 'Subscribers'),
                      _buildNavItem(3, Icons.handyman_rounded, Icons.handyman_outlined, 'Tools'),
                      _buildNavItem(4, Icons.business_rounded, Icons.business_outlined, 'Corporate'),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
                      _buildNavItem(1, Icons.explore_rounded, Icons.explore_outlined, 'Explore'),
                      _buildVerifyNavItem(2),
                      _buildNavItem(3, Icons.account_balance_wallet_rounded, Icons.account_balance_wallet_outlined, 'Purchases'),
                      _buildNavItem(4, Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => switchTab(index),
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

  Widget _buildVerifyNavItem(int index) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => switchTab(index),
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
              color: isSelected ? AppColors.primary : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
