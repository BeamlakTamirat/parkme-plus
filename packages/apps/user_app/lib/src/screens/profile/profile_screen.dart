import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import '../../providers/comprehensive_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: currentUserAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/sign-in'),
                child: const Text('Go to Sign In'),
              ),
            ],
          ),
        ),
        data: (user) {
          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No user data found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/sign-in'),
                    child: const Text('Go to Sign In'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Header Section
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.orange, Colors.deepOrange],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          // Profile Picture
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Center(
                                child: Text(
                                  user.fullName.isNotEmpty
                                      ? user.fullName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // User Name
                          Text(
                            user.fullName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(height: 4),

                          // Email
                          Text(
                            user.email,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Role Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              user.role.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Stats Row
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Menu Items
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      _MenuSection(
                        title: 'Account',
                        items: [
                          _MenuItem(
                            icon: Icons.person_outline,
                            title: 'Edit Profile',
                            subtitle: 'Update your personal information',
                            onTap: () => _editProfile(context, user),
                          ),
                          _MenuItem(
                            icon: Icons.phone_outlined,
                            title: 'Phone Number',
                            subtitle: user.phoneNumber ?? 'Not set',
                            onTap: () => _updatePhone(context, user),
                          ),
                          _MenuItem(
                            icon: Icons.lock_outline,
                            title: 'Change Password',
                            subtitle: 'Update your password',
                            onTap: () => _changePassword(context, user),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      _MenuSection(
                        title: 'Vehicle',
                        items: [
                          _MenuItem(
                            icon: Icons.directions_car_outlined,
                            title: 'Vehicle Information',
                            subtitle: user.vehiclePlateNumber ?? 'Not set',
                            onTap: () => _updateVehicle(context, user),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      _MenuSection(
                        title: 'App',
                        items: [
                          _MenuItem(
                            icon: Icons.notifications_outlined,
                            title: 'Notifications',
                            subtitle: 'Manage notification settings',
                            onTap: () => _notifications(context),
                          ),
                          _MenuItem(
                            icon: Icons.security_outlined,
                            title: 'Privacy & Security',
                            subtitle: 'Manage your privacy settings',
                            onTap: () => _privacySecurity(context),
                          ),
                          _MenuItem(
                            icon: Icons.help_outline,
                            title: 'Help & Support',
                            subtitle: 'Get help and contact support',
                            onTap: () => _helpSupport(context),
                          ),
                          _MenuItem(
                            icon: Icons.info_outline,
                            title: 'About',
                            subtitle: 'App version and information',
                            onTap: () => _about(context),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Sign Out Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _signOut(context, ref),
                          icon: const Icon(Icons.logout),
                          label: const Text('Sign Out'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _editProfile(BuildContext context, User user) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit Profile feature coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _updatePhone(BuildContext context, User user) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Update Phone feature coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _changePassword(BuildContext context, User user) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Change Password feature coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _updateVehicle(BuildContext context, User user) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Update Vehicle feature coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _notifications(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notifications feature coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _privacySecurity(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Privacy & Security feature coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _helpSupport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Help & Support feature coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _about(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('About feature coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final authService = ref.read(comprehensiveAuthProvider);
    final success = await authService.signOut();

    if (success && context.mounted) {
      // Refresh user data to clear the cached user info
      ref.invalidate(currentUserProvider);
      ref.invalidate(isAuthenticatedProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Signed out successfully'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/sign-in');
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _MenuSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
            children: items,
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.orange,
        size: 24,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }
}
