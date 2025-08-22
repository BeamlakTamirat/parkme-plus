# WePark Attendant App

A simple, core-functionality attendant app for managing parking operations.

## 🎯 Core Features

### ✅ **Authentication**
- Role-based login (attendants only)
- Secure session management
- Admin role validation

### ✅ **QR Code Scanner**
- Real-time QR code scanning
- Booking verification
- Check-in/check-out functionality
- Status updates (pending → active → completed)

### ✅ **Dashboard**
- Welcome section with attendant info
- Assigned location overview
- Quick stats (total bookings, active bookings)
- Quick action buttons

### ✅ **Booking Management**
- View all bookings for assigned location
- Detailed booking information
- Status management
- Vehicle information display

### ✅ **Spot Management**
- Visual parking spot grid
- Real-time availability status
- Occupied/available spot indicators
- Spot details and current bookings

## 🗄️ Database Integration

Uses the existing **COMPREHENSIVE_DATABASE_SETUP.md** structure:
- **Users Collection**: Attendant authentication with role validation
- **Parking Locations Collection**: Location assignment
- **Bookings Collection**: Real-time booking management

## 🛠️ Tech Stack

- **Flutter**: UI framework
- **Riverpod**: State management
- **GoRouter**: Navigation
- **Shared Package**: Reuses all backend services
- **QR Code Scanner**: For booking verification
- **Permission Handler**: Camera permissions

## 📱 App Flow

1. **Login** → Role validation (attendants only)
2. **Dashboard** → Overview of assigned location and stats
3. **QR Scanner** → Scan booking QR codes for check-in/out
4. **Booking Details** → View and manage individual bookings
5. **Spot Management** → Visual overview of parking availability

## 🔧 Setup

1. Ensure main `.env` file exists in project root
2. Run `flutter pub get`
3. Connect device or start emulator
4. Run `flutter run`

## 🔐 Access Requirements

- User must have `role: 'attendant'` in the database
- Attendant must be assigned to a parking location via `attendantId` field

## 🎮 Usage

1. **Login** with attendant credentials
2. **Scan QR codes** from user bookings to check vehicles in/out
3. **Monitor parking spots** through the spot management screen
4. **View booking details** for any issues or questions

## 🚀 Simple & Efficient

- **No over-engineering**: Core functionality only
- **Reuses existing backend**: Shared services and database
- **Clean UI**: Focused on essential operations
- **Real-time updates**: Automatic data refresh
- **Error handling**: Graceful fallbacks and user feedback

Perfect for parking attendants to efficiently manage their assigned location! 🅿️