import 'package:flutter/material.dart';

import '../core/app_images/app_images.dart';
import '../core/theme/app_colors.dart';

/// The shared cosmic background used by every auth screen: the app image with
/// a darkening gradient so text stays readable on top of it.
class AuthBackground extends StatelessWidget {
  final Widget child;

  /// Wrap [child] in a `SafeArea` + scrolling column. Set false when the screen
  /// manages its own scrolling.
  final bool scrollable;
  final EdgeInsetsGeometry? padding;

  const AuthBackground({
    super.key,
    required this.child,
    this.scrollable = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final horizontal = MediaQuery.of(context).size.width < 360 ? 16.0 : 24.0;
    final resolvedPadding =
        padding ?? EdgeInsets.symmetric(horizontal: horizontal);

    Widget content = child;
    if (scrollable) {
      content = SingleChildScrollView(
        padding: resolvedPadding,
        child: child,
      );
    } else {
      content = Padding(padding: resolvedPadding, child: child);
    }

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppImages.backgroundImage),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.3),
                Colors.black.withValues(alpha: 0.5),
              ],
            ),
          ),
          child: SafeArea(child: content),
        ),
      ),
    );
  }
}
