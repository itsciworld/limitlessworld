// import 'package:flutter/material.dart';
// import '../core/theme/app_colors.dart';
// import '../core/theme/app_text_styles.dart';

// /// App logo with the Limitless branding
// class AppLogo extends StatelessWidget {
//   final double size;
//   final bool showTagline;

//   const AppLogo({
//     super.key,
//     this.size = 200,
//     this.showTagline = true,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         // Logo Icon - Triangular shape
//         Container(
//           width: size * 0.4,
//           height: size * 0.4,
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//               colors: [
//                 AppColors.primaryGold,
//                 AppColors.primaryBlue,
//               ],
//             ),
//             shape: BoxShape.rectangle,
//             boxShadow: [
//               BoxShadow(
//                 color: AppColors.primaryBlue.withOpacity(0.3),
//                 blurRadius: 20,
//                 spreadRadius: 5,
//               ),
//             ],
//           ),
//           child: ClipPath(
//             clipper: TriangleClipper(),
//             child: Container(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   colors: [
//                     AppColors.primaryGold,
//                     AppColors.primaryBlue,
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//         const SizedBox(height: 16),
//         // Logo Text
//         ShaderMask(
//           shaderCallback: (bounds) => const LinearGradient(
//             colors: [
//               AppColors.textPrimary,
//               AppColors.primaryGold,
//             ],
//           ).createShader(bounds),
//           child: Text(
//             'LIMITLESS',
//             style: AppTextStyles.displayLarge.copyWith(
//               fontSize: size * 0.15,
//               letterSpacing: 2,
//               fontWeight: FontWeight.w900,
//             ),
//           ),
//         ),
//         if (showTagline) ...[
//           const SizedBox(height: 8),
//           Text(
//             'BEYOND BOUNDARIES.',
//             style: AppTextStyles.bodySmall.copyWith(
//               fontSize: size * 0.05,
//               letterSpacing: 2,
//               color: AppColors.textSecondary,
//             ),
//           ),
//           Text(
//             'BEYOND LIMITS.',
//             style: AppTextStyles.bodySmall.copyWith(
//               fontSize: size * 0.05,
//               letterSpacing: 2,
//               color: AppColors.primaryBlue,
//             ),
//           ),
//         ],
//       ],
//     );
//   }
// }

// /// Triangle clipper for logo shape
// class TriangleClipper extends CustomClipper<Path> {
//   @override
//   Path getClip(Size size) {
//     final path = Path();
//     path.moveTo(size.width / 2, 0);
//     path.lineTo(size.width, size.height);
//     path.lineTo(0, size.height);
//     path.close();
//     return path;
//   }

//   @override
//   bool shouldReclip(CustomClipper<Path> oldClipper) => false;
// }
