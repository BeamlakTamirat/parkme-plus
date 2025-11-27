import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import '../../providers/attendant_providers.dart';

enum SpotState {
  available,
  occupied,
  maintenance,
  blocked,
  reserved,
}

class SpotManagementScreen extends ConsumerStatefulWidget {
  const SpotManagementScreen({super.key});

  @override
  ConsumerState<SpotManagementScreen> createState() =>
      _SpotManagementScreenState();
}

class _SpotManagementScreenState extends ConsumerState<SpotManagementScreen> {
  // Track manual spot states (maintenance, blocked, etc.)
  Map<String, SpotState> manualSpotStates = {};

  // Track maintenance reports
  Map<String, String> maintenanceReports = {};

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(attendantLocationProvider);
    final bookingsAsync = ref.watch(attendantBookingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spot Management'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshData(),
            tooltip: 'Refresh',
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.build, size: 18),
                    SizedBox(width: 8),
                    Text('Maintenance Mode'),
                  ],
                ),
                onTap: () => _showMaintenanceModeDialog(),
              ),
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.analytics, size: 18),
                    SizedBox(width: 8),
                    Text('View Statistics'),
                  ],
                ),
                onTap: () => _showStatisticsDialog(),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: locationAsync.when(
          data: (location) {
            if (location == null) {
              return _buildNoLocationView();
            }

            return bookingsAsync.when(
              data: (bookings) =>
                  _buildSpotManagement(context, location, bookings),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  _buildErrorView('Error loading bookings: $error', () {
                // ignore: unused_result
                ref.refresh(attendantBookingsProvider);
              }),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              _buildErrorView('Error loading location: $error', () {
            // ignore: unused_result
            ref.refresh(attendantLocationProvider);
          }),
        ),
      ),
      floatingActionButton: locationAsync.maybeWhen(
        data: (location) => location != null
            ? FloatingActionButton(
                onPressed: () => _showBulkActionsDialog(location),
                backgroundColor: Colors.blue[700],
                tooltip: 'Bulk Actions',
                child: const Icon(Icons.dashboard_customize),
              )
            : null,
        orElse: () => null,
      ),
    );
  }

  Future<void> _refreshData() async {
    ref.invalidate(attendantLocationProvider);
    ref.invalidate(attendantBookingsProvider);
    ref.invalidate(activeBookingsProvider);
  }

  Widget _buildNoLocationView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 80, color: Colors.orange[300]),
            const SizedBox(height: 20),
            const Text(
              'No Location Assigned',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'You haven\'t been assigned to a parking location yet. Contact your administrator to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
            const SizedBox(height: 20),
            const Text(
              'Something went wrong',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpotManagement(
    BuildContext context,
    ParkingLocation location,
    List<Booking> bookings,
  ) {
    // Get active and pending bookings (occupied/reserved spots)
    final activeBookings = bookings
        .where((b) =>
            b.status.toLowerCase() == 'active' ||
            b.status.toLowerCase() == 'pending')
        .toList();

    final occupiedSpots = activeBookings.map((b) => b.spotNumber).toSet();

    // Calculate statistics
    final totalSpots = location.totalSpots;
    final availableSpots = totalSpots -
        occupiedSpots.length -
        _getBlockedSpotsCount() -
        _getMaintenanceSpotsCount();
    final maintenanceSpots = _getMaintenanceSpotsCount();
    final blockedSpots = _getBlockedSpotsCount();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location Header
          _buildLocationHeader(location),
          const SizedBox(height: 24),

          // Quick Stats
          _buildQuickStats(totalSpots, occupiedSpots.length, availableSpots,
              maintenanceSpots, blockedSpots),
          const SizedBox(height: 24),

          // Legend
          _buildLegend(),
          const SizedBox(height: 16),

          // Spot Grid
          _buildSpotGrid(totalSpots, occupiedSpots, activeBookings),
          const SizedBox(height: 24),

          // Action Buttons
          _buildActionButtons(location),
        ],
      ),
    );
  }

  Widget _buildLocationHeader(ParkingLocation location) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.blue[700], size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    location.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: location.isActive ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    location.isActive ? 'ACTIVE' : 'INACTIVE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              location.address,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  location.formattedHourlyRate,
                  style: TextStyle(
                    color: Colors.green[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${location.availableSpots}/${location.totalSpots} available',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(
      int total, int occupied, int available, int maintenance, int blocked) {
    return Row(
      children: [
        Expanded(
            child: _buildStatCard(
                'Total', '$total', Colors.blue, Icons.grid_view)),
        const SizedBox(width: 8),
        Expanded(
            child: _buildStatCard(
                'Occupied', '$occupied', Colors.red, Icons.directions_car)),
        const SizedBox(width: 8),
        Expanded(
            child: _buildStatCard(
                'Available', '$available', Colors.green, Icons.local_parking)),
        const SizedBox(width: 8),
        Expanded(
            child: _buildStatCard('Issues', '${maintenance + blocked}',
                Colors.orange, Icons.warning)),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Legend',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildLegendItem(
                    Colors.green, 'Available', Icons.local_parking),
                _buildLegendItem(Colors.red, 'Occupied', Icons.directions_car),
                _buildLegendItem(Colors.blue, 'Reserved', Icons.bookmark),
                _buildLegendItem(Colors.orange, 'Maintenance', Icons.build),
                _buildLegendItem(Colors.grey, 'Blocked', Icons.block),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, color: Colors.white, size: 10),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSpotGrid(
      int totalSpots, Set<String> occupiedSpots, List<Booking> activeBookings) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Parking Spots',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: totalSpots,
              itemBuilder: (context, index) {
                final spotNumber = _generateSpotNumber(index + 1);
                final spotState =
                    _getSpotState(spotNumber, occupiedSpots, activeBookings);
                final booking = activeBookings
                    .where((b) => b.spotNumber == spotNumber)
                    .firstOrNull;

                return _buildSpotTile(spotNumber, spotState, booking);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpotTile(String spotNumber, SpotState state, Booking? booking) {
    Color color;
    IconData icon;

    switch (state) {
      case SpotState.available:
        color = Colors.green;
        icon = Icons.local_parking;
        break;
      case SpotState.occupied:
        color = Colors.red;
        icon = Icons.directions_car;
        break;
      case SpotState.reserved:
        color = Colors.blue;
        icon = Icons.bookmark;
        break;
      case SpotState.maintenance:
        color = Colors.orange;
        icon = Icons.build;
        break;
      case SpotState.blocked:
        color = Colors.grey;
        icon = Icons.block;
        break;
    }

    return GestureDetector(
      onTap: () => _showSpotDetailsDialog(spotNumber, state, booking),
      onLongPress: () => _showSpotActionsDialog(spotNumber, state),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: 0.7),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(height: 2),
            Text(
              spotNumber,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ParkingLocation location) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showMaintenanceReportDialog(),
                icon: const Icon(Icons.report_problem),
                label: const Text('Report Issue'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showBulkActionsDialog(location),
                icon: const Icon(Icons.dashboard_customize),
                label: const Text('Bulk Actions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Helper Methods
  String _generateSpotNumber(int index) {
    // Generate spot numbers like A1-A20, B1-B20, etc.
    final letter = String.fromCharCode(65 + ((index - 1) ~/ 20)); // A, B, C...
    final number = ((index - 1) % 20) + 1;
    return '$letter$number';
  }

  SpotState _getSpotState(String spotNumber, Set<String> occupiedSpots,
      List<Booking> activeBookings) {
    if (manualSpotStates.containsKey(spotNumber)) {
      return manualSpotStates[spotNumber]!;
    }

    if (occupiedSpots.contains(spotNumber)) {
      final booking =
          activeBookings.where((b) => b.spotNumber == spotNumber).firstOrNull;
      return booking?.status == 'pending'
          ? SpotState.reserved
          : SpotState.occupied;
    }

    return SpotState.available;
  }

  int _getMaintenanceSpotsCount() {
    return manualSpotStates.values
        .where((state) => state == SpotState.maintenance)
        .length;
  }

  int _getBlockedSpotsCount() {
    return manualSpotStates.values
        .where((state) => state == SpotState.blocked)
        .length;
  }

  // Dialog Methods
  void _showSpotDetailsDialog(
      String spotNumber, SpotState state, Booking? booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_getSpotIcon(state), color: _getSpotColor(state)),
            const SizedBox(width: 8),
            Text('Spot $spotNumber'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Status', _getSpotStatusText(state)),
              if (booking != null) ...[
                const Divider(),
                const Text('Booking Details:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildDetailRow('Vehicle', booking.vehiclePlateNumber),
                if (booking.vehicleModel != null)
                  _buildDetailRow('Model', booking.vehicleModel!),
                _buildDetailRow('Start Time', booking.formattedStartTime),
                if (booking.endTime != null)
                  _buildDetailRow('End Time', booking.formattedEndTime),
                _buildDetailRow('Amount', booking.formattedTotalAmount),
                _buildDetailRow('Payment', booking.paymentStatus.toUpperCase()),
              ],
              if (manualSpotStates[spotNumber] == SpotState.maintenance &&
                  maintenanceReports[spotNumber] != null) ...[
                const Divider(),
                const Text('Maintenance Report:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(maintenanceReports[spotNumber]!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (state != SpotState.occupied)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showSpotActionsDialog(spotNumber, state);
              },
              child: const Text('Manage'),
            ),
        ],
      ),
    );
  }

  void _showSpotActionsDialog(String spotNumber, SpotState currentState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Manage Spot $spotNumber'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.local_parking, color: Colors.green),
              title: const Text('Mark as Available'),
              onTap: () {
                _updateSpotState(spotNumber, SpotState.available);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.build, color: Colors.orange),
              title: const Text('Mark for Maintenance'),
              onTap: () {
                Navigator.of(context).pop();
                _showMaintenanceReasonDialog(spotNumber);
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.grey),
              title: const Text('Block Spot'),
              onTap: () {
                _updateSpotState(spotNumber, SpotState.blocked);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showMaintenanceReasonDialog(String spotNumber) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Maintenance - Spot $spotNumber'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please describe the maintenance issue:'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g., Pothole, oil spill, damaged marking...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = controller.text.trim();
              if (reason.isNotEmpty) {
                _updateSpotState(spotNumber, SpotState.maintenance);
                maintenanceReports[spotNumber] = reason;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Spot $spotNumber marked for maintenance'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showMaintenanceReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Maintenance Reports'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: maintenanceReports.isEmpty
              ? const Center(child: Text('No maintenance reports yet'))
              : ListView(
                  children: maintenanceReports.entries
                      .map(
                        (entry) => ListTile(
                          leading:
                              const Icon(Icons.build, color: Colors.orange),
                          title: Text('Spot ${entry.key}'),
                          subtitle: Text(entry.value),
                          trailing: IconButton(
                            icon: const Icon(Icons.check_circle,
                                color: Colors.green),
                            onPressed: () {
                              _updateSpotState(entry.key, SpotState.available);
                              maintenanceReports.remove(entry.key);
                              Navigator.of(context).pop();
                              _showMaintenanceReportDialog(); // Refresh dialog
                            },
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showBulkActionsDialog(ParkingLocation location) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Actions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.blue),
              title: const Text('Reset All Manual States'),
              subtitle: const Text('Clear all maintenance and blocked spots'),
              onTap: () {
                _resetAllManualStates();
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility, color: Colors.green),
              title: const Text('View Statistics'),
              subtitle: const Text('Show detailed parking statistics'),
              onTap: () {
                Navigator.of(context).pop();
                _showStatisticsDialog();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showStatisticsDialog() {
    final locationAsync = ref.read(attendantLocationProvider);
    final bookingsAsync = ref.read(attendantBookingsProvider);

    locationAsync.whenData((location) {
      if (location == null) return;

      bookingsAsync.whenData((bookings) {
        final totalSpots = location.totalSpots;
        final occupied = bookings.where((b) => b.status == 'active').length;
        final pending = bookings.where((b) => b.status == 'pending').length;
        final maintenance = _getMaintenanceSpotsCount();
        final blocked = _getBlockedSpotsCount();
        final available =
            totalSpots - occupied - pending - maintenance - blocked;

        final occupancyRate =
            ((occupied / totalSpots) * 100).toStringAsFixed(1);

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Parking Statistics'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatRow('Total Spots', '$totalSpots'),
                _buildStatRow('Currently Occupied', '$occupied'),
                _buildStatRow('Reserved (Pending)', '$pending'),
                _buildStatRow('Available', '$available'),
                _buildStatRow('Under Maintenance', '$maintenance'),
                _buildStatRow('Blocked', '$blocked'),
                const Divider(),
                _buildStatRow('Occupancy Rate', '$occupancyRate%'),
                _buildStatRow('Revenue Today', 'Coming soon...'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      });
    });
  }

  void _showMaintenanceModeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Maintenance Mode'),
        content: const Text(
            'This would enable maintenance mode for the entire location, '
            'temporarily blocking new bookings while allowing current ones to complete.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Maintenance mode feature coming soon'),
                ),
              );
            },
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // State Management Methods
  void _updateSpotState(String spotNumber, SpotState state) {
    setState(() {
      if (state == SpotState.available) {
        manualSpotStates.remove(spotNumber);
      } else {
        manualSpotStates[spotNumber] = state;
      }
    });
  }

  void _resetAllManualStates() {
    setState(() {
      manualSpotStates.clear();
      maintenanceReports.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All manual spot states have been reset'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Helper Methods for UI
  Color _getSpotColor(SpotState state) {
    switch (state) {
      case SpotState.available:
        return Colors.green;
      case SpotState.occupied:
        return Colors.red;
      case SpotState.reserved:
        return Colors.blue;
      case SpotState.maintenance:
        return Colors.orange;
      case SpotState.blocked:
        return Colors.grey;
    }
  }

  IconData _getSpotIcon(SpotState state) {
    switch (state) {
      case SpotState.available:
        return Icons.local_parking;
      case SpotState.occupied:
        return Icons.directions_car;
      case SpotState.reserved:
        return Icons.bookmark;
      case SpotState.maintenance:
        return Icons.build;
      case SpotState.blocked:
        return Icons.block;
    }
  }

  String _getSpotStatusText(SpotState state) {
    switch (state) {
      case SpotState.available:
        return 'Available';
      case SpotState.occupied:
        return 'Occupied';
      case SpotState.reserved:
        return 'Reserved';
      case SpotState.maintenance:
        return 'Under Maintenance';
      case SpotState.blocked:
        return 'Blocked';
    }
  }
}
