import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'WePark',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.orange,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Implement profile navigation
            },
            icon: const Icon(Icons.person, color: Colors.white),
          ),
        ],
      ),
      body: _buildHomeContent(context),
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Welcome section
            Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
              borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome to WePark!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                    Text(
                  'Find and book parking spots easily',
                      style: TextStyle(
                    fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
          ),
          const SizedBox(height: 20),

          // Quick actions
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
          const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _buildActionCard(
                  title: 'Find Parking',
                  icon: Icons.search,
                  color: Colors.blue,
                  onTap: () {
                    // TODO: Navigate to parking search
                  },
                ),
              ),
              const SizedBox(width: 12),
            Expanded(
                child: _buildActionCard(
                  title: 'My Bookings',
                  icon: Icons.bookmark,
                  color: Colors.green,
                  onTap: () {
                    // TODO: Navigate to bookings
                  },
              ),
            ),
          ],
        ),
          const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _buildActionCard(
                  title: 'QR Scanner',
                  icon: Icons.qr_code_scanner,
                  color: Colors.purple,
                  onTap: () {
                    // TODO: Open QR scanner
                  },
                ),
              ),
              const SizedBox(width: 12),
            Expanded(
                child: _buildActionCard(
                  title: 'Profile',
                  icon: Icons.person,
                  color: Colors.orange,
                  onTap: () {
                    // TODO: Navigate to profile
                  },
              ),
            ),
          ],
        ),
          const SizedBox(height: 30),

          // Recent activity placeholder
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
                Icon(
                  Icons.history,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No recent activity',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
            Text(
                  'Your parking history will appear here',
                  style: TextStyle(
                fontSize: 14,
                    color: Colors.grey[500],
              ),
            ),
          ],
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
                  Text(
              title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}