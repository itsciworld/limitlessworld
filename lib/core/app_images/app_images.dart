/// AppImages class containing all image asset paths used in the application
class AppImages {
  // Private constructor to prevent instantiation
  AppImages._();

  // Base paths
  static const String _imagesPath = 'assets/images';
  // ignore: unused_field
  static const String _iconsPath = 'assets/icons';
  // ignore: unused_field
  static const String _logoPath = 'assets/logo';

  // Images
  /// Background image for authentication screens
  static const String backgroundImage = '$_imagesPath/bg.png';

  /// Alternative background image
  static const String backgroundImage2 = '$_imagesPath/bg2.png';
  static const String googleIcon = '$_imagesPath/google-logo.png';

  /// App logo in webp format
  static const String appLogo = '$_imagesPath/limitless-logo.webp';

  /// App logo in PNG format (for native splash and compatibility)
  static const String appLogoPng = '$_imagesPath/limitless-logo.png';

  // Add more image paths as needed
  // Icons can be added here when available
  // static const String iconName = '$_iconsPath/icon_name.png';

  // Logo variations can be added here when available
  // static const String logoVariant = '$_logoPath/logo_variant.png';
}
