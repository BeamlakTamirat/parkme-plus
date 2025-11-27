<div align="center">

# 📱 ParkMe Plus - User Mobile App

### *Find Your Perfect Parking Spot in Seconds*

[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android-blue)](https://flutter.dev)
[![Flutter](https://img.shields.io/badge/Flutter-3.19.0+-02569B?logo=flutter)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](../../../LICENSE)

**The ultimate parking companion for Ethiopian drivers - powered by real-time maps and instant payments.**

</div>

---

## 🎯 What is This App?

The **ParkMe Plus User App** is a beautiful, intuitive mobile application that transforms the parking experience. No more driving in circles looking for a spot - find, book, and pay for parking in just a few taps.

### **Key Highlights**

✨ **Real-Time Availability** - See live parking spots on Mapbox maps  
🗺️ **Smart GPS Search** - Find nearest parking with distance calculation  
⚡ **Instant Booking** - Reserve spots in under 10 seconds  
💳 **Ethiopian Payments** - Telebirr, CBE Birr, cards via Chapa  
📱 **QR Check-In** - Scan to enter and exit parking lots  
📊 **Booking History** - Track all your parking sessions  

---

## 🏗️ App Architecture

### **Screen Structure**

```
user_app/
├── lib/
│   └── src/
│       ├── screens/
│       │   ├── auth/                    # 🔐 Authentication
│       │   │   ├── enhanced_sign_in_screen.dart
│       │   │   └── enhanced_sign_up_screen.dart
│       │   │
│       │   ├── onboarding/              # 👋 First-time user experience
│       │   │   └── onboarding_screen.dart
│       │   │
│       │   ├── home/                    # 🏠 Main dashboard
│       │   │   └── comprehensive_home_screen.dart
│       │   │
│       │   ├── maps/                    # 🗺️ Interactive Mapbox maps
│       │   │   └── maps_screen.dart
│       │   │
│       │   ├── parking/                 # 🅿️ Find & browse parking
│       │   │   └── find_parking_screen.dart
│       │   │
│       │   ├── booking/                 # 📝 Active bookings
│       │   │   └── active_booking_screen.dart
│       │   │
│       │   ├── payment/                 # 💳 Payment processing
│       │   │   ├── secure_payment_screen.dart
│       │   │   └── webview_payment_screen.dart
│       │   │
│       │   ├── history/                 # 📊 Past bookings
│       │   │   └── parking_history_screen.dart
│       │   │
│       │   ├── profile/                 # 👤 User profile
│       │   │   └── profile_screen.dart
│       │   │
│       │   └── navigation/              # 🧭 Bottom navigation
│       │       ├── main_navigation.dart
│       │       └── navigation_screen.dart
│       │
│       ├── providers/                   # 🔄 Riverpod state management
│       │   ├── auth_provider.dart
│       │   ├── booking_provider.dart
│       │   └── location_provider.dart
│       │
│       ├── routes/                      # 🛣️ Navigation routes
│       │   └── app_router.dart
│       │
│       └── widgets/                     # 🧩 Reusable components
│           └── common/
│
└── pubspec.yaml
```

### **State Management with Riverpod**

```dart
// Example: Auth Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

// Example: Parking Locations Provider
final parkingLocationsProvider = FutureProvider<List<ParkingLocation>>((ref) async {
  return await DatabaseService.instance.getParkingLocations();
});
```

---

## ✨ Features Deep Dive

### **1. 🔐 Authentication**

**Screens:**
- `enhanced_sign_in_screen.dart` - Beautiful gradient login
- `enhanced_sign_up_screen.dart` - Quick registration

**Features:**
- Email/password authentication via Appwrite
- Form validation with real-time feedback
- Secure session management
- Password strength indicator
- "Remember me" functionality

### **2. 🗺️ Interactive Maps**

**Powered by Mapbox Maps Flutter**

- Real-time parking location markers
- User location tracking with GPS
- Distance calculation (Haversine formula)
- Multiple map styles (Streets, Satellite, Dark)
- Smooth animations and gestures
- Custom parking spot icons

**Map Styles Available:**
```dart
- Streets (Default)
- Satellite
- Satellite + Streets
- Outdoors
- Light
- Dark
- Navigation Day
- Navigation Night
```

### **3. 🅿️ Smart Parking Search**

**Find Parking Screen Features:**

- **Filter by Distance** - Show nearest locations first
- **Filter by Price** - Find affordable parking
- **Filter by Availability** - Only show available spots
- **Sort Options** - Distance, price, rating
- **Real-Time Updates** - Live availability via Appwrite Realtime

**Search Algorithm:**
```dart
// Distance calculation using Haversine formula
double calculateDistance(lat1, lon1, lat2, lon2) {
  const earthRadius = 6371; // km
  // ... Haversine implementation
  return distance;
}
```

### **4. ⚡ Instant Booking**

**Booking Flow:**
1. Select parking location
2. Choose time duration
3. Enter vehicle details (plate number, model, color)
4. Review booking summary
5. Proceed to payment
6. Receive QR code for check-in

**Dynamic Spot Assignment:**
- Automatic spot allocation (A1-A20, B1-B20)
- Real-time availability checking
- Conflict prevention with database locks

### **5. 💳 Payment Integration**

**Chapa Payment Gateway**

Supported Methods:
- 💰 **Telebirr** - Ethiopia's #1 mobile money
- 🏦 **CBE Birr** - Commercial Bank of Ethiopia
- 💳 **Awash Birr** - Awash Bank wallet
- 📱 **E-Birr** - National mobile money
- 🌍 **Visa/Mastercard** - International cards

**Payment Flow:**
```
User → Select Payment Method → Chapa WebView → 
Payment Verification → Booking Confirmation → QR Code Generation
```

**Security Features:**
- PCI-compliant payment processing
- Transaction verification with Chapa API
- Amount validation before booking creation
- Secure WebView for payment forms
- Receipt generation

### **6. 📱 QR Code System**

**QR Code Generation:**
```dart
// Unique QR code for each booking
String qrData = 'PARKME_${bookingId}_${userId}_${timestamp}';
```

**Use Cases:**
- Check-in at parking entrance
- Check-out when leaving
- Attendant verification
- Quick booking lookup

### **7. 📊 Booking History**

**Features:**
- Complete transaction history
- Filter by status (Active, Completed, Cancelled)
- Search by date range
- Detailed booking information
- Receipt download
- Rebooking option

---

## 🚀 Getting Started

### **Prerequisites**

- Flutter SDK `>=3.19.0`
- Dart SDK `>=3.3.0`
- iOS 12.0+ or Android 5.0+
- Xcode 14+ (for iOS)
- Android Studio (for Android)

### **Installation**

#### **Step 1: Navigate to User App**
```bash
cd packages/apps/user_app
```

#### **Step 2: Install Dependencies**
```bash
flutter pub get
```

#### **Step 3: Configure Environment**

Create `.env` file in the root directory:

```env
# Appwrite Configuration
APPWRITE_ENDPOINT=https://cloud.appwrite.io/v1
APPWRITE_PROJECT_ID=your_project_id
APPWRITE_API_KEY=your_api_key

# Mapbox Configuration
MAPBOX_ACCESS_TOKEN=pk.your_mapbox_token
MAPBOX_STYLE_URL=mapbox://styles/mapbox/streets-v12
USE_MAPBOX=true
MAPBOX_DEFAULT_ZOOM=15.0

# Chapa Payment (Test Mode)
CHAPA_SECRET_KEY_TEST=CHASECK_TEST-your_key
CHAPA_PUBLIC_KEY_TEST=CHAPUBK_TEST-your_key

# App Settings
ENVIRONMENT=development
DEBUG_MODE=true
```

#### **Step 4: Run the App**

```bash
# Run on Android
flutter run

# Run on iOS
flutter run -d ios

# Run on specific device
flutter devices
flutter run -d <device-id>
```

### **Build for Production**

```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release

# iOS IPA
flutter build ipa --release
```

---

## 📦 Dependencies

### **Core Dependencies**

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Shared business logic
  shared:
    path: ../../shared
  
  # State Management
  flutter_riverpod: ^2.5.1
  
  # Navigation
  go_router: ^14.1.4
  
  # QR Code
  qr_flutter: ^4.1.0
  
  # Location Services
  geolocator: ^10.1.0
  
  # WebView for payments
  webview_flutter: ^4.4.2
  
  # PDF & File Operations
  pdf: ^3.10.7
  path_provider: ^2.1.2
  permission_handler: ^11.3.0
  
  # Environment Variables
  flutter_dotenv: ^5.1.0
```

---

## 🎨 UI/UX Design

### **Design Principles**

1. **Simplicity** - Clean, uncluttered interface
2. **Speed** - Fast loading, instant feedback
3. **Clarity** - Clear labels, obvious actions
4. **Consistency** - Uniform design language
5. **Accessibility** - Large touch targets, readable fonts

### **Color Scheme**

```dart
Primary: #FF9500 (Orange)
Secondary: #E68600 (Dark Orange)
Accent: #FFB347 (Light Orange)
Background: #F8F9FA
Text: #1A1A1A
Success: #28A745
Error: #DC3545
```

### **Typography**

- **Headings:** Bold, 24-32px
- **Body:** Regular, 16px
- **Captions:** Light, 14px
- **Buttons:** Medium, 16px

### **Animations**

- Screen transitions: 300ms ease-in-out
- Button press: 150ms scale animation
- Loading states: Shimmer effect
- Map markers: Bounce animation

---

## 🔧 Configuration

### **Permissions Required**

#### **Android** (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.CAMERA"/>
```

#### **iOS** (`ios/Runner/Info.plist`)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to find nearby parking spots</string>
<key>NSCameraUsageDescription</key>
<string>We need camera access to scan QR codes</string>
```

---

## 📸 Screenshots


### **Authentication**
![Sign In](screenshots/signin.png) ![Sign Up](screenshots/signup.png)

### **Home & Maps**
![Home](screenshots/home.png) ![Maps](screenshots/maps.png)

### **Booking & Payment**
![Booking](screenshots/booking.png) ![Payment](screenshots/payment.png)

### **History & Profile**
![History](screenshots/history.png) ![Profile](screenshots/profile.png)

---

## 🐛 Troubleshooting

### **Common Issues**

**1. Maps not loading**
```bash
# Check Mapbox token
echo $MAPBOX_ACCESS_TOKEN

# Verify internet connection
# Check Mapbox account status
```

**2. Payment failing**
```bash
# Verify Chapa API keys
# Check test credentials
# Review Chapa dashboard logs
```

**3. Location not working**
```bash
# Grant location permissions
# Enable GPS on device
# Check geolocator package version
```

---

## 🚀 Deployment

### **Android**

1. **Update version** in `pubspec.yaml`
2. **Build release APK**
   ```bash
   flutter build apk --release
   ```
3. **Upload to Google Play Console**

### **iOS**

1. **Update version** in `pubspec.yaml`
2. **Build release IPA**
   ```bash
   flutter build ipa --release
   ```
3. **Upload to App Store Connect**

---

## 📄 License

This app is part of the **ParkMe Plus** ecosystem, licensed under the MIT License.

---

<div align="center">

**Built with ❤️ for Ethiopian Drivers**

[Main Project](../../../README.md) • [Report Bug](https://github.com/your-org/parkme-plus/issues) • [Request Feature](https://github.com/your-org/parkme-plus/issues)

</div>