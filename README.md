# WePark - Smart Parking System

A comprehensive smart parking solution built with Flutter and **Appwrite**, enabling users to find, book, and pay for parking spots in real-time.

## 🏗️ Project Structure

This is a monorepo containing multiple Flutter applications:

- **User App** (Mobile) - iOS & Android app for end users
- **Admin Panel** (Web) - Web dashboard for parking operators  
- **Attendant App** (Tablet) - Tablet app for parking attendants

## 📱 Applications

### User App Features
- Real-time parking availability
- GPS-based parking search
- QR code check-in/out
- Multiple payment methods (Telebirr, CBE Birr, Cards)
- Booking history and management
- Push notifications

### Admin Panel Features  
- Real-time occupancy dashboard
- Location and spot management
- User management
- Revenue analytics and reports
- Dynamic pricing configuration

### Attendant App Features
- QR code scanning for vehicle check-in/out
- Booking validation
- Simple tablet-optimized interface

## 🛠️ Tech Stack

- **Frontend**: Flutter (Mobile & Web)
- **Backend**: Appwrite (Database, Auth, Storage, Functions)
- **Payments**: Chapa (Telebirr, CBE Birr, Cards)
- **State Management**: Riverpod
- **Monorepo Tool**: Melos

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (^3.19.0)
- Dart SDK (^3.3.0)
- Appwrite Cloud account or self-hosted instance
- Melos CLI

### Installation

1. **Install Melos**
   ```bash
   dart pub global activate melos
   ```

2. **Clone and Setup**
   ```bash
   git clone <repository-url>
   cd wepark
   melos bootstrap
   ```

3. **Configure Environment**
   - Setup Appwrite project (see `APPWRITE_SETUP.md`)
   - Add Chapa API keys
   - Configure Google Maps API

### Development Commands

```bash
# Get dependencies for all packages
melos get:all

# Run tests for all packages
melos test:all

# Analyze all packages
melos analyze

# Build all applications
melos build:all

# Build specific apps
melos build:user-app
melos build:admin-web
melos build:attendant-app
```

## 🔧 Configuration

### Appwrite Setup
1. Create Appwrite project (Cloud or self-hosted)
2. Configure authentication, database, storage
3. Setup collections and permissions
4. Add configuration to `.env` files

**📋 See `APPWRITE_SETUP.md` for detailed instructions**

### Chapa Integration
1. Get API keys from Chapa
2. Configure webhook endpoints
3. Setup payment methods

## 📦 Package Structure

```
packages/
├── shared/           # Shared models, services, widgets
├── apps/
│   ├── user_app/     # Mobile app for users
│   ├── admin_panel/  # Web dashboard
│   └── attendant_app/ # Tablet app
```

## 🎨 Design System

The app follows a consistent design system with:
- Orange primary color (#FF9500)
- Clean typography using system fonts
- Consistent spacing and shadows
- Reusable components across apps

## 🔒 Security

- Appwrite Authentication with multiple providers
- Secure payment processing via Chapa
- Role-based access control (RBAC)
- Data validation and sanitization

## 📊 Analytics

- User behavior tracking
- Revenue analytics
- Occupancy monitoring
- Performance metrics

## 🚀 Deployment

### Mobile Apps
- User App: Google Play Store & Apple App Store
- Attendant App: Internal distribution or Play Store

### Web App
- Admin Panel: Flutter Web hosted on your preferred platform

### Backend
- Appwrite Cloud or self-hosted Appwrite instance



## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.