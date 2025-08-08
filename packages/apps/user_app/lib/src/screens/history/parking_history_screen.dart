import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ParkingHistoryScreen extends ConsumerWidget {
  const ParkingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Parking History',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHistoryItem(
            location: 'Meskel Square Parking',
            space: 'Space A12',
            vehicle: 'Toyota Corolla',
            date: 'Today',
            time: '9:00 AM - 5:00 PM',
            duration: '8 hours',
            cost: '247 ETB',
            status: 'active',
            statusColor: Colors.orange,
            primaryAction: 'Manage',
            primaryActionColor: Colors.orange,
            secondaryAction: 'View Details',
            onPrimaryAction: () {
              // Navigate to active booking
            },
            onSecondaryAction: () {
              // Show booking details
            },
          ),
          const SizedBox(height: 16),
          _buildHistoryItem(
            location: 'Bole Arena Plaza',
            space: 'Space B05',
            vehicle: 'Toyota Corolla',
            date: 'Yesterday',
            time: '2:00 PM - 6:00 PM',
            duration: '4 hours',
            cost: '120 ETB',
            status: 'completed',
            statusColor: Colors.grey,
            primaryAction: 'Book Again',
            primaryActionColor: Colors.orange,
            secondaryAction: 'View Details',
            onPrimaryAction: () {
              // Navigate to booking screen with this location
            },
            onSecondaryAction: () {
              // Show booking details
            },
          ),
          const SizedBox(height: 16),
          _buildHistoryItem(
            location: 'Piassa Mall Garage',
            space: 'Space C18',
            vehicle: 'Toyota Corolla',
            date: 'Jan 28, 2025',
            time: '10:00 AM - 3:00 PM',
            duration: '5 hours',
            cost: '180 ETB',
            status: 'completed',
            statusColor: Colors.grey,
            primaryAction: 'Book Again',
            primaryActionColor: Colors.orange,
            secondaryAction: 'View Details',
            onPrimaryAction: () {
              // Navigate to booking screen with this location
            },
            onSecondaryAction: () {
              // Show booking details
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem({
    required String location,
    required String space,
    required String vehicle,
    required String date,
    required String time,
    required String duration,
    required String cost,
    required String status,
    required Color statusColor,
    required String primaryAction,
    required Color primaryActionColor,
    required String secondaryAction,
    required VoidCallback onPrimaryAction,
    required VoidCallback onSecondaryAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with location and status
          Row(
            children: [
              Expanded(
                child: Text(
                  location,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          Text(
            '$space • $vehicle',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),

          const SizedBox(height: 16),

          // Date & Time and Duration & Cost sections
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date & Time',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Duration & Cost',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    duration,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    cost,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onSecondaryAction,
                  child: Text(
                    secondaryAction,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: onPrimaryAction,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: primaryActionColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    primaryAction,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
