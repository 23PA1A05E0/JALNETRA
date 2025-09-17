# JALNETRA - Groundwater Monitoring & Recharge Estimation App

A comprehensive Flutter application for monitoring groundwater stations and estimating recharge rates using advanced sensor data analysis.

## 🚀 Features

- **Real-time Monitoring**: Live data from groundwater monitoring stations
- **Interactive Maps**: Google Maps integration with station markers
- **Data Visualization**: Time-series charts for water level, temperature, pH, and recharge rates
- **Recharge Estimation**: Multiple algorithms for groundwater recharge calculation
- **Push Notifications**: Alerts for station status and recharge rate changes
- **Background Sync**: Automatic data synchronization
- **Secure Storage**: Encrypted local data storage
- **Offline Support**: Local caching with Hive database

## 🏗️ Architecture

- **MVVM Pattern**: Clean separation of concerns
- **State Management**: Riverpod for reactive state management
- **Navigation**: go_router for declarative routing
- **Local Storage**: Hive for offline data persistence
- **Networking**: Dio for HTTP requests
- **Maps**: Google Maps Flutter plugin
- **Charts**: FL Chart for data visualization

## 📱 Screenshots

*Screenshots will be added after UI implementation*

## 🛠️ Setup Instructions

### Prerequisites

- Flutter SDK (3.8.1 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / VS Code
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd jalnetra
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code**
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Configure Firebase** (Optional)
   - Create a Firebase project
   - Add `google-services.json` to `android/app/`
   - Add `GoogleService-Info.plist` to `ios/Runner/`

5. **Configure Google Maps** (Required for maps)
   - Get Google Maps API key
   - Add to `android/app/src/main/AndroidManifest.xml`:
     ```xml
     <meta-data android:name="com.google.android.geo.API_KEY"
                android:value="YOUR_API_KEY"/>
     ```
   - Add to `ios/Runner/AppDelegate.swift`:
     ```swift
     GMSServices.provideAPIKey("YOUR_API_KEY")
     ```

### Configuration

#### Backend API Configuration

1. **Set API Base URL**
   - Open `lib/services/api_service.dart`
   - Update `_baseUrl` constant:
     ```dart
     static const String _baseUrl = 'https://your-api-domain.com/v1';
     ```

2. **Set API Key**
   - Update `_apiKey` constant:
     ```dart
     static const String _apiKey = 'your-actual-api-key';
     ```
   - Or use secure storage for production:
     ```dart
     final apiKey = await SecureStorageService.instance.retrieve('api_key');
     ```

#### Map Provider Configuration

To switch from Google Maps to OpenStreetMap:

1. **Update pubspec.yaml**
   ```yaml
   dependencies:
     # Remove: google_maps_flutter: ^2.6.1
     # Add: flutter_map: ^6.1.0
   ```

2. **Update map implementation**
   - Replace Google Maps widgets with Flutter Map widgets
   - Update `lib/screens/home_screen.dart` map implementation

#### Notification Configuration

1. **Firebase Setup**
   - Enable Firebase Cloud Messaging
   - Configure notification channels

2. **Local Notifications**
   - Update notification icons in `android/app/src/main/res/`
   - Configure notification permissions

### Running the App

1. **Debug Mode**
   ```bash
   flutter run
   ```

2. **Release Mode**
   ```bash
   flutter run --release
   ```

3. **Build APK**
   ```bash
   flutter build apk --release
   ```

4. **Build iOS**
   ```bash
   flutter build ios --release
   ```

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── station.dart         # Station model
│   ├── measurement.dart     # Measurement model
│   └── recharge_estimate.dart # Recharge estimate model
├── services/                # Business logic
│   └── api_service.dart     # API communication
├── providers/               # State management
│   ├── stations_provider.dart
│   └── measurements_provider.dart
├── screens/                 # UI screens
│   ├── home_screen.dart
│   ├── station_detail_screen.dart
│   └── settings_screen.dart
├── widgets/                 # Reusable widgets
│   ├── station_card.dart
│   ├── measurement_chart.dart
│   └── recharge_settings_dialog.dart
├── routes/                  # Navigation
│   └── app_router.dart
└── utils/                   # Utilities
    ├── secure_storage_service.dart
    └── notification_service.dart
```

## 🔧 Development

### Code Generation

The project uses code generation for JSON serialization and Hive adapters:

```bash
# Generate code
flutter packages pub run build_runner build

# Watch for changes
flutter packages pub run build_runner watch
```

### Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/
```

### Linting

```bash
# Analyze code
flutter analyze

# Fix formatting
dart format .
```

## 🚧 TODO Implementation Areas

### High Priority
- [ ] **WebSocket Connection**: Implement real-time data streaming
- [ ] **Recharge Algorithm**: Implement actual recharge calculation logic
- [ ] **API Integration**: Connect to real backend endpoints
- [ ] **Authentication**: Add user login and authorization
- [ ] **Data Validation**: Add input validation and error handling

### Medium Priority
- [ ] **Offline Sync**: Implement conflict resolution for offline data
- [ ] **Push Notifications**: Configure FCM and local notifications
- [ ] **Background Tasks**: Implement WorkManager and Background Fetch
- [ ] **Data Export**: Add CSV/JSON export functionality
- [ ] **Settings Persistence**: Save user preferences

### Low Priority
- [ ] **Dark Theme**: Implement dark mode
- [ ] **Accessibility**: Add screen reader support
- [ ] **Internationalization**: Add multi-language support
- [ ] **Analytics**: Add usage tracking
- [ ] **Crash Reporting**: Implement error reporting

## 🔐 Security Considerations

- **API Keys**: Store sensitive keys in secure storage
- **Data Encryption**: Encrypt sensitive data at rest
- **Network Security**: Use HTTPS for all API calls
- **Input Validation**: Validate all user inputs
- **Authentication**: Implement proper user authentication

## 📊 Performance Optimization

- **Image Caching**: Implement image caching for station photos
- **Data Pagination**: Load data in chunks for large datasets
- **Memory Management**: Dispose controllers and streams properly
- **Background Processing**: Use isolates for heavy computations

## 🐛 Troubleshooting

### Common Issues

1. **Build Errors**
   ```bash
   flutter clean
   flutter pub get
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```

2. **Map Not Showing**
   - Check API key configuration
   - Verify internet connection
   - Check platform-specific setup

3. **Notifications Not Working**
   - Verify Firebase configuration
   - Check notification permissions
   - Test on physical device

### Debug Mode

Enable debug logging:
```dart
// In main.dart
Logger.level = Level.debug;
```

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📞 Support

For support and questions:
- Create an issue in the repository
- Contact the development team
- Check the documentation

## 🔄 Version History

- **v1.0.0** - Initial release with core features
- **v1.1.0** - Added real-time monitoring
- **v1.2.0** - Enhanced charts and visualization
- **v1.3.0** - Added recharge estimation algorithms

---

**Note**: This is a starter project with scaffolded implementations. Real functionality needs to be implemented based on your specific requirements and backend API.
