import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import '../../providers/admin_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentAdminProvider);
    final allUsersAsync = ref.watch(allUsersProvider);
    final allLocationsAsync = ref.watch(allParkingLocationsProvider);
    // final allBookingsAsync = ref.watch(allBookingsProvider); // Not used in current implementation
    final totalRevenueAsync = ref.watch(totalRevenueProvider);
    final todayBookingsAsync = ref.watch(todayBookingsProvider);
    final activeBookingsAsync = ref.watch(activeBookingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => refreshAllData(ref),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Sign Out'),
                  ],
                ),
                onTap: () => _handleSignOut(context, ref),
              ),
            ],
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
              // Welcome Section
              currentUserAsync.when(
                data: (user) => _buildWelcomeSection(user),
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (error, _) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Error loading user: $error'),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Stats Overview
              const Text(
                'System Overview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Stats Grid
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
                      () => context.push('/users'),
                    ),
                    loading: () => _buildStatCard(
                        'Total Users', '...', Icons.people, Colors.blue, null),
                    error: (_, __) => _buildStatCard(
                        'Total Users', 'Error', Icons.people, Colors.red, null),
                  ),
                  allLocationsAsync.when(
                    data: (locations) => _buildStatCard(
                      'Parking Locations',
                      locations.length.toString(),
                      Icons.location_on,
                      Colors.green,
                      () => context.push('/locations'),
                    ),
                    loading: () => _buildStatCard('Parking Locations', '...',
                        Icons.location_on, Colors.green, null),
                    error: (_, __) => _buildStatCard('Parking Locations',
                        'Error', Icons.location_on, Colors.red, null),
                  ),
                  activeBookingsAsync.when(
                    data: (activeBookings) => _buildStatCard(
                      'Active Bookings',
                      activeBookings.length.toString(),
                      Icons.local_parking,
                      Colors.orange,
                      () => context.push('/bookings'),
                    ),
                    loading: () => _buildStatCard('Active Bookings', '...',
                        Icons.local_parking, Colors.orange, null),
                    error: (_, __) => _buildStatCard('Active Bookings', 'Error',
                        Icons.local_parking, Colors.red, null),
                  ),
                  totalRevenueAsync.when(
                    data: (revenue) => _buildStatCard(
                      'Total Revenue',
                      '${revenue.toStringAsFixed(0)} ETB',
                      Icons.attach_money,
                      Colors.purple,
                      () => context.push('/analytics'),
                    ),
                    loading: () => _buildStatCard('Total Revenue', '...',
                        Icons.attach_money, Colors.purple, null),
                    error: (_, __) => _buildStatCard('Total Revenue', 'Error',
                        Icons.attach_money, Colors.red, null),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick Actions
              const Text(
                'Quick Actions',
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
                children: [
                  _buildActionCard(
                    'Manage Users',
                    'View and manage all users',
                    Icons.people_outline,
                    Colors.blue,
                    () => context.push('/users'),
                  ),
                  _buildActionCard(
                    'Manage Locations',
                    'Add and edit parking locations',
                    Icons.add_location,
                    Colors.green,
                    () => context.push('/locations'),
                  ),
                  _buildActionCard(
                    'View Bookings',
                    'Monitor all bookings',
                    Icons.book_online,
                    Colors.orange,
                    () => context.push('/bookings'),
                  ),
                  _buildActionCard(
                    'Analytics',
                    'View system analytics',
                    Icons.analytics,
                    Colors.purple,
                    () => context.push('/analytics'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Today's Activity
              const Text(
                'Today\'s Activity',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              todayBookingsAsync.when(
                data: (todayBookings) => _buildTodayActivity(todayBookings),
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (error, _) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Error loading today\'s activity: $error'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(User? user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.red,
              child: Text(
                user?.fullName.substring(0, 1).toUpperCase() ?? 'A',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    user?.fullName ?? 'Administrator',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'System Administrator',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
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
    String title,
    String value,
    IconData icon,
    Color color,
    VoidCallback? onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayActivity(List<Booking> todayBookings) {
    if (todayBookings.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.calendar_today, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text('No bookings today'),
              ],
            ),
          ),
        ),
      );
    }

    final completed =
        todayBookings.where((b) => b.status == 'completed').length;
    final active = todayBookings.where((b) => b.status == 'active').length;
    final pending = todayBookings.where((b) => b.status == 'pending').length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActivityStat(
                    'Total', todayBookings.length.toString(), Colors.blue),
                _buildActivityStat('Active', active.toString(), Colors.green),
                _buildActivityStat(
                    'Pending', pending.toString(), Colors.orange),
                _buildActivityStat(
                    'Completed', completed.toString(), Colors.purple),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to detailed bookings view
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black87,
                ),
                child: const Text('View All Today\'s Bookings'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
    try {
      final authService = ref.read(adminAuthServiceProvider);
      await authService.signOut();

      // Clear all cached data
      ref.invalidate(currentAdminProvider);
      ref.invalidate(isAdminAuthenticatedProvider);
      refreshAllData(ref);

      if (context.mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign out failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
