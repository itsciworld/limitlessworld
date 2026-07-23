# Limitless - Flutter Authentication App

A beautiful Flutter authentication app with cosmic-themed UI, implementing MVVM architecture with BLoC state management.

## Features

✨ **Authentication Features**
- Email/Phone login with validation
- User registration with strong password requirements
- Password visibility toggle
- Forgot password functionality (placeholder)
- Social authentication (Google & Apple) - UI ready
- Email verification support
- Token refresh mechanism
- Secure session management

🎨 **UI/UX Features**
- Cosmic dark theme with gradient backgrounds
- Animated splash screen with logo
- Custom form fields with validation
- Gradient buttons with loading states
- Social authentication buttons
- Smooth transitions and animations
- Responsive design

🏗️ **Architecture**
- MVVM (Model-View-ViewModel) pattern
- BLoC for state management
- Clean architecture with separation of concerns
- Repository pattern for data layer
- Reusable UI components
- Type-safe models with validation

## Project Structure

```
lib/
├── bloc/                          # BLoC state management
│   └── auth/                      # Authentication BLoC
│       ├── auth_bloc.dart
│       ├── auth_event.dart
│       └── auth_state.dart
├── components/                    # Reusable UI components
│   ├── app_logo.dart             # Custom app logo widget
│   ├── cosmic_background.dart    # Gradient background
│   ├── custom_text_field.dart    # Custom form field
│   ├── gradient_button.dart      # Gradient button
│   ├── loading_overlay.dart      # Loading indicator
│   └── social_auth_button.dart   # Social login buttons
├── core/                          # Core functionality
│   ├── app_tost/                 # Toast notifications
│   ├── constants/                # App constants
│   │   ├── app_constants.dart
│   │   └── asset_constants.dart
│   └── theme/                    # App theme
│       ├── app_colors.dart
│       ├── app_text_styles.dart
│       └── app_theme.dart
├── features/                      # Feature modules
│   ├── auth/                     # Authentication feature
│   │   ├── models/               # Data models
│   │   │   ├── login_request.dart
│   │   │   ├── register_request.dart
│   │   │   └── user_model.dart
│   │   ├── presentation/         # UI layer
│   │   │   └── pages/
│   │   │       ├── login_screen.dart
│   │   │       ├── signup_screen.dart
│   │   │       └── splash_screen.dart
│   │   └── repository/           # Data layer
│   │       └── auth_repository.dart
│   └── home/                     # Home feature
│       └── presentation/
│           └── pages/
│               └── home_screen.dart
├── service/                       # Services
│   └── api_interceptor_service/  # API service with Dio
└── main.dart                      # App entry point
```

## Getting Started

### Prerequisites

- Flutter SDK (>=3.11.4)
- Dart SDK
- Android Studio / VS Code
- iOS development tools (for iOS)

### Installation

1. Clone the repository:
```bash
git clone <your-repo-url>
cd limitless
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure your API:
   - Open `lib/main.dart`
   - Replace `'https://api.yourdomain.com'` with your actual API URL
   - Update endpoints in `lib/features/auth/repository/auth_repository.dart` if needed

4. Run the app:
```bash
flutter run
```

## Configuration

### API Configuration

Update the base URL in `lib/main.dart`:

```dart
RepositoryProvider<ApiInterceptorService>(
  create: (context) => ApiInterceptorService(
    baseUrl: 'https://your-api-url.com', // Update this
  ),
),
```

### Theme Customization

Modify colors in `lib/core/theme/app_colors.dart`:

```dart
static const Color primaryBlue = Color(0xFF0A7AFF);
static const Color primaryGold = Color(0xFFD4AF37);
// ... more colors
```

### Adding Assets

1. Place your assets in the `assets/` directory
2. Update `pubspec.yaml` if needed
3. Use `AssetConstants` class for asset paths
4. See `assets/README.md` for detailed instructions

## Dependencies

```yaml
dependencies:
  flutter_bloc: ^8.1.6      # State management
  equatable: ^2.0.7         # Value equality
  dio: ^5.10.0             # HTTP client
  fluttertoast: ^9.1.0     # Toast notifications
```

## API Integration

The app expects the following API endpoints:

### Authentication Endpoints

```
POST /auth/login              # User login
POST /auth/register           # User registration
POST /auth/logout             # User logout
GET  /auth/me                 # Get current user
POST /auth/refresh            # Refresh token
POST /auth/password-reset     # Password reset request
POST /auth/google             # Google OAuth
POST /auth/apple              # Apple OAuth
POST /auth/verify-email       # Verify email
POST /auth/resend-code        # Resend verification code
```

### Expected Request/Response Format

**Login Request:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Login Response:**
```json
{
  "token": "jwt_token_here",
  "refresh_token": "refresh_token_here",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "user@example.com"
  }
}
```

## Screens

### 1. Splash Screen
- Animated logo with fade and scale effects
- Cosmic background with stars
- Checks authentication status
- Auto-navigates to login or home

### 2. Login Screen
- Email/Phone input with validation
- Password field with visibility toggle
- Forgot password link
- Sign in button with loading state
- Google & Apple sign-in buttons
- Navigate to signup

### 3. Signup Screen
- Full name, email, phone, password fields
- Password strength validation
- Confirm password matching
- Terms & conditions checkbox
- Create account button
- Social signup options
- Navigate to login

### 4. Home Screen
- Welcome message with user name
- User profile information card
- Logout functionality

## Validation Rules

### Password Requirements
- Minimum 8 characters
- At least one uppercase letter
- At least one lowercase letter
- At least one number
- At least one special character

### Email Validation
- Standard email format (RFC 5322)

### Phone Validation
- Minimum 10 digits
- Supports international formats

### Name Validation
- Minimum 2 characters
- Maximum 100 characters

## State Management

The app uses BLoC pattern with the following states:

- `AuthInitial` - Initial state
- `AuthLoading` - Loading/processing
- `Authenticated` - User logged in
- `Unauthenticated` - No user logged in
- `AuthError` - Error occurred
- `RegistrationSuccess` - Registration completed
- `SessionExpired` - Token expired

## Error Handling

The app handles various error scenarios:
- Network errors
- Server errors (4xx, 5xx)
- Validation errors
- Session expiration
- Token refresh failures

All errors are displayed via toast notifications.

## Customization

### Change App Name
Update in:
- `lib/core/constants/app_constants.dart`
- `pubspec.yaml`
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`

### Change Theme Colors
Modify `lib/core/theme/app_colors.dart`

### Add New Features
Follow the existing feature structure:
```
features/
└── your_feature/
    ├── models/
    ├── presentation/
    └── repository/
```

## Testing

Run tests with:
```bash
flutter test
```

## Building

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## Troubleshooting

### Issue: API connection fails
- Check your API base URL in `main.dart`
- Verify network connectivity
- Check API endpoints match expected format

### Issue: Assets not loading
- Run `flutter clean && flutter pub get`
- Verify asset paths in `pubspec.yaml`
- Check file names match in code

### Issue: Build errors
- Update Flutter: `flutter upgrade`
- Clean project: `flutter clean`
- Get dependencies: `flutter pub get`

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Open a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support, email support@yourdomain.com or open an issue in the repository.

## Acknowledgments

- Flutter team for the amazing framework
- BLoC library maintainers
- Community contributors

---

**Made with ❤️ using Flutter**
