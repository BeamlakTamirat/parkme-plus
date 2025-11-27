<div align="center">

# 🖥️ ParkMe Plus - Admin App / Dashboard

### *Command Center for Smart Parking Operations*

[![Platform](https://img.shields.io/badge/Platform-Web-blue)](https://flutter.dev)
[![Flutter](https://img.shields.io/badge/Flutter-3.19.0+-02569B?logo=flutter)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](../../../LICENSE)

**Powerful dashboard for managing parking locations, monitoring revenue, and analyzing user behavior.**

</div>

---

## 🎯 What is This App?

The **ParkMe Plus Admin Dashboard** is a comprehensive application built with Flutter that gives parking operators complete control over their parking ecosystem. Monitor real-time occupancy, manage locations, track revenue, and gain insights - all from a beautiful, responsive interface.

### **Key Highlights**

📊 **Live Dashboard** - Real-time occupancy and revenue tracking  
🗺️ **Location Management** - Add/edit parking locations with Mapbox  
👥 **User Management** - View and manage user accounts  
💰 **Revenue Analytics** - Detailed financial reports and insights  
📈 **Booking Analytics** - Track booking patterns and trends  
🎯 **Spot Control** - Dynamic spot assignment and availability  

---

## 🏗️ App Architecture

### **Screen Structure**

```
admin_app/
├── lib/
│   └── src/
│       ├── screens/
│       │   ├── auth/                    # 🔐 Admin Authentication
│       │   │   └── login_screen.dart
│       │   │
│       │   ├── home/                    # 🏠 Main Dashboard
│       │   │   └── dashboard_screen.dart
│       │   │
│       │   ├── locations/               # 🗺️ Parking Location Management
│       │   │   └── locations_management_screen.dart
│       │   │
│       │   ├── users/                   # 👥 User Management
│       │   │   └── users_management_screen.dart
│       │   │
│       │   ├── bookings/                # 📝 Booking Management
│       │   │   └── bookings_overview_screen.dart
│       │   │
│       │   └── analytics/               # 📊 Analytics & Reports
│       │       └── analytics_screen.dart
│       │
│       ├── providers/                   # 🔄 Riverpod state management
│       │   ├── auth_provider.dart
│       │   ├── location_provider.dart
│       │   └── analytics_provider.dart
│       │
│       └── routes/                      # 🛣️ Navigation routes
│           └── app_router.dart
│
└── pubspec.yaml
```

### **State Management**

```dart
// Admin-specific providers
final adminAuthProvider = StateNotifierProvider<AdminAuthNotifier, AdminAuthState>((ref) {
  return AdminAuthNotifier();
});

final locationsProvider = FutureProvider<List<ParkingLocation>>((ref) async {
  return await DatabaseService.instance.getAllParkingLocations();
});

final revenueAnalyticsProvider = FutureProvider<RevenueData>((ref) async {
  return await AnalyticsService.instance.getRevenueData();
});
```

---

## ✨ Features Deep Dive

### **1. 📊 Live Dashboard**

**Real-Time Metrics:**
- Total revenue (today, week, month, year)
- Active bookings count
- Total users registered
- Parking occupancy rates
- Recent transactions
- Top performing locations

**Visual Components:**
- Revenue charts (line, bar, pie)
- Occupancy heat maps
- Booking trend graphs
- User growth analytics

**Refresh Intervals:**
- Real-time updates via Appwrite Realtime
- Auto-refresh every 30 seconds
- Manual refresh button

### **2. 🗺️ Location Management**

**Features:**
- **Add New Locations** - Create parking lots with Mapbox integration
- **Edit Locations** - Update details, pricing, amenities
- **Delete Locations** - Remove inactive parking lots
- **View on Map** - Interactive Mapbox visualization
- **Assign Attendants** - Link attendants to specific locations
- **Manage Spots** - Configure total and available spots

**Location Details:**
```dart
{
  "name": "string",
  "address": "string",
  "latitude": "double",
  "longitude": "double",
  "totalSpots": "integer",
  "hourlyRate": "double",
  "amenities": ["CCTV", "24/7", "Covered"],
  "attendantId": "string",
  "isActive": "boolean"
}
```

**Bulk Operations:**
- Import locations from CSV
- Export location data
- Bulk price updates
- Batch activation/deactivation

### **3. 👥 User Management**

**User Overview:**
- Total registered users
- Active users (last 30 days)
- User growth trends
- User segmentation (regular, premium, inactive)

**User Actions:**
- View user profiles
- Check booking history
- Monitor payment history
- Send notifications
- Suspend/activate accounts
- Export user data

**Search & Filter:**
- Search by name, email, phone
- Filter by registration date
- Filter by booking count
- Sort by various criteria

### **4. 📝 Booking Management**

**Booking Overview:**
- All bookings (active, completed, cancelled)
- Booking status distribution
- Average booking duration
- Peak booking times

**Booking Details:**
- User information
- Parking location
- Vehicle details
- Payment status
- QR code
- Transaction ID

**Actions:**
- Cancel bookings
- Extend bookings
- Refund payments
- Export booking data
- Generate reports

### **5. 💰 Revenue Analytics**

**Financial Metrics:**
- Total revenue (all-time, monthly, weekly, daily)
- Revenue by location
- Revenue by payment method
- Average transaction value
- Revenue growth rate

**Payment Breakdown:**
- Telebirr transactions
- CBE Birr transactions
- Card payments
- Failed payments
- Refunds

**Reports:**
- Daily revenue reports
- Monthly financial statements
- Location performance reports
- Payment method analysis
- Export to PDF/Excel

### **6. 📈 Analytics & Insights**

**User Analytics:**
- New user registrations
- User retention rate
- User lifetime value
- Churn rate

**Booking Analytics:**
- Booking frequency
- Peak hours analysis
- Average booking duration
- Cancellation rate
- No-show rate

**Location Analytics:**
- Occupancy rates by location
- Revenue per location
- Popular locations
- Underperforming locations

---

## 🚀 Getting Started

### **Prerequisites**

- Flutter SDK `>=3.19.0`
- Dart SDK `>=3.3.0`
- Modern web browser (Chrome, Firefox, Safari, Edge)
- Appwrite Cloud account

### **Installation**

#### **Step 1: Navigate to Admin App**
```bash
cd packages/apps/admin_app
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

# Mapbox Configuration (for location management)
MAPBOX_ACCESS_TOKEN=pk.your_mapbox_token

# App Settings
ENVIRONMENT=development
DEBUG_MODE=true
```

#### **Step 4: Run the App**

```bash
# Run on Chrome
flutter run -d chrome

# Run on Edge
flutter run -d edge

# Run on Firefox
flutter run -d firefox

# Run with hot reload
flutter run -d chrome --web-hot-reload
```

### **Build for Production**

```bash
# Build optimized web app
flutter build web --release

# Build with web renderer
flutter build web --release --web-renderer canvaskit

# Build with HTML renderer (smaller size)
flutter build web --release --web-renderer html
```

**Output:** `build/web/` directory ready for deployment

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
  
  # Image Picking (for location images)
  image_picker: ^1.0.4
```

---

## 🎨 UI/UX Design

### **Design Principles**

1. **Data Density** - Show maximum information efficiently
2. **Clarity** - Clear visual hierarchy and labels
3. **Responsiveness** - Works on desktop, tablet, mobile
4. **Speed** - Fast loading with lazy loading
5. **Accessibility** - Keyboard navigation, screen readers

### **Layout**

- **Sidebar Navigation** - Quick access to all sections
- **Top Bar** - User profile, notifications, search
- **Main Content** - Dashboard, tables, charts
- **Responsive Grid** - Adapts to screen size

### **Color Scheme**

```dart
Primary: #FF9500 (Orange)
Secondary: #E68600 (Dark Orange)
Background: #F8F9FA
Sidebar: #FFFFFF
Text: #1A1A1A
Success: #28A745
Error: #DC3545
Warning: #FFC107
Info: #17A2B8
```

### **Components**

- **Data Tables** - Sortable, filterable, paginated
- **Charts** - Line, bar, pie, donut
- **Cards** - Metric cards with icons
- **Modals** - For forms and confirmations
- **Dropdowns** - For filters and actions

---

## 🔧 Configuration

### **Admin Roles & Permissions**

```dart
enum AdminRole {
  superAdmin,  // Full access
  admin,       // Most features
  operator,    // Limited access
  viewer,      // Read-only
}

// Permission matrix
Permissions {
  superAdmin: [all],
  admin: [locations, users, bookings, analytics],
  operator: [locations, bookings],
  viewer: [dashboard, analytics],
}
```

### **Dashboard Customization**

```dart
// Customize dashboard widgets
DashboardConfig {
  widgets: [
    RevenueCard(),
    ActiveBookingsCard(),
    OccupancyChart(),
    RecentTransactions(),
  ],
  refreshInterval: Duration(seconds: 30),
  theme: DashboardTheme.light,
}
```

---

## 📊 Data Tables

### **Features**

- **Sorting** - Click column headers to sort
- **Filtering** - Filter by multiple criteria
- **Pagination** - Navigate large datasets
- **Search** - Quick search across columns
- **Export** - Download as CSV/Excel/PDF
- **Bulk Actions** - Select multiple rows

### **Example: Locations Table**

| Name | Address | Spots | Rate | Occupancy | Status | Actions |
|------|---------|-------|------|-----------|--------|---------|
| Bole Parking | Bole Road | 50 | 50 ETB/hr | 80% | Active | Edit \| Delete |
| Piassa Lot | Piassa | 30 | 40 ETB/hr | 60% | Active | Edit \| Delete |

---

## 📈 Charts & Visualizations

### **Chart Types**

1. **Line Charts** - Revenue trends over time
2. **Bar Charts** - Location comparisons
3. **Pie Charts** - Payment method distribution
4. **Donut Charts** - Booking status breakdown
5. **Area Charts** - User growth
6. **Heat Maps** - Peak hours visualization

### **Chart Libraries**

- **fl_chart** - Beautiful Flutter charts
- **syncfusion_flutter_charts** - Advanced charts
- **charts_flutter** - Google Charts for Flutter

---

## 🔒 Security

### **Authentication**

- Admin-only access with Appwrite Auth
- Role-based access control (RBAC)
- Session management
- Two-factor authentication (optional)

### **Data Protection**

- HTTPS only
- API key protection
- Input validation
- SQL injection prevention
- XSS protection

### **Audit Logs**

Track all admin actions:
- Who made changes
- What was changed
- When it happened
- IP address
- Device information

---

## 🚀 Deployment

### **Hosting Options**

#### **1. Firebase Hosting** (Recommended)
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase
firebase init hosting

# Deploy
firebase deploy
```

#### **2. Vercel**
```bash
# Install Vercel CLI
npm install -g vercel

# Deploy
vercel --prod
```

#### **3. Netlify**
```bash
# Install Netlify CLI
npm install -g netlify-cli

# Deploy
netlify deploy --prod --dir=build/web
```

#### **4. GitHub Pages**
```bash
# Build
flutter build web --release --base-href "/parkme-plus/"

# Deploy to gh-pages branch
git subtree push --prefix build/web origin gh-pages
```

### **Environment Variables**

Set environment variables in your hosting platform:
```
APPWRITE_ENDPOINT=https://cloud.appwrite.io/v1
APPWRITE_PROJECT_ID=your_project_id
MAPBOX_ACCESS_TOKEN=pk.your_token
```

---

## 📸 Screenshots


### **Dashboard**
![Dashboard](screenshots/dashboard.png)

### **Location Management**
![Locations](screenshots/locations.png)

### **Analytics**
![Analytics](screenshots/analytics.png)

---

## 🐛 Troubleshooting

### **Common Issues**

**1. CORS errors**
```bash
# Run with CORS disabled (development only)
flutter run -d chrome --web-browser-flag "--disable-web-security"
```

**2. Slow loading**
```bash
# Use HTML renderer for better performance
flutter build web --web-renderer html
```

**3. Appwrite connection issues**
```bash
# Check Appwrite endpoint
# Verify API keys
# Check network connectivity
```

---

## 📄 License

This app is part of the **ParkMe Plus** ecosystem, licensed under the MIT License.

---

<div align="center">

**Built with ❤️ for Parking Operators**

[Main Project](../../../README.md) • [Report Bug](https://github.com/your-org/parkme-plus/issues) • [Request Feature](https://github.com/your-org/parkme-plus/issues)

</div>
