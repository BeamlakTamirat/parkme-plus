<div align="center">

# 📲 ParkMe Plus - Attendant Tablet App

### *Streamlined Parking Operations at Your Fingertips*

[![Platform](https://img.shields.io/badge/Platform-Android%20Tablet-green)](https://flutter.dev)
[![Flutter](https://img.shields.io/badge/Flutter-3.19.0+-02569B?logo=flutter)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](../../../LICENSE)

**Fast, simple, and powerful tablet app for parking attendants to manage check-ins, verify bookings, and monitor spots.**

</div>

---

## 🎯 What is This App?

The **ParkMe Plus Attendant App** is a tablet-optimized application designed specifically for parking lot attendants. With a focus on speed and simplicity, it enables attendants to scan QR codes, verify bookings, manage parking spots, and monitor their assigned location - all with large, easy-to-tap controls perfect for tablets.

### **Key Highlights**

📷 **Lightning-Fast QR Scanner** - Scan booking QR codes in milliseconds  
✅ **Instant Verification** - Validate bookings and payment status  
🅿️ **Visual Spot Grid** - See all parking spots at a glance  
📊 **Real-Time Dashboard** - Monitor bookings and occupancy  
🔄 **Offline Support** - Continue operations during connectivity issues  
🎯 **Tablet-Optimized** - Large touch targets, clear visuals  

---

## 🏗️ App Architecture

### **Screen Structure**

```
attendant_app/
├── lib/
│   └── src/
│       ├── screens/
│       │   ├── auth/                    # 🔐 Attendant Authentication
│       │   │   └── login_screen.dart
│       │   │
│       │   ├── home/                    # 🏠 Dashboard
│       │   │   └── dashboard_screen.dart
│       │   │
│       │   ├── scanner/                 # 📷 QR Code Scanner
│       │   │   └── qr_scanner_screen.dart
│       │   │
│       │   ├── bookings/                # 📝 Booking Details
│       │   │   └── booking_details_screen.dart
│       │   │
│       │   └── spots/                   # 🅿️ Spot Management
│       │       └── spot_management_screen.dart
│       │
│       ├── providers/                   # 🔄 Riverpod state management
│       │   ├── auth_provider.dart
│       │   ├── booking_provider.dart
│       │   └── location_provider.dart
│       │
│       └── routes/                      # 🛣️ Navigation routes
│           └── app_router.dart
│
└── pubspec.yaml
```

### **State Management**

```dart
// Attendant-specific providers
final attendantAuthProvider = StateNotifierProvider<AttendantAuthNotifier, AttendantAuthState>((ref) {
  return AttendantAuthNotifier();
});

final assignedLocationProvider = FutureProvider<ParkingLocation?>((ref) async {
  final attendant = ref.watch(attendantAuthProvider);
  return await DatabaseService.instance.getAttendantLocation(attendant.id);
});

final locationBookingsProvider = StreamProvider<List<Booking>>((ref) {
  final location = ref.watch(assignedLocationProvider).value;
  return DatabaseService.instance.watchLocationBookings(location?.id ?? '');
});
```

---

## ✨ Features Deep Dive

### **1. 🔐 Role-Based Authentication**

**Attendant Login:**
- Email/password authentication via Appwrite
- Role validation (attendants only)
- Automatic location assignment check
- Session persistence

**Security:**
```dart
// Only users with role='attendant' can access
if (user.role != 'attendant') {
  throw Exception('Access denied: Attendant role required');
}

// Must be assigned to a location
if (attendant.assignedLocationId == null) {
  throw Exception('No location assigned to this attendant');
}
```

### **2. 📷 QR Code Scanner**

**Powered by mobile_scanner**

**Features:**
- **Ultra-Fast Scanning** - Detects QR codes in <100ms
- **Auto-Focus** - Sharp scanning in any lighting
- **Torch Support** - Built-in flashlight for dark areas
- **Vibration Feedback** - Haptic confirmation on scan
- **Sound Alerts** - Audio feedback for successful scans

**QR Code Format:**
```
PARKME_${bookingId}_${userId}_${timestamp}
```

**Scan Flow:**
1. User shows QR code from mobile app
2. Attendant scans code
3. App fetches booking details
4. Validates payment status
5. Updates booking status (check-in/check-out)
6. Shows confirmation

**Status Updates:**
```dart
// Check-in flow
pending → active (vehicle entered)

// Check-out flow
active → completed (vehicle exited)
```

### **3. 🏠 Dashboard**

**Real-Time Metrics:**
- **Assigned Location** - Name, address, total spots
- **Total Bookings Today** - Count of all bookings
- **Active Bookings** - Currently parked vehicles
- **Available Spots** - Real-time availability
- **Revenue Today** - Total earnings for the day

**Quick Actions:**
- 📷 **Scan QR Code** - Jump to scanner
- 🅿️ **View Spots** - Check parking grid
- 📋 **View Bookings** - See all bookings
- 🔄 **Refresh Data** - Manual refresh

**Visual Design:**
- Large metric cards with icons
- Color-coded status indicators
- Easy-to-read typography (18-24px)
- High contrast for outdoor visibility

### **4. 📝 Booking Management**

**Booking List:**
- All bookings for assigned location
- Filter by status (Active, Completed, Pending)
- Search by vehicle plate number
- Sort by time, spot number, status

**Booking Details:**
```dart
{
  "bookingId": "string",
  "userName": "string",
  "userPhone": "string",
  "vehiclePlateNumber": "string",
  "vehicleModel": "string",
  "vehicleColor": "string",
  "spotNumber": "string",
  "startTime": "datetime",
  "endTime": "datetime",
  "totalAmount": "double",
  "paymentStatus": "paid/pending",
  "status": "active/completed/pending"
}
```

**Actions:**
- **View Details** - Full booking information
- **Check In** - Mark vehicle as entered
- **Check Out** - Mark vehicle as exited
- **Call User** - Quick phone call
- **View QR Code** - Display booking QR

### **5. 🅿️ Visual Spot Management**

**Parking Grid View:**
- Visual representation of all spots (A1-A20, B1-B20)
- Color-coded status:
  - 🟢 **Green** - Available
  - 🔴 **Red** - Occupied
  - 🟡 **Yellow** - Reserved (pending check-in)
  - ⚪ **Gray** - Out of service

**Spot Details:**
- Tap any spot to see details
- Current booking information
- Vehicle details if occupied
- Time remaining
- Quick actions (check-out, view booking)

**Grid Layout:**
```
Row A: [A1] [A2] [A3] ... [A20]
Row B: [B1] [B2] [B3] ... [B20]
```

### **6. 🔄 Real-Time Updates**

**Appwrite Realtime Integration:**
```dart
// Subscribe to location bookings
final subscription = Realtime(client).subscribe([
  'databases.wepark_db.collections.bookings.documents'
]);

subscription.stream.listen((response) {
  // Auto-refresh when bookings change
  refreshBookings();
});
```

**Auto-Refresh:**
- New bookings appear instantly
- Status changes update in real-time
- Spot availability updates automatically
- No manual refresh needed

### **7. 📴 Offline Support**

**Offline Capabilities:**
- View cached booking data
- Access spot grid (last known state)
- Queue actions for when online
- Visual offline indicator

**Sync on Reconnect:**
- Automatic data sync when connection restored
- Conflict resolution
- User notification of sync status

---

## 🚀 Getting Started

### **Prerequisites**

- Flutter SDK `>=3.19.0`
- Dart SDK `>=3.3.0`
- Android tablet (8" or larger recommended)
- Camera permission for QR scanning
- Appwrite Cloud account

### **Installation**

#### **Step 1: Navigate to Attendant App**
```bash
cd packages/apps/attendant_app
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

# App Settings
ENVIRONMENT=development
DEBUG_MODE=true
```

#### **Step 4: Run the App**

```bash
# Run on connected Android tablet
flutter run

# Run on specific device
flutter devices
flutter run -d <device-id>

# Run in release mode for better performance
flutter run --release
```

### **Build for Production**

```bash
# Build Android APK
flutter build apk --release

# Build for specific tablet resolution
flutter build apk --release --target-platform android-arm64
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
  
  # QR Code Scanning
  mobile_scanner: ^5.0.0
  
  # Permissions
  permission_handler: ^11.3.0
```

---

## 🎨 UI/UX Design

### **Design Principles**

1. **Large Touch Targets** - Minimum 60x60px for easy tapping
2. **High Contrast** - Readable in bright outdoor light
3. **Simple Navigation** - Maximum 3 taps to any feature
4. **Clear Feedback** - Visual, audio, haptic confirmations
5. **Minimal Text Input** - Rely on scanning and tapping

### **Tablet Optimization**

- **Landscape Mode** - Primary orientation
- **Portrait Support** - Also works vertically
- **Large Fonts** - 18-24px for body text
- **Spacious Layout** - Generous padding and margins
- **Grid Layouts** - Efficient use of screen space

### **Color Scheme**

```dart
Primary: #FF9500 (Orange)
Success: #28A745 (Green) - Available spots
Error: #DC3545 (Red) - Occupied spots
Warning: #FFC107 (Yellow) - Reserved spots
Info: #17A2B8 (Blue) - Information
Background: #F8F9FA
```

### **Accessibility**

- **Large Text** - Easy to read from distance
- **Color + Icons** - Not relying on color alone
- **Voice Feedback** - Optional audio announcements
- **Haptic Feedback** - Vibration on actions

---

## 🔧 Configuration

### **Permissions Required**

#### **Android** (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.FLASHLIGHT"/>
```

### **Attendant Setup in Database**

**Step 1: Create Attendant User**
```json
{
  "name": "John Doe",
  "email": "john@parkmeplus.et",
  "role": "attendant",
  "phone": "0911234567"
}
```

**Step 2: Assign to Location**
```json
{
  "locationId": "location_123",
  "attendantId": "user_456"
}
```

**Step 3: Attendant Can Login**
- Use email and password
- App validates role
- Loads assigned location

---

## 📱 User Flow

### **Typical Day for Attendant**

**Morning:**
1. Login to app
2. Review dashboard (spots available, bookings today)
3. Check spot grid status

**During Operations:**
1. User arrives → Scan QR code → Check-in
2. Monitor dashboard for new bookings
3. Assist users with questions
4. User leaves → Scan QR code → Check-out

**End of Day:**
1. Review completed bookings
2. Check revenue total
3. Logout

---

## 🔒 Security

### **Access Control**

- **Role Validation** - Only attendants can login
- **Location Binding** - Can only see assigned location
- **Session Management** - Auto-logout after inactivity
- **Secure Storage** - Credentials encrypted locally

### **Data Protection**

- **HTTPS Only** - All API calls encrypted
- **No Sensitive Data Storage** - Payment info not cached
- **Audit Trail** - All actions logged
- **Permission Checks** - Camera access on-demand

---

## 📸 Screenshots

### **Dashboard**
![Dashboard](screenshots/dashboard.png)

### **QR Scanner**
![Scanner](screenshots/scanner.png)

### **Spot Grid**
![Spots](screenshots/spots.png)

---

## 🐛 Troubleshooting

### **Common Issues**

**1. QR Scanner not working**
```bash
# Grant camera permission
# Check if camera is working in other apps
# Restart the app
# Clean and rebuild: flutter clean && flutter pub get
```

**2. Bookings not loading**
```bash
# Check internet connection
# Verify Appwrite endpoint
# Check attendant is assigned to location
# Review Appwrite console for errors
```

**3. Slow performance**
```bash
# Run in release mode: flutter run --release
# Clear app cache
# Restart device
```

---

## 🚀 Deployment

### **Internal Distribution**

**Option 1: Direct APK Install**
```bash
# Build APK
flutter build apk --release

# Transfer to tablet via USB or cloud
# Install APK on tablet
```

**Option 2: Google Play Internal Testing**
```bash
# Build App Bundle
flutter build appbundle --release

# Upload to Google Play Console
# Add attendants as internal testers
```

**Option 3: Firebase App Distribution**
```bash
# Build APK
flutter build apk --release

# Upload to Firebase
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
  --app YOUR_APP_ID \
  --groups attendants
```

---

## 📄 License

This app is part of the **ParkMe Plus** ecosystem, licensed under the MIT License.

---

<div align="center">

**Built with ❤️ for Parking Attendants**

[Main Project](../../../README.md) • [Report Bug](https://github.com/your-org/parkme-plus/issues) • [Request Feature](https://github.com/your-org/parkme-plus/issues)

</div>