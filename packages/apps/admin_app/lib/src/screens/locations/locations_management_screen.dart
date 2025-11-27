import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:image_picker/image_picker.dart'; // 📸 Image picker
import 'dart:io';
import '../../providers/admin_providers.dart';

class LocationsManagementScreen extends ConsumerStatefulWidget {
  const LocationsManagementScreen({super.key});

  @override
  ConsumerState<LocationsManagementScreen> createState() =>
      _LocationsManagementScreenState();
}

class _LocationsManagementScreenState
    extends ConsumerState<LocationsManagementScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final locationsAsync = ref.watch(allParkingLocationsProvider);
    final usersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Management'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(allParkingLocationsProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search locations...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // Locations List
          Expanded(
            child: locationsAsync.when(
              data: (locations) => usersAsync.when(
                data: (users) => _buildLocationsList(locations, users),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    Center(child: Text('Error loading users: $error')),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error loading locations: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          ref.invalidate(allParkingLocationsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateLocationDialog(),
        backgroundColor: Colors.red,
        child: const Icon(Icons.add_location),
      ),
    );
  }

  Widget _buildLocationsList(
      List<ParkingLocation> allLocations, List<User> users) {
    // Filter locations by search query
    List<ParkingLocation> filteredLocations = allLocations;

    if (_searchQuery.isNotEmpty) {
      filteredLocations = allLocations
          .where((location) =>
              location.name.toLowerCase().contains(_searchQuery) ||
              location.address.toLowerCase().contains(_searchQuery))
          .toList();
    }

    if (filteredLocations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'No parking locations found'
                  : 'No locations match your search',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredLocations.length,
      itemBuilder: (context, index) {
        final location = filteredLocations[index];
        final attendant =
            users.where((u) => u.id == location.attendantId).firstOrNull;
        return _buildLocationCard(location, attendant);
      },
    );
  }

  Widget _buildLocationCard(ParkingLocation location, User? attendant) {
    final occupancyRate = location.totalSpots > 0
        ? ((location.totalSpots - location.availableSpots) /
            location.totalSpots *
            100)
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            location.isActive
                                ? Icons.location_on
                                : Icons.location_off,
                            color:
                                location.isActive ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              location.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        location.address,
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                      onTap: () => _showEditLocationDialog(location),
                    ),
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(location.isActive
                              ? Icons.block
                              : Icons.check_circle),
                          const SizedBox(width: 8),
                          Text(location.isActive ? 'Deactivate' : 'Activate'),
                        ],
                      ),
                      onTap: () => _toggleLocationStatus(location),
                    ),
                    PopupMenuItem(
                      child: const Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                      onTap: () => _showDeleteLocationDialog(location),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stats
            Row(
              children: [
                Expanded(
                  child: _buildStatChip(
                    'Total Spots',
                    location.totalSpots.toString(),
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatChip(
                    'Available',
                    location.availableSpots.toString(),
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatChip(
                    'Occupancy',
                    '${occupancyRate.toStringAsFixed(0)}%',
                    occupancyRate > 80 ? Colors.red : Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatChip(
                    'Rate',
                    location.formattedHourlyRate,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Attendant Info
            if (attendant != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Assigned Attendant',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            attendant.fullName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            attendant.email,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'No attendant assigned',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Additional Info
            if (location.description != null &&
                location.description!.isNotEmpty) ...[
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(location.description!),
              const SizedBox(height: 8),
            ],

            // Amenities
            if (location.amenities != null &&
                location.amenities!.isNotEmpty) ...[
              Text(
                'Amenities',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: location.amenities!
                    .map(
                      (amenity) => Chip(
                        label: Text(
                          amenity,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: Colors.grey[200],
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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

  void _showCreateLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreateLocationDialog(),
    ).then((_) {
      ref.invalidate(allParkingLocationsProvider);
    });
  }

  void _showEditLocationDialog(ParkingLocation location) {
    showDialog(
      context: context,
      builder: (context) => EditLocationDialog(location: location),
    ).then((_) {
      ref.invalidate(allParkingLocationsProvider);
    });
  }

  void _toggleLocationStatus(ParkingLocation location) async {
    try {
      final updatedLocation = location.copyWith(isActive: !location.isActive);
      final result =
          await ref.read(updateParkingLocationProvider(updatedLocation).future);

      if (result) {
        ref.invalidate(allParkingLocationsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Location ${location.isActive ? 'deactivated' : 'activated'} successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update location status'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteLocationDialog(ParkingLocation location) {
    showDialog(
      context: context,
      builder: (context) => DeleteLocationDialog(location: location),
    );
  }
}

// Delete Location Dialog
class DeleteLocationDialog extends ConsumerStatefulWidget {
  final ParkingLocation location;

  const DeleteLocationDialog({super.key, required this.location});

  @override
  ConsumerState<DeleteLocationDialog> createState() => _DeleteLocationDialogState();
}

class _DeleteLocationDialogState extends ConsumerState<DeleteLocationDialog> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning, color: Colors.red[700]),
          const SizedBox(width: 8),
          const Text('Delete Location'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to delete this parking location?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.location.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.place, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.location.address,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.local_parking, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.location.totalSpots} parking spots',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.attach_money, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.location.hourlyRate} ETB/hour',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                if (widget.location.attendantId != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person, color: Colors.blue[600], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Has assigned attendant',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This action cannot be undone. The location will be permanently removed.',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.red[700], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'All active bookings must be completed first',
                        style: TextStyle(
                          color: Colors.red[600],
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.red[700], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No upcoming bookings in next 24 hours',
                        style: TextStyle(
                          color: Colors.red[600],
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isDeleting ? null : _deleteLocation,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: _isDeleting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Delete Location'),
        ),
      ],
    );
  }

  Future<void> _deleteLocation() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      if (kDebugMode) {
        print('🗑️ Initiating location deletion for: ${widget.location.name}');
      }

      // Call the deletion provider
      final success = await ref.read(deleteParkingLocationProvider(widget.location.id).future);

      if (success && mounted) {
        Navigator.of(context).pop();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Location "${widget.location.name}" deleted successfully'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        if (kDebugMode) {
          print('✅ Location deletion completed and UI updated');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Location deletion failed: $e');
      }

      if (mounted) {
        setState(() {
          _isDeleting = false;
        });

        // Show error message with detailed information
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.error, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Failed to delete location',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  e.toString(),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 7),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    }
  }
}

// Create Location Dialog
class CreateLocationDialog extends ConsumerStatefulWidget {
  const CreateLocationDialog({super.key});

  @override
  ConsumerState<CreateLocationDialog> createState() =>
      _CreateLocationDialogState();
}

class _CreateLocationDialogState extends ConsumerState<CreateLocationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _totalSpotsController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amenitiesController = TextEditingController();
  String? _selectedAttendantId;
  bool _isLoading = false;

  final List<XFile> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploadingImages = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _totalSpotsController.dispose();
    _hourlyRateController.dispose();
    _descriptionController.dispose();
    _amenitiesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final attendantsAsync = ref.watch(usersByRoleProvider('attendant'));

    return AlertDialog(
      title: const Text('Create New Location'),
      content: SizedBox(
        width: 500,
        height: 600,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Location Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter location name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latitudeController,
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter latitude';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _longitudeController,
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter longitude';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _totalSpotsController,
                        decoration: const InputDecoration(
                          labelText: 'Total Spots',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter total spots';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _hourlyRateController,
                        decoration: const InputDecoration(
                          labelText: 'Hourly Rate (ETB)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter hourly rate';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                attendantsAsync.when(
                  data: (attendants) => DropdownButtonFormField<String>(
                    value: _selectedAttendantId,
                    decoration: const InputDecoration(
                      labelText: 'Assign Attendant (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('No attendant'),
                      ),
                      ...attendants.map(
                        (attendant) => DropdownMenuItem<String>(
                          value: attendant.id,
                          child: Text(attendant.fullName),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedAttendantId = value;
                      });
                    },
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Text('Error loading attendants'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // 📸 IMAGE UPLOAD SECTION
                _buildImageUploadSection(),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _amenitiesController,
                  decoration: const InputDecoration(
                    labelText: 'Amenities (comma separated)',
                    border: OutlineInputBorder(),
                    hintText: 'Security, CCTV, Well-lit',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createLocation,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  // 📸 BUILD IMAGE UPLOAD SECTION
  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.image, color: Colors.blue),
            const SizedBox(width: 8),
            const Text(
              'Parking Images',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _isUploadingImages ? null : _pickImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Add Photos'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_selectedImages.isNotEmpty) ...[
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                final image = _selectedImages[index];
                return Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(image.path),
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 120,
                              height: 120,
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.error,
                                color: Colors.red,
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '· ${_selectedImages.length} image(s) selected',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            '· Images will help users identify the parking area',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ] else
          Container(
            height: 80,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: InkWell(
              onTap: _isUploadingImages ? null : _pickImages,
              borderRadius: BorderRadius.circular(8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 32,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to add parking images',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // 📸 PICK IMAGES FROM GALLERY
  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (pickedFiles.isNotEmpty) {
        setState(() {
          // Limit to maximum 5 images
          final remainingSlots = 5 - _selectedImages.length;
          final imagesToAdd = pickedFiles.take(remainingSlots).toList();
          _selectedImages.addAll(imagesToAdd);
        });

        if (pickedFiles.length >
            5 - (_selectedImages.length - pickedFiles.length)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Maximum 5 images allowed'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 📸 REMOVE SELECTED IMAGE
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _createLocation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final totalSpots = int.parse(_totalSpotsController.text);
      final amenities = _amenitiesController.text.trim().isEmpty
          ? <String>[]
          : _amenitiesController.text.split(',').map((e) => e.trim()).toList();

      // 📸 UPLOAD IMAGES FIRST
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        setState(() {
          _isUploadingImages = true;
        });

        final locationName = _nameController.text.trim().replaceAll(' ', '_');
        final storageService = StorageService.instance;

        for (int i = 0; i < _selectedImages.length; i++) {
          final image = _selectedImages[i];
          final fileName =
              '${locationName}_image_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.jpg';

          final fileId = await storageService.uploadParkingImage(
            locationId: locationName,
            file: File(image.path),
            fileName: fileName,
          );

          if (fileId != null) {
            final imageUrl = storageService.getImageUrl(fileId);
            imageUrls.add(imageUrl);
          }
        }

        setState(() {
          _isUploadingImages = false;
        });
      }

      final locationData = {
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'latitude': double.parse(_latitudeController.text),
        'longitude': double.parse(_longitudeController.text),
        'totalSpots': totalSpots,
        'availableSpots': totalSpots, // Initially all spots are available
        'hourlyRate': double.parse(_hourlyRateController.text),
        'isActive': true,
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'amenities': amenities,
        'images': imageUrls, // 📸 ADD UPLOADED IMAGE URLS
        'attendantId': _selectedAttendantId,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final result =
          await ref.read(createParkingLocationProvider(locationData).future);

      if (result != null) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location created successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create location'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

// Edit Location Dialog - Similar to Create but with pre-filled data
class EditLocationDialog extends ConsumerStatefulWidget {
  final ParkingLocation location;

  const EditLocationDialog({super.key, required this.location});

  @override
  ConsumerState<EditLocationDialog> createState() => _EditLocationDialogState();
}

class _EditLocationDialogState extends ConsumerState<EditLocationDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _totalSpotsController;
  late TextEditingController _availableSpotsController;
  late TextEditingController _hourlyRateController;
  late TextEditingController _descriptionController;
  late TextEditingController _amenitiesController;
  late String? _selectedAttendantId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.location.name);
    _addressController = TextEditingController(text: widget.location.address);
    _totalSpotsController =
        TextEditingController(text: widget.location.totalSpots.toString());
    _availableSpotsController =
        TextEditingController(text: widget.location.availableSpots.toString());
    _hourlyRateController =
        TextEditingController(text: widget.location.hourlyRate.toString());
    _descriptionController =
        TextEditingController(text: widget.location.description ?? '');
    _amenitiesController = TextEditingController(
      text: widget.location.amenities?.join(', ') ?? '',
    );
    _selectedAttendantId = widget.location.attendantId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _totalSpotsController.dispose();
    _availableSpotsController.dispose();
    _hourlyRateController.dispose();
    _descriptionController.dispose();
    _amenitiesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final attendantsAsync = ref.watch(usersByRoleProvider('attendant'));

    return AlertDialog(
      title: Text('Edit ${widget.location.name}'),
      content: SizedBox(
        width: 500,
        height: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Location Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter location name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _totalSpotsController,
                        decoration: const InputDecoration(
                          labelText: 'Total Spots',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter total spots';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _availableSpotsController,
                        decoration: const InputDecoration(
                          labelText: 'Available Spots',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter available spots';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _hourlyRateController,
                  decoration: const InputDecoration(
                    labelText: 'Hourly Rate (ETB)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter hourly rate';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                attendantsAsync.when(
                  data: (attendants) => DropdownButtonFormField<String>(
                    value: _selectedAttendantId,
                    decoration: const InputDecoration(
                      labelText: 'Assign Attendant',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('No attendant'),
                      ),
                      ...attendants.map(
                        (attendant) => DropdownMenuItem<String>(
                          value: attendant.id,
                          child: Text(attendant.fullName),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedAttendantId = value;
                      });
                    },
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Text('Error loading attendants'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amenitiesController,
                  decoration: const InputDecoration(
                    labelText: 'Amenities (comma separated)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateLocation,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }

  Future<void> _updateLocation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final amenities = _amenitiesController.text.trim().isEmpty
          ? <String>[]
          : _amenitiesController.text.split(',').map((e) => e.trim()).toList();

      final updatedLocation = widget.location.copyWith(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        totalSpots: int.parse(_totalSpotsController.text),
        availableSpots: int.parse(_availableSpotsController.text),
        hourlyRate: double.parse(_hourlyRateController.text),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        amenities: amenities,
        attendantId: _selectedAttendantId,
        updatedAt: DateTime.now(),
      );

      final result =
          await ref.read(updateParkingLocationProvider(updatedLocation).future);

      if (result) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update location'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
