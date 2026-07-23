# Assets Directory

This directory contains all the assets used in the Limitless app.

## Directory Structure

```
assets/
├── images/          # General images used in the app
├── icons/           # App icons and custom icons
└── logo/            # App logo and branding assets
```

## Adding Assets

### 1. Logo Assets
Place your logo files in the `assets/logo/` directory:
- `logo.png` - Main app logo
- `logo_with_text.png` - Logo with "LIMITLESS" text
- `logo_icon.png` - Icon-only version for splash screen

### 2. Social Media Icons
Place social media icons in the `assets/icons/` directory:
- `google_icon.png` - Google logo for sign-in button
- `apple_icon.png` - Apple logo for sign-in button

Recommended size: 24x24 pixels or 48x48 pixels (2x)

### 3. Background Images
Place any additional background images in the `assets/images/` directory.

## Usage in Code

After adding assets, you can use them in your Flutter code:

```dart
// For images
Image.asset('assets/images/your_image.png')

// For icons in social buttons
Image.asset('assets/icons/google_icon.png', width: 20, height: 20)

// For logo
Image.asset('assets/logo/logo.png')
```

## Note

The app currently uses:
- Custom painted logo (triangular shape) in `AppLogo` widget
- Material Icons for most UI elements
- Custom gradient backgrounds

If you want to use image assets instead of the custom painted logo, you can replace the `AppLogo` widget implementation to use `Image.asset()` instead of the custom `ClipPath` and `Container` widgets.

## Optimization

For production apps, consider:
1. Using vector assets (SVG) with the `flutter_svg` package
2. Providing multiple resolutions (1x, 2x, 3x) for raster images
3. Optimizing image sizes using tools like TinyPNG or ImageOptim
