# Metiss Mobile Partner Portal

A Flutter-based mobile application for the Metiss Partner Portal.

## Getting Started

Follow these steps to set up and run the project locally.

### Prerequisites

- Flutter SDK (refer to `pubspec.yaml` for the required SDK version, currently `^3.11.4`)
- Android Studio / Xcode for running on emulators/simulators or physical devices
- Firebase CLI (if managing Firebase configurations)

### Setup Instructions

1. **Clone the Repository**
   ```bash
   git clone <repository_url>
   cd mobile
   ```

2. **Environment Variables**
   The application uses `flutter_dotenv` for configuration. Copy the example environment file and adjust the values if necessary:
   ```bash
   cp .env.example .env
   ```

3. **Get Dependencies**
   Run the following command to download the packages:
   ```bash
   flutter pub get
   ```

4. **Firebase Configuration**
   The project requires Firebase configuration files:
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`

   Ensure these files are present before building or running the application.

5. **Run Code Generation**
   This project uses `build_runner` for code generation (e.g., Riverpod, Freezed, JsonSerializable). Run the generator:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

6. **Run the Application**
   ```bash
   flutter run
   ```

## Running Tests

To run the unit and widget tests:
```bash
flutter test
```

## Code Quality & Formatting

Make sure to format and analyze your code before submitting any pull requests:
```bash
dart format .
flutter analyze
```
