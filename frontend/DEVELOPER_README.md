# Smart Attendee

**Automated Student Attendance Monitoring and Analytics System for Colleges**

A Flutter-based mobile application that streamlines attendance tracking in educational institutions using QR code technology, GPS verification, and real-time analytics.

## 📱 Features

### For Teachers/Faculty
- **QR Code Generation**: Generate unique QR codes for attendance sessions
- **Real-time Dashboard**: Monitor attendance sessions with live student participation
- **Analytics**: View comprehensive analytics including class-wise and subject-wise attendance statistics
- **Session Management**: Start and end attendance sessions with location-based verification
- **Profile Management**: Access faculty profile and authentication

### For Students
- **QR Code Scanning**: Scan QR codes to mark attendance quickly and securely
- **Attendance Analytics**: View personal attendance statistics and history
- **Location Verification**: Automatic GPS-based location verification for attendance
- **Profile Access**: View student profile information

### General Features
- **Role-based Authentication**: Separate login flows for students and faculty
- **JWT Token Management**: Secure authentication using JSON Web Tokens
- **GPS Integration**: Location-based attendance verification to prevent proxy attendance
- **Responsive Design**: Modern UI with smooth animations and responsive layouts
- **Cross-platform**: Supports Android, iOS, Web, Linux, macOS, and Windows

## 🛠️ Tech Stack

- **Framework**: Flutter 3.7.2+
- **Language**: Dart
- **State Management**: StatefulWidget
- **HTTP Client**: `http` package
- **QR Code**: 
  - `qr_flutter` - QR code generation (for teachers)
  - `mobile_scanner` - QR code scanning (for students)
- **Location Services**: `geolocator` package
- **Permissions**: `permission_handler` package
- **Local Storage**: `shared_preferences` package
- **Backend API**: RESTful API (hosted on Render)

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.7.2 or higher)
- [Dart SDK](https://dart.dev/get-dart) (comes with Flutter)
- [Android Studio](https://developer.android.com/studio) (for Android development)
- [Xcode](https://developer.apple.com/xcode/) (for iOS development, macOS only)
- A code editor (VS Code, Android Studio, or IntelliJ IDEA)
- Git

## 🚀 Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd smart_attendee
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Verify Flutter setup**
   ```bash
   flutter doctor
   ```

4. **Run the application**
   ```bash
   flutter run
   ```

## ⚙️ Configuration

### Backend API Configuration

The app is configured to connect to a backend API. The base URL is defined in `lib/utils/constants.dart`:

```dart
static const String apiBaseUrl = 'https://smartattendee-sih25-backend.onrender.com';
```

To use a different backend, update the `apiBaseUrl` in `lib/utils/constants.dart`.

### Permissions

The app requires the following permissions:

**Android** (`android/app/src/main/AndroidManifest.xml`):
- `INTERNET` - For API calls
- `ACCESS_FINE_LOCATION` - For GPS location
- `ACCESS_COARSE_LOCATION` - For approximate location
- `CAMERA` - For QR code scanning

**iOS** (`ios/Runner/Info.plist`):
- `NSLocationWhenInUseUsageDescription` - Location permission description
- `NSCameraUsageDescription` - Camera permission description

## 📱 Usage

### For Faculty/Teachers

1. **Login**: Use your faculty credentials to log in
2. **Dashboard**: View your classes, subjects, and attendance statistics
3. **Generate QR Session**: 
   - Select a class and subject
   - Generate a QR code for the attendance session
   - Display the QR code for students to scan
4. **Monitor Session**: View real-time attendance as students scan the QR code
5. **End Session**: Close the attendance session when complete

### For Students

1. **Login**: Use your student credentials to log in
2. **Home Screen**: View your attendance statistics and profile
3. **Scan QR Code**: 
   - Tap the "Scan QR Code" button
   - Point your camera at the teacher's QR code
   - Attendance will be automatically marked with location verification

## 📁 Project Structure

```
lib/
├── main.dart                          # App entry point
├── services/                          # Business logic and API services
│   ├── attendance_service.dart        # Attendance-related API calls
│   ├── auth_service.dart              # Authentication and login
│   ├── faculty_service.dart           # Faculty-specific API calls
│   ├── location_service.dart          # GPS location services
│   └── student_analytics_service.dart # Student analytics API calls
├── shared/                            # Shared components
│   ├── screens/
│   │   └── login_screen.dart          # Login screen for both roles
│   └── widgets/                       # Reusable widgets
│       ├── custom_button.dart
│       ├── custom_card.dart
│       └── loading_indicator.dart
├── student_app/                       # Student-specific features
│   └── screens/
│       ├── home_screen.dart           # Student dashboard
│       └── qr_scanner_screen.dart     # QR code scanner
├── teacher_app/                       # Teacher-specific features
│   └── screens/
│       ├── teacher_dashboard_screen.dart # Teacher dashboard
│       └── qr_display_screen.dart     # QR code display
└── utils/                             # Utilities and constants
    ├── constants.dart                 # API URLs and constants
    ├── responsive.dart                # Responsive design utilities
    └── theme.dart                     # App theme configuration
```

## 🔌 API Endpoints

The app communicates with the following backend endpoints:

- `POST /auth/login` - User authentication
- `GET /auth/profile` - Get user profile
- `POST /attendance/generate-qr` - Generate QR session (Faculty)
- `GET /attendance/session/{sessionId}` - Get session details
- `POST /attendance/end-session` - End attendance session
- `POST /attendance/mark-attendance` - Mark attendance (Student)
- `GET /api/analytics/faculty` - Faculty analytics
- `GET /api/analytics/student` - Student analytics

## 🧪 Testing

Run the test suite:

```bash
flutter test
```

## 🏗️ Building

### Android
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## 📝 Notes

- The app uses JWT tokens for authentication, stored securely using `shared_preferences`
- Location services are required for attendance verification
- Camera permissions are necessary for QR code scanning
- Demo credentials are included in the codebase for testing purposes

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is part of the Smart India Hackathon 2025 (SIH25).

## 👥 Authors

- Project Team - Smart Attendee

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- All package maintainers whose packages made this project possible

---

**Note**: This is a demo project. Ensure you configure your own backend API and update the credentials before deploying to production.
