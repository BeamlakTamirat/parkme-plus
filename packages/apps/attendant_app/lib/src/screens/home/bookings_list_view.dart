import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import '../../providers/attendant_providers.dart';

enum BookingFilter { all, pending, active, completed, cancelled }

enum BookingSortBy { newest, oldest, amount, vehicle }

class BookingsListView extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final AsyncValue<List<Booking>> bookingsAsync;

  const BookingsListView({
    super.key,
    required this.scrollController,
    required this.bookingsAsync,
  });

  @override
  ConsumerState<BookingsListView> createState() => _BookingsListViewState();
}

class _BookingsListViewState extends ConsumerState<BookingsListView> {
  BookingFilter selectedFilter = BookingFilter.all;
  BookingSortBy sortBy = BookingSortBy.newest;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Bookings',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Filters and Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by plate number, spot, etc.',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                ),

                const SizedBox(height: 12),

                // Filter chips and sort
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: BookingFilter.values.map((filter) {
                            final isSelected = selectedFilter == filter;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(_getFilterLabel(filter)),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    selectedFilter = filter;
                                  });
                                },
                                selectedColor: Colors.blue[100],
                                checkmarkColor: Colors.blue[700],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    PopupMenuButton<BookingSortBy>(
                      icon: const Icon(Icons.sort),
                      onSelected: (value) {
                        setState(() {
                          sortBy = value;
                        });
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: BookingSortBy.newest,
                          child: Row(
                            children: [
                              Icon(Icons.access_time),
                              SizedBox(width: 8),
                              Text('Newest First'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: BookingSortBy.oldest,
                          child: Row(
                            children: [
                              Icon(Icons.history),
                              SizedBox(width: 8),
                              Text('Oldest First'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: BookingSortBy.amount,
                          child: Row(
                            children: [
                              Icon(Icons.monetization_on),
                              SizedBox(width: 8),
                              Text('By Amount'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: BookingSortBy.vehicle,
                          child: Row(
                            children: [
                              Icon(Icons.directions_car),
                              SizedBox(width: 8),
                              Text('By Vehicle'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Bookings list
          Expanded(
            child: widget.bookingsAsync.when(
              data: (bookings) {
                final filteredAndSorted = _filterAndSortBookings(bookings);

                if (filteredAndSorted.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredAndSorted.length,
                  itemBuilder: (context, index) {
                    final booking = filteredAndSorted[index];
                    return _buildBookingCard(context, booking);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorState(error.toString()),
            ),
          ),
        ],
      ),
    );
  }

  List<Booking> _filterAndSortBookings(List<Booking> bookings) {
    List<Booking> filtered = bookings;

    // Apply filter
    if (selectedFilter != BookingFilter.all) {
      filtered = filtered.where((booking) {
        switch (selectedFilter) {
          case BookingFilter.pending:
            return booking.status.toLowerCase() == 'pending';
          case BookingFilter.active:
            return booking.status.toLowerCase() == 'active';
          case BookingFilter.completed:
            return booking.status.toLowerCase() == 'completed';
          case BookingFilter.cancelled:
            return booking.status.toLowerCase() == 'cancelled';
          default:
            return true;
        }
      }).toList();
    }

    // Apply search
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((booking) {
        final query = searchQuery.toLowerCase();
        return booking.vehiclePlateNumber.toLowerCase().contains(query) ||
            booking.spotNumber.toLowerCase().contains(query) ||
            booking.id.toLowerCase().contains(query) ||
            (booking.vehicleModel?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Apply sort
    switch (sortBy) {
      case BookingSortBy.newest:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case BookingSortBy.oldest:
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case BookingSortBy.amount:
        filtered.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
        break;
      case BookingSortBy.vehicle:
        filtered.sort(
            (a, b) => a.vehiclePlateNumber.compareTo(b.vehiclePlateNumber));
        break;
    }

    return filtered;
  }

  Widget _buildBookingCard(BuildContext context, Booking booking) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop();
          context.push('/booking/${booking.id}', extra: booking);
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Status badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(booking.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      booking.status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Amount
                  Text(
                    booking.formattedTotalAmount,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Vehicle and spot info
              Row(
                children: [
                  Icon(Icons.directions_car, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    booking.vehiclePlateNumber,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.local_parking, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Spot ${booking.spotNumber}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),

              if (booking.vehicleModel != null) ...[
                const SizedBox(height: 4),
                Text(
                  booking.vehicleModel!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Time information
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Started: ${booking.formattedStartTime}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),

              if (booking.endTime != null) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.event_available,
                        size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Ended: ${booking.formattedEndTime}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 8),

              // Payment status
              Row(
                children: [
                  Icon(
                    booking.paymentStatus == 'paid'
                        ? Icons.check_circle
                        : Icons.schedule,
                    size: 16,
                    color: booking.paymentStatus == 'paid'
                        ? Colors.green
                        : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Payment: ${booking.paymentStatus.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 12,
                      color: booking.paymentStatus == 'paid'
                          ? Colors.green[700]
                          : Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  // Quick action button
                  if (_canQuickAction(booking))
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getQuickActionText(booking),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;

    if (searchQuery.isNotEmpty) {
      message = 'No bookings found matching "$searchQuery"';
      icon = Icons.search_off;
    } else if (selectedFilter != BookingFilter.all) {
      message = 'No ${_getFilterLabel(selectedFilter).toLowerCase()} bookings';
      icon = Icons.filter_list_off;
    } else {
      message = 'No bookings found for this location';
      icon = Icons.event_busy;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (selectedFilter != BookingFilter.all || searchQuery.isNotEmpty)
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    selectedFilter = BookingFilter.all;
                    searchQuery = '';
                    _searchController.clear();
                  });
                },
                child: const Text('Clear Filters'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            const Text(
              'Error Loading Bookings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Refresh data
                ref.invalidate(attendantBookingsProvider);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  String _getFilterLabel(BookingFilter filter) {
    switch (filter) {
      case BookingFilter.all:
        return 'All';
      case BookingFilter.pending:
        return 'Pending';
      case BookingFilter.active:
        return 'Active';
      case BookingFilter.completed:
        return 'Completed';
      case BookingFilter.cancelled:
        return 'Cancelled';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  bool _canQuickAction(Booking booking) {
    final status = booking.status.toLowerCase();
    return status == 'pending' || status == 'active';
  }

  String _getQuickActionText(Booking booking) {
    final status = booking.status.toLowerCase();
    switch (status) {
      case 'pending':
        return 'Check In';
      case 'active':
        return 'Check Out';
      default:
        return '';
    }
  }
}
