import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import '../../providers/admin_providers.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allBookingsAsync = ref.watch(allBookingsProvider);
    final allUsersAsync = ref.watch(allUsersProvider);
    final allLocationsAsync = ref.watch(allParkingLocationsProvider);
    final totalRevenueAsync = ref.watch(totalRevenueProvider);
    final todayBookingsAsync = ref.watch(todayBookingsProvider);
    final activeBookingsAsync = ref.watch(activeBookingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Reports'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => refreshAllData(ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => refreshAllData(ref),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Revenue Overview
              const Text(
                'Revenue Overview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              totalRevenueAsync.when(
                data: (revenue) => _buildRevenueCard(revenue),
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (error, _) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Error loading revenue: $error'),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // System Stats
              const Text(
                'System Statistics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  allUsersAsync.when(
                    data: (users) => _buildStatCard(
                      'Total Users',
                      users.length.toString(),
                      Icons.people,
                      Colors.blue,
                      'Registered users',
                    ),
                    loading: () => _buildStatCard(
                        'Total Users', '...', Icons.people, Colors.blue, ''),
                    error: (_, __) => _buildStatCard(
                        'Total Users', 'Error', Icons.people, Colors.red, ''),
                  ),
                  allLocationsAsync.when(
                    data: (locations) => _buildStatCard(
                      'Parking Locations',
                      locations.length.toString(),
                      Icons.location_on,
                      Colors.green,
                      'Active locations',
                    ),
                    loading: () => _buildStatCard('Parking Locations', '...',
                        Icons.location_on, Colors.green, ''),
                    error: (_, __) => _buildStatCard('Parking Locations',
                        'Error', Icons.location_on, Colors.red, ''),
                  ),
                  allBookingsAsync.when(
                    data: (bookings) => _buildStatCard(
                      'Total Bookings',
                      bookings.length.toString(),
                      Icons.book,
                      Colors.orange,
                      'All time bookings',
                    ),
                    loading: () => _buildStatCard(
                        'Total Bookings', '...', Icons.book, Colors.orange, ''),
                    error: (_, __) => _buildStatCard(
                        'Total Bookings', 'Error', Icons.book, Colors.red, ''),
                  ),
                  activeBookingsAsync.when(
                    data: (activeBookings) => _buildStatCard(
                      'Active Now',
                      activeBookings.length.toString(),
                      Icons.local_parking,
                      Colors.purple,
                      'Currently parking',
                    ),
                    loading: () => _buildStatCard('Active Now', '...',
                        Icons.local_parking, Colors.purple, ''),
                    error: (_, __) => _buildStatCard('Active Now', 'Error',
                        Icons.local_parking, Colors.red, ''),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Today's Performance
              const Text(
                'Today\'s Performance',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              todayBookingsAsync.when(
                data: (todayBookings) => _buildTodayPerformance(todayBookings),
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (error, _) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Error loading today\'s data: $error'),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // User Role Distribution
              allUsersAsync.when(
                data: (users) => _buildUserRoleDistribution(users),
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (error, _) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Error loading user data: $error'),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Location Performance
              allBookingsAsync.when(
                data: (bookings) => allLocationsAsync.when(
                  data: (locations) =>
                      _buildLocationPerformance(bookings, locations),
                  loading: () => const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                  error: (error, _) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Error loading location data: $error'),
                    ),
                  ),
                ),
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (error, _) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Error loading booking data: $error'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueCard(double revenue) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.attach_money, size: 32, color: Colors.green),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Revenue',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${revenue.toStringAsFixed(0)} ETB',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, color: Colors.green, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Revenue from completed bookings only',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color, String subtitle) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayPerformance(List<Booking> todayBookings) {
    final completed =
        todayBookings.where((b) => b.status == 'completed').length;
    final active = todayBookings.where((b) => b.status == 'active').length;
    final pending = todayBookings.where((b) => b.status == 'pending').length;
    final cancelled =
        todayBookings.where((b) => b.status == 'cancelled').length;

    final todayRevenue = todayBookings
        .where((b) => b.status == 'completed')
        .fold(0.0, (total, booking) => total + booking.totalAmount);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.today, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Today\'s Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${todayRevenue.toStringAsFixed(0)} ETB',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMiniStatCard(
                      'Total', todayBookings.length.toString(), Colors.blue),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMiniStatCard(
                      'Active', active.toString(), Colors.green),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMiniStatCard(
                      'Pending', pending.toString(), Colors.orange),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMiniStatCard(
                      'Completed', completed.toString(), Colors.purple),
                ),
              ],
            ),
            if (cancelled > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '$cancelled cancelled bookings today',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRoleDistribution(List<User> users) {
    final userCount = users.where((u) => u.role == 'user').length;
    final attendantCount = users.where((u) => u.role == 'attendant').length;
    final adminCount = users.where((u) => u.role == 'admin').length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Role Distribution',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildRoleCard('Users', userCount.toString(),
                      Colors.green, Icons.person),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRoleCard('Attendants', attendantCount.toString(),
                      Colors.blue, Icons.local_parking),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRoleCard('Admins', adminCount.toString(),
                      Colors.red, Icons.admin_panel_settings),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard(String role, String count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            role,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPerformance(
      List<Booking> bookings, List<ParkingLocation> locations) {
    // Calculate bookings per location
    Map<String, int> locationBookingCount = {};
    Map<String, double> locationRevenue = {};

    for (final booking in bookings) {
      final locationId = booking.parkingLocationId;
      locationBookingCount[locationId] =
          (locationBookingCount[locationId] ?? 0) + 1;

      if (booking.status == 'completed') {
        locationRevenue[locationId] =
            (locationRevenue[locationId] ?? 0) + booking.totalAmount;
      }
    }

    // Sort locations by booking count
    final sortedLocations =
        locations.where((l) => locationBookingCount.containsKey(l.id)).toList();
    sortedLocations.sort((a, b) => (locationBookingCount[b.id] ?? 0)
        .compareTo(locationBookingCount[a.id] ?? 0));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Location Performance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (sortedLocations.isEmpty)
              const Center(
                child: Text('No booking data available'),
              )
            else
              ...sortedLocations.take(5).map((location) {
                final bookingCount = locationBookingCount[location.id] ?? 0;
                final revenue = locationRevenue[location.id] ?? 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              location.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              location.address,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '$bookingCount\nbookings',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${revenue.toStringAsFixed(0)}\nETB',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}


