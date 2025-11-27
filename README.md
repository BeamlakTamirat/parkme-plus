<div align="center">

# 🅿️arkMe Plus - Smart Parking System

### *Where Finding Parking Becomes Effortless*

[![Flutter](https://img.shields.io/badge/Flutter-3.19.0+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.3.0+-0175C2?logo=dart)](https://dart.dev)
[![Appwrite](https://img.shields.io/badge/Appwrite-Cloud-F02E65?logo=appwrite)](https://appwrite.io)
[![Mapbox](https://img.shields.io/badge/Mapbox-Maps-000000?logo=mapbox)](https://mapbox.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)


**A next-generation smart parking ecosystem built with Flutter, powered by Appwrite, and designed for the Ethiopian market.**

[Features](#-features) • [Architecture](#-architecture) • [Getting Started](#-quick-start) • [Screenshots](#-screenshots) • [Apps](#-the-ecosystem)

<div align="center">

### 🚀 **Download Latest Release**

<a href="https://github.com/OzoneTechnologyDevelopment/parkme-plus/releases">
  <img src="https://img.shields.io/badge/📱%20Download%20Latest%20Release-FF9500?style=for-the-badge&logo=github&logoColor=white&labelColor=FF9500&color=white" alt="Download Latest Release" />
</a>

</div>

---

</div>

## 🎯 What is ParkMe Plus?

ParkMe Plus revolutionizes urban parking in Ethiopia by connecting drivers with available parking spots in real-time. Built as a **Flutter monorepo**, it delivers three interconnected applications that work seamlessly together:

- 🚗 **User App** - Find, book, and pay for parking instantly
- 🖥️ **Admin App** - Manage locations, monitor revenue, analyze data
- 📱 **Attendant App** - Scan QR codes, validate bookings, manage spots

## ✨ Features

### 🌟 For Drivers (User App)
- **Real-Time Availability** - See live parking spots on interactive Mapbox maps
- **Smart Search** - GPS-powered location finder with distance calculation
- **Instant Booking** - Reserve your spot in seconds with QR code generation
- **Ethiopian Payments** - Pay with Telebirr, CBE Birr, or international cards via Chapa
- **Booking History** - Track all your parking sessions and receipts
- **Navigation** - Get directions to your reserved parking spot

### 🎛️ For Operators (Admin Dashboard)
- **Live Dashboard** - Real-time occupancy tracking and revenue monitoring
- **Location Management** - Add/edit parking locations with Mapbox integration
- **User Analytics** - Comprehensive user behavior and booking insights
- **Revenue Reports** - Detailed financial analytics and transaction history
- **Spot Control** - Dynamic spot assignment (A1-A20, B1-B20 system)

### 📲 For Attendants (Tablet App)
- **QR Scanner** - Fast check-in/check-out with mobile_scanner
- **Booking Validation** - Verify payments and booking status instantly
- **Spot Management** - Real-time spot availability updates
- **Offline Support** - Continue operations during connectivity issues

## 🏗️ Architecture

### **Monorepo Structure**
```
parkme-plus/
├── packages/
│   ├── shared/                    # 🎁 Shared Package (Core Business Logic)
│   │   ├── models/                # Data models with JSON serialization
│   │   │   ├── booking/           # Booking, BookingHistory
│   │   │   ├── parking/           # ParkingLocation, ParkingSpot
│   │   │   ├── payment/           # Payment, ChapaPayment
│   │   │   ├── user/              # User, UserProfile, UserPreferences
│   │   │   └── vehicle/           # Vehicle model
│   │   ├── services/              # Business logic services
│   │   │   ├── auth/              # Authentication (Appwrite)
│   │   │   ├── database/          # Database operations (CRUD)
│   │   │   ├── payment/           # Chapa payment integration
│   │   │   ├── maps/              # Mapbox service
│   │   │   ├── booking/           # Booking management
│   │   │   ├── storage/           # File storage (Appwrite)
│   │   │   └── realtime/          # Real-time subscriptions
│   │   ├── config/                # Configuration
│   │   │   ├── appwrite_config.dart
│   │   │   ├── mapbox_config.dart
│   │   │   └── payment_config.dart
│   │   ├── widgets/               # Reusable UI components
│   │   └── theme/                 # Design system
│   │
│   └── apps/
│       ├── user_app/              # 📱 User Mobile App
│       ├── admin_app/             # 🖥️ Admin Web Dashboard
│       └── attendant_app/         # 📲 Attendant Tablet App
│
├── melos.yaml                     # Monorepo configuration
└── .env                           # Environment variables
```

### **Technology Stack**

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Frontend** | Flutter 3.19+ | Cross-platform UI framework |
| **State Management** | Riverpod 2.5+ | Reactive state management |
| **Backend** | Appwrite Cloud | Database, Auth, Storage, Realtime |
| **Maps** | Mapbox Maps Flutter | Real-world interactive maps |
| **Payments** | Chapa API | Ethiopian payment gateway |
| **QR Codes** | qr_flutter, mobile_scanner | QR generation & scanning |
| **Navigation** | go_router 14+ | Declarative routing |
| **Monorepo** | Melos | Multi-package management |

## 🚀 Quick Start

<details>
<summary><b>📋 Prerequisites</b></summary>

<br>

Before you begin, ensure you have:

- ✅ **Flutter SDK** `>=3.19.0` ([Install Flutter](https://flutter.dev/docs/get-started/install))
- ✅ **Dart SDK** `>=3.3.0` (comes with Flutter)
- ✅ **Melos CLI** for monorepo management
- ✅ **Appwrite Cloud Account** ([Sign up free](https://cloud.appwrite.io))
- ✅ **Mapbox Account** ([Get free token](https://account.mapbox.com))
- ✅ **Chapa Test Account** ([Ethiopian payment gateway](https://chapa.co))

</details>

<details>
<summary><b>📦 Step 1: Install Melos</b></summary>

<br>

```bash
dart pub global activate melos
```

</details>

<details>
<summary><b>📥 Step 2: Clone & Bootstrap</b></summary>

<br>

```bash
git clone https://github.com/your-org/parkme-plus.git
cd wepark
melos bootstrap
```

This command will:
- Install dependencies for all packages
- Link local packages together
- Generate necessary files

</details>

<details>
<summary><b>🔐 Step 3: Configure Environment Variables</b></summary>

<br>

Create `.env` files in each app directory with the following structure:

```env
# Appwrite Configuration
APPWRITE_ENDPOINT=https://cloud.appwrite.io/v1
APPWRITE_PROJECT_ID=your_project_id_here
APPWRITE_API_KEY=your_api_key_here

# Mapbox Configuration
MAPBOX_ACCESS_TOKEN=pk.your_mapbox_token_here
MAPBOX_STYLE_URL=mapbox://styles/mapbox/streets-v12
USE_MAPBOX=true
MAPBOX_DEFAULT_ZOOM=15.0

# Chapa Payment Configuration (Test Mode)
CHAPA_SECRET_KEY_TEST=CHASECK_TEST-your_secret_key
CHAPA_PUBLIC_KEY_TEST=CHAPUBK_TEST-your_public_key
CHAPA_WEBHOOK_SECRET=your_webhook_url

# App Configuration
ENVIRONMENT=development
DEBUG_MODE=true
```

> 💡 **Tip:** Copy `.env.example` to `.env` and fill in your credentials

</details>

<details>
<summary><b>☁️ Step 4: Setup Appwrite Backend</b></summary>

<br>

1. **Create Appwrite Project**
   - Go to [Appwrite Cloud](https://cloud.appwrite.io)
   - Create new project named "ParkMe Plus"
   - Copy your Project ID

2. **Create Database & Collections**
   ```
   Database: wepark_db
   
   Collections:
   - users (User profiles and preferences)
   - parking_locations (Parking lot information)
   - bookings (Parking reservations)
   ```

3. **Configure Authentication**
   - Enable Email/Password authentication
   - Set session duration to 365 days
   - Configure password requirements

4. **Set Permissions**
   - Users: Read/Write own documents
   - Admins: Full access
   - Attendants: Read bookings, Update bookings

</details>

<details>
<summary><b>▶️ Step 5: Run the Apps</b></summary>

<br>

```bash
# User Mobile App (Android/iOS)
cd packages/apps/user_app
flutter run

# Admin Web Dashboard
cd packages/apps/admin_app
flutter run -d chrome

# Attendant Tablet App
cd packages/apps/attendant_app
flutter run
```

</details>

<details>
<summary><b>🛠️ Melos Commands</b></summary>

<br>

```bash
# 📦 Install dependencies for all packages
melos get:all

# 🧪 Run tests across all packages
melos test:all

# 🔍 Analyze code quality
melos analyze

# 🧹 Clean all packages
melos clean:all

# 🏗️ Build all applications
melos build:all

# 🎯 Build specific apps
melos build:user-app        # Build user mobile app (APK)
melos build:admin-web       # Build admin web dashboard
melos build:attendant-app   # Build attendant tablet app
```

</details>

---

## 🔐 **Test Credentials & Access Levels**

> 🎯 **Ready to test?** Use these credentials to explore all three apps!

<details open>
<summary><h3>👨‍💼 <b>ADMIN ACCESS</b> - Full Control</h3></summary>

<br>

```
📧 Email:    testadmin@gmail.com
🔑 Password: testadmin
```

### **✨ What Admins Can Do:**

| Feature | Description |
|---------|-------------|
| 🗺️ **Manage Locations** | Add, edit, delete parking locations |
| 👥 **Control Users** | View, suspend, or promote users |
| 👨‍✈️ **Assign Attendants** | Assign ONE attendant to ONE location |
| 💰 **Revenue Analytics** | Real-time revenue tracking & reports |
| 📊 **Dashboard** | Live metrics across all locations |
| ⚙️ **System Settings** | Configure pricing, hours, amenities |

> 💡 **Pro Tip:** Admins can reassign attendants between locations anytime!

</details>

<details open>
<summary><h3>👨‍✈️ <b>ATTENDANT ACCESS</b> - Location Specific</h3></summary>

<br>

```
📧 Email:    testattendant@gmail.com
🔑 Password: testattendant
📍 Assigned: Bole Airport Parking (500 spots)
```

### **✨ What Attendants Can Do:**

| Feature | Description |
|---------|-------------|
| 📷 **QR Scanner** | Lightning-fast check-in/checkout |
| 🗺️ **Parking Grid** | 3D view of all spots (A1-A20, B1-B20) |
| ✅ **Verify Bookings** | Validate user reservations |
| 📊 **Shift Reports** | Track daily performance |
| 🔔 **Live Alerts** | Expiring bookings, new arrivals |

> ⚠️ **Important:** Each attendant is assigned to **ONE location only**. Admins can change assignments.

</details>

<details open>
<summary><h3>👤 <b>USER ACCESS</b> - Self Registration</h3></summary>

<br>

```
📱 Download the User App
➕ Create your account (Email + Password)
✅ Start booking parking spots!
```

### **✨ What Users Can Do:**

| Feature | Description |
|---------|-------------|
| 🔍 **Find Parking** | Search by location, price, availability |
| 📖 **Book Spots** | Reserve parking in advance |
| 💳 **Pay Securely** | Multiple payment methods via Chapa |
| 🎫 **Get QR Code** | Digital ticket for check-in |
| 📜 **View History** | All past bookings and receipts |
| ⭐ **Rate & Review** | Share parking experiences |

</details>

---

## 💳 **Payment Methods (Powered by Chapa)**

<details>
<summary><h3>💰 <b>Available Payment Options</b></h3></summary>

<br>

ParkMe Plus supports **6 payment methods** through Chapa - Ethiopia's leading payment gateway:

### **📱 Mobile Wallets**

| Method | Description | Test Credentials |
|--------|-------------|------------------|
| 📱 **Telebirr** | Most popular mobile money in Ethiopia | `0900112233` |
| 🏦 **CBE Birr** | Commercial Bank of Ethiopia wallet | `0900123456` |
| 📲 **M-Pesa** | Safaricom mobile money | `0700123456` |
| 🤝 **COOPPay-eBirr** | Cooperative Bank eBirr wallet | `0900881111` |

### **💳 International Cards**

| Method | Description | Test Credentials |
|--------|-------------|------------------|
| 💳 **Visa** | International credit/debit cards | Card: `4200 0000 0000 0000`<br>CVV: `123`<br>Expiry: `12/34` |
| 💳 **Mastercard** | International credit/debit cards | Card: `6200 0000 0000 0000`<br>CVV: `123`<br>Expiry: `12/34` |

### **🔒 Security Features**

- ✅ PCI-DSS Compliant
- ✅ End-to-end encryption
- ✅ Instant payment verification
- ✅ Automatic refunds for early checkout
- ✅ Transaction history & receipts

> 💡 **Note:** All test credentials work in development mode. Use real credentials in production.

</details>

---

## 🔧 Configuration Deep Dive

<details>
<summary><h3>📊 <b>Appwrite Collections Schema</b></h3></summary>

<br>

#### **`users` Collection**
```json
{
  "name": "string",
  "email": "string",
  "phone": "string",
  "role": "string",  // "user", "admin", "attendant"
  "profileImageUrl": "string",
  "createdAt": "datetime",
  "updatedAt": "datetime"
}
```

#### **`parking_locations` Collection**
```json
{
  "name": "string",
  "address": "string",
  "latitude": "double",
  "longitude": "double",
  "totalSpots": "integer",
  "availableSpots": "integer",
  "hourlyRate": "double",
  "isActive": "boolean",
  "amenities": "string",  // Comma-separated
  "attendantId": "string",  // ONE attendant per location
  "createdAt": "datetime",
  "updatedAt": "datetime"
}
```

#### **`bookings` Collection**
```json
{
  "userId": "string",
  "parkingLocationId": "string",
  "spotNumber": "string",
  "vehiclePlateNumber": "string",
  "startTime": "datetime",
  "endTime": "datetime",
  "totalAmount": "double",
  "status": "string",  // "pending", "active", "completed", "cancelled"
  "paymentStatus": "string",  // "pending", "paid", "failed"
  "qrCode": "string",
  "transactionId": "string",
  "createdAt": "datetime",
  "updatedAt": "datetime"
}
```

</details>

<details>
<summary><h3>🎨 <b>Design System</b></h3></summary>

<br>

### **Color Palette**
```dart
Primary Orange: #FF9500
Dark Orange: #E68600
Light Orange: #FFB347
Background: #F8F9FA
Text Dark: #1A1A1A
Text Light: #6C757D
Success: #28A745
Error: #DC3545
Warning: #FFC107
```

### **Typography**
- **Headings:** SF Pro Display (iOS) / Roboto (Android)
- **Body:** System default with fallbacks
- **Monospace:** Courier New (for codes)

### **Components**
- Consistent 16px border radius
- Elevation shadows for depth
- Smooth animations (200-300ms)
- Responsive layouts for all screen sizes

</details>

<details>
<summary><h3>📱 <b>The Ecosystem</b></h3></summary>

<br>

### **User Mobile App**
- **Platform:** iOS & Android
- **Screens:** 16 screens including auth, maps, booking, payment
- **Features:** Real-time maps, QR codes, payment integration
- **State:** Riverpod providers for auth, bookings, locations

### **Admin Web Dashboard**
- **Platform:** Web & Android
- **Screens:** Dashboard, locations, users, bookings, analytics
- **Features:** CRUD operations, charts, real-time monitoring
- **Responsive:** Desktop & tablet optimized

### **Attendant Tablet App**
- **Platform:** Android tablets
- **Screens:** Dashboard, QR scanner, booking details, spot management
- **Features:** Fast QR scanning, offline mode, simple UI
- **Optimized:** Large touch targets for tablet use

</details>

<details>
<summary><h3>🔒 <b>Security & Privacy</b></h3></summary>

<br>

- 🔐 **Appwrite Authentication** - Secure session management
- 🛡️ **Payment Security** - PCI-compliant via Chapa
- 🔑 **API Key Protection** - Environment variables only
- 👥 **Role-Based Access** - User, Admin, Attendant roles
- 📊 **Data Validation** - Input sanitization on all forms
- 🔒 **HTTPS Only** - Encrypted data transmission

</details>

<details>
<summary><h3>📊 <b>Analytics & Monitoring</b></h3></summary>

<br>

Track key metrics:
- 📈 **Revenue Analytics** - Daily, weekly, monthly reports
- 🚗 **Occupancy Rates** - Real-time and historical
- 👤 **User Behavior** - Booking patterns and preferences
- 💰 **Payment Success** - Transaction success rates
- ⏱️ **Performance** - App load times and API response

</details>

<details>
<summary><h3>🚀 <b>Deployment</b></h3></summary>

<br>

### **Mobile Apps**
```bash
# Build Android APK
cd packages/apps/user_app
flutter build apk --release

# Build iOS IPA
flutter build ipa --release

# Build App Bundle (Google Play)
flutter build appbundle --release
```

### **Web Dashboard**
```bash
cd packages/apps/admin_app
flutter build web --release
# Deploy to Firebase Hosting, Vercel, or Netlify
```

### **Backend**
- **Appwrite Cloud** - Managed hosting (recommended)
- **Self-Hosted** - Docker deployment on your server

</details>

---

## 📸 Screenshots


| User App | Admin Dashboard | Attendant App |
|----------|----------------|---------------|
| ![User](screenshots/user-home.png) | ![Admin](screenshots/admin-dashboard.png) | ![Attendant](screenshots/attendant-scanner.png) |

## 🤝 Contributing

🍀Contributions are welcome!

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

<div align="center">

**Built with ❤️ in Ethiopia**

[Report Bug](https://github.com/beamlaktamirat1/parkme-plus/issues) • [Request Feature](https://github.com/beamlaktamirat1/parkme-plus/issues) • [Documentation](https://github.com/beamlaktamirat1/parkme-plus)

</div>