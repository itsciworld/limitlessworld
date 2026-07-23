import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../components/app_bottom_nav_bar.dart';
import '../../../../core/theme/app_colors.dart';

/// Hosts the signed-in tabs and keeps [AppBottomNavBar] visible across them.
///
/// Each tab keeps its own navigation stack and state via go_router's
/// [StatefulNavigationShell], so switching tabs does not rebuild or re-fetch.
class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  void _onTap(int index) {
    //  from a bottom bar.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      // The tab bodies paint their own background, so this only frames them.
      body: navigationShell,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
      ),
    );
  }
}
