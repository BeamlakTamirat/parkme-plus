 # WePark Backend Implementation Guide

## 🏗️ Architecture Overview

The WePark backend is built using a **Firebase + Supabase hybrid architecture** that provides:

- **Firebase**: Authentication, Firestore database, Cloud Functions, Analytics, Crashlytics
- **Supabase**: Cost-effective storage for images and files
- **Chapa**: Ethiopian payment gateway integration
- **Real-time updates**: Live parking availability and booking status
- **Comprehensive security**: Role-based access control and data validation

## 📱 Supported Applications

This backend supports three applications:
1. **User Mobile App** - Flutter mobile app for users
2. **Admin Web Panel** - Flutter web app for administrators  
3. **Attendant Tablet App** - Flutter tablet app for parking attendants

## 🔧 Setup Instructions

### 1. Firebase Setup

#### Create Firebase Project
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Create new project
firebase projects:create wepark-smart-parking
```

#### Configure Firebase Services
1. **Authentication**
   - Enable Email/Password authentication
   - Enable Google authentication
   - Configure authorized domains

2. **Firestore Database**
   - Create database in production mode
   - Deploy security rules: `firebase deploy --only firestore:rules`

3. **Cloud Functions**
   - Initialize functions: `firebase init functions`
   - Deploy functions: `firebase deploy --only functions`

4. **Analytics & Crashlytics**
   - Enable Firebase Analytics
   - Enable Firebase Crashlytics

#### Firebase Configuration Files
Add these to your Flutter apps:

**Android**: `android/app/google-services.json`
**iOS**: `ios/Runner/GoogleService-Info.plist`  
**Web**: Firebase config in `web/index.html`

### 2. Supabase Setup

#### Create Supabase Project
1. Go to [supabase.com](https://supabase.com)
2. Create new project
3. Note your project URL and anon key

#### Create Storage Buckets
```sql
-- Create storage buckets
INSERT INTO storage.buckets (id, name, public) VALUES 
('profile-images', 'profile-images', true),
('parking-images', 'parking-images', true),
('vehicle-images', 'vehicle-images', true),
('documents', 'documents', false),
('qr-codes', 'qr-codes', true),
('receipts', 'receipts', false);
```

#### Setup Storage Policies
```sql
-- Allow authenticated users to upload profile images
CREATE POLICY "Users can upload their own profile images" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'profile-images' AND 
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Allow public read access to parking images
CREATE POLICY "Public read access to parking images" ON storage.objects
FOR SELECT USING (bucket_id = 'parking-images');
```

### 3. Chapa Payment Gateway Setup

#### Get Chapa API Keys
1. Visit [chapa.co](https://chapa.co)
2. Register for business account
3. Get test and production API keys

#### Configure Webhook
Set webhook URL in Chapa dashboard:
- **Test**: `https://your-functions-url/api/webhooks/chapa`
- **Production**: `https://your-domain.com/api/webhooks/chapa`

### 4. Environment Configuration

Create environment files for each app:

#### User App (`packages/apps/user_app/.env`)
```env
FIREBASE_PROJECT_ID=wepark-smart-parking
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
CHAPA_PUBLIC_KEY=CHAPUBK_TEST-your-public-key
GOOGLE_MAPS_API_KEY=your-maps-api-key
```

#### Shared Package (`packages/shared/.env`)
```env
# Copy all configuration values
# This will be used by all apps
```

## 🗄️ Database Schema

### Firestore Collections

#### Users Collection (`users`)
```dart
{
  "id": "string",
  "email": "string",
  "full_name": "string", 
  "phone_number": "string?",
  "profile_image_url": "string?",
  "role": "user|admin|attendant|superAdmin",
  "is_email_verified": "boolean",
  "is_active": "boolean",
  "preferences": {
    "notifications_enabled": "boolean",
    "location_sharing": "boolean"
  },
  "created_at": "timestamp",
  "updated_at": "timestamp",
  "last_login_at": "timestamp?"
}
```

#### Parking Locations (`parking_locations`)
```dart
{
  "id": "string",
  "name": "string",
  "address": "string",
  "latitude": "double",
  "longitude": "double", 
  "total_spots": "int",
  "available_spots": "int",
  "hourly_rate": "double",
  "amenities": {
    "has_ev_charging": "boolean",
    "has_cctv": "boolean",
    "has_security": "boolean",
    "has_roof_cover": "boolean",
    "has_restrooms": "boolean",
    "has_car_wash": "boolean",
    "has_valet_service": "boolean",
    "has_handicap_access": "boolean"
  },
  "operating_hours": {
    "monday": {"open": "string", "close": "string"},
    "tuesday": {"open": "string", "close": "string"}
    // ... other days
  },
  "images": ["string"],
  "is_active": "boolean",
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

#### Bookings (`bookings`)
```dart
{
  "id": "string",
  "user_id": "string",
  "parking_location_id": "string",
  "parking_spot_id": "string",
  "vehicle_id": "string",
  "start_time": "timestamp",
  "end_time": "timestamp",
  "check_in_time": "timestamp?",
  "check_out_time": "timestamp?", 
  "status": "pending|confirmed|active|completed|cancelled",
  "total_amount": "double",
  "payment_id": "string?",
  "qr_code": "string",
  "is_active": "boolean",
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

#### Payments (`payments`)
```dart
{
  "id": "string",
  "user_id": "string",
  "booking_id": "string",
  "amount": "double",
  "currency": "string",
  "payment_method": "telebirr|cbe_birr|awash_birr|ebirr|mpesa|visa|mastercard",
  "payment_status": "pending|processing|success|failed|cancelled|refunded",
  "transaction_id": "string",
  "chapa_reference": "string",
  "gateway_response": "map?",
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

## 🔐 Security Rules

Our Firestore security rules implement:

- **Role-based access control** (User, Admin, Attendant, SuperAdmin)
- **Data ownership validation** (users can only access their own data)
- **Field-level security** (specific fields can only be updated by specific roles)
- **Data validation** (ensure required fields and data types)

Key security features:
- Users can only read/write their own bookings, vehicles, and payments
- Admins can manage parking locations and spots
- Attendants can update spot availability and booking status
- All operations require authentication
- Email verification enforced for sensitive operations

## 🚀 Deployment

### Firebase Deployment
```bash
# Deploy all Firebase services
firebase deploy

# Deploy specific services
firebase deploy --only firestore:rules
firebase deploy --only functions
firebase deploy --only hosting
```

### Flutter App Deployment

#### Android
```bash
cd packages/apps/user_app
flutter build apk --release
# Upload to Google Play Store
```

#### iOS
```bash
cd packages/apps/user_app
flutter build ios --release
# Upload to App Store Connect
```

#### Web (Admin Panel)
```bash
cd packages/apps/admin_panel
flutter build web --release
firebase deploy --only hosting
```

## 📊 Monitoring & Analytics

### Firebase Analytics Events
- User sign up/sign in
- Parking search and booking
- Payment success/failure
- Location sharing
- App crashes and performance

### Performance Monitoring
- App startup time
- Network request latency
- Screen rendering performance
- Memory usage

### Crashlytics
- Automatic crash reporting
- Custom error logging
- User impact analysis

## 🔄 Real-time Features

### Live Updates
- **Parking availability**: Real-time spot status updates
- **Booking status**: Live booking state changes
- **Location updates**: Dynamic parking information
- **Notifications**: Instant push notifications

### WebSocket Connections
- Persistent connections for real-time data
- Automatic reconnection on network issues
- Optimized for mobile battery life

## 🧪 Testing

### Unit Tests
```bash
# Run all unit tests
melos test:all

# Run specific package tests
cd packages/shared
flutter test
```

### Integration Tests
```bash
# Run integration tests
cd packages/apps/user_app
flutter test integration_test/
```

### Firebase Emulator Testing
```bash
# Start Firebase emulators
firebase emulators:start

# Run tests against emulators
flutter test --dart-define=USE_FIREBASE_EMULATOR=true
```

## 📈 Scaling Considerations

### Database Optimization
- **Composite indexes** for complex queries
- **Data denormalization** for read performance
- **Pagination** for large result sets
- **Caching** with Redis for frequently accessed data

### Performance Optimization
- **Image optimization** with Supabase transforms
- **CDN** for static assets
- **Lazy loading** for large lists
- **Background sync** for offline support

### Security Hardening
- **Rate limiting** on API endpoints
- **Input validation** and sanitization
- **HTTPS everywhere** with SSL certificates
- **Regular security audits**

## 🆘 Troubleshooting

### Common Issues

#### Firebase Connection Issues
```bash
# Check Firebase project configuration
firebase projects:list

# Verify authentication
firebase auth:login
```

#### Firestore Permission Denied
- Check security rules
- Verify user authentication
- Ensure proper role assignment

#### Payment Integration Issues
- Verify Chapa API keys
- Check webhook configuration
- Review payment method availability

### Debug Mode
Enable debug logging in development:
```dart
// In main.dart
void main() {
  Logger.root.level = Level.ALL;
  runApp(MyApp());
}
```

## 📞 Support

For technical support:
- **Email**: tech@wepark.et
- **Documentation**: [docs.wepark.et](https://docs.wepark.et)
- **Issue Tracker**: [github.com/wepark/issues](https://github.com/wepark/issues)

---

## 🔄 Next Steps

1. **Set up Firebase project** following the guide above
2. **Configure Supabase storage** with proper policies
3. **Integrate Chapa payments** for Ethiopian market
4. **Deploy security rules** and test thoroughly
5. **Set up monitoring** and analytics
6. **Run comprehensive tests** before production deployment

This backend implementation provides a solid foundation for the WePark smart parking system with room for future enhancements and scaling.